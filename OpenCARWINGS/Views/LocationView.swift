//
//  LocationView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 30.4.2025.
//

import SwiftUI
import MapKit
import Get
import RestAPI

struct LocationView: View {
    @Binding var token: String
    @Binding var refreshToken: String
    @Binding var serverUrl: String
    @Binding var carLocation: Car?
    @StateObject private var viewModel = LocationViewModel()
    @State private var showSendCarDialog = false
    @State private var showProgress = false
    @State private var showError = false
    @State private var errorMsg: String = ""

    private var lat: Double {
        return Double(carLocation?.location.lat ?? "0.0") ?? 0.0
    }
    
    private var lon: Double {
        return Double(carLocation?.location.lon ?? "0.0") ?? 0.0
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.annotations) { place in
                MapPin(coordinate: place.coordinate)
            }
            .ignoresSafeArea()
            .onTapGesture {
                // Dismiss suggestions when tapping outside (on the map)
                viewModel.searchSuggestions = []
                viewModel.isSearchFocused = false
            }
            .onChange(of: carLocation?.location) { newValue in
                viewModel.setInitialRegion(latitude: lat, longitude: lon)
            }
            

                
                // Display search suggestions if available
            if !viewModel.searchSuggestions.isEmpty && viewModel.isSearchFocused {
                    if #available(iOS 26.0, *) {
                        List {
                            ForEach(viewModel.searchSuggestions, id: \.self) { suggestion in
                                VStack(alignment: .leading) {
                                    Text(suggestion.title)
                                        .font(.body)
                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }.background(.clear)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .padding(.horizontal, 8)
                                .glassEffect(.regular)
                                .onTapGesture {
                                    // Handle suggestion selection
                                    viewModel.handleSearchResult(suggestion)
                                }
                            }.listRowBackground(Color.clear).listRowSpacing(0.05)
                        }.listStyle(.plain).listRowSpacing(0.05).background(.clear).scrollContentBackground(.hidden).presentationBackground(.clear)
                        
                    } else {
                        // Fallback on earlier versions
                        List(viewModel.searchSuggestions, id: \.self) { suggestion in
                            VStack(alignment: .leading) {
                                Text(suggestion.title)
                                    .font(.body)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                            .cornerRadius(12)
                            .onTapGesture {
                                // Handle suggestion selection
                                viewModel.handleSearchResult(suggestion)
                                viewModel.searchQuery = "" // Clear search bar
                                viewModel.searchSuggestions = [] // Clear suggestions
                                viewModel.isSearchFocused = false // Dismiss keyboard
                            }
                        }
                        .background(Color.black)
                        .cornerRadius(12)
                        .listStyle(.plain)
                        .frame(maxHeight: 550)
                        .padding(.horizontal)
                    }
                }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if #available(iOS 26.0, *) {
                    TextField("Search for a place", text: $viewModel.searchQuery)
                        .padding(.horizontal)
                        .onChange(of: viewModel.searchQuery) { _, newValue in
                            // Update suggestions as user types
                            viewModel.search(query: newValue)
                            viewModel.isSearchFocused = !newValue.isEmpty
                        }
                } else {
                    TextField("Search for a place", text: $viewModel.searchQuery)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(25)
                        .padding(.horizontal)
                        .onChange(of: viewModel.searchQuery) { _, newValue in
                            // Update suggestions as user types
                            viewModel.search(query: newValue)
                            viewModel.isSearchFocused = !newValue.isEmpty
                        }
                }
            }
        }
        .onAppear {
            // Set initial region based on carLocation
            viewModel.setInitialRegion(latitude: lat, longitude: lon)
        }
        .confirmationDialog(NSLocalizedString("Share location to car?", comment: ""),
          isPresented: $showSendCarDialog) {
            Button("Share") {
                viewModel.searchQuery = "" // Clear search bar
                viewModel.searchSuggestions = [] // Clear suggestions
                viewModel.isSearchFocused = false // Dismiss keyboard
                showProgress = true
                Task {
                    await sendLocation()
                }
           }
            Button("Cancel", role: .cancel) {
                viewModel.placeName = nil
                viewModel.placeLocation = nil
            }
        } message: {
            Text("Share location to car?")
        }
        .onChange(of: viewModel.placeName) {name in
            if name != nil && viewModel.placeLocation != nil {
                showSendCarDialog = true
            }
        }.loadingDialog(isPresented: $showProgress, message: NSLocalizedString("Sending...", comment: "")).alert(errorMsg, isPresented: $showError) {}
    }
    
    func sendLocation() async {
        let client = OCWAPIClientFactory.createAPIClient(serverUrl, token)
        
        do {
            let locationName: String = viewModel.placeName ?? NSLocalizedString("Location from phone", comment: "")
            var carUpdating = CarUpdating()
            carUpdating.sendToCarLocation = SendToCarLocation(
                id: nil, lat: String(format: "%.9f", viewModel.placeLocation!.coordinate.latitude), lon: String(format: "%.9f", viewModel.placeLocation!.coordinate.longitude), name: locationName
            )
            
            try await client.send(Paths.api.car.vin(carLocation!.vin).patch(carUpdating))
            showProgress = false
            showError = true
            errorMsg = String(format: NSLocalizedString("%@ sent to car!", comment: ""), locationName)
        } catch let e as OCWAPIError {
            let autCheckResult = await SessionHandler.checkAndRenewSession(client, e, refreshToken, token)
            switch autCheckResult {
            case let .ok(newToken):
                token = newToken?.access ?? ""
                refreshToken = newToken?.refresh ?? ""
                await sendLocation()
                break
            case let .error(error):
                showError = true
                errorMsg = "Cannot connect to server. Please try again later.";
                if let apiErr = error as? OCWAPIError {
                    if apiErr.statusCode == 503 {
                        errorMsg = "Server is unavailable. Please try again later.";
                    } else {
                        errorMsg = apiErr.apiError?.detail ?? apiErr.apiError?.error ?? errorMsg
                    }
                }
                break
            case .invalidRefreshToken:
                refreshToken = ""
                break
            }
        } catch let e {
            print(e)
            showError = true
            errorMsg = "Cannot connect to server. Please try again later.";
        }
    }
}

// ViewModel to manage search and map state
@MainActor
class LocationViewModel: NSObject, ObservableObject { // Inherit from NSObject for MKLocalSearchCompleterDelegate
    @Published var region = MKCoordinateRegion()
    @Published var annotations: [AnnotatedPlace] = []
    @Published var searchQuery: String = ""
    @Published var searchSuggestions: [MKLocalSearchCompletion] = []
    @Published var placeName: String? = nil
    @Published var placeLocation: CLLocation? = nil
    @Published var isSearchFocused: Bool = false
    
    private let searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
    }
    
    func setInitialRegion(latitude: Double, longitude: Double) {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
        // Add initial car location as an annotation if valid
        if latitude != 0.0 || longitude != 0.0 {
            annotations = [AnnotatedPlace(name: NSLocalizedString("Car Location", comment: ""), coordinate: center)]
        }
    }
    
    func search(query: String) {
        if query.isEmpty {
            searchSuggestions = []
        } else {
            searchCompleter.queryFragment = query
        }
    }
    
    func handleSearchResult(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let mapItem = response?.mapItems.first,
                  let name = mapItem.name,
                  let location = mapItem.placemark.location else {
                print("Search error: \(error?.localizedDescription ?? "No results")")
                return
            }
            
            self.placeName = name
            self.placeLocation = location
            
            
        }
    }
    
    func handleAnnotationTap(name: String, coordinate: CLLocationCoordinate2D) {
        // Example action: Print or process the selected location's details
        print("Selected: \(name), Lat: \(coordinate.latitude), Lon: \(coordinate.longitude)")
        // Add custom logic here, e.g., update a state variable, call an API, etc.
    }
    
    func onPlaceSelected(name: String, latitude: Double, longitude: Double) {
        // Placeholder function for when a place is selected
        // Add your custom logic here
    }
}

// Conform to MKLocalSearchCompleterDelegate for search suggestions
extension LocationViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchSuggestions = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Completer error: \(error.localizedDescription)")
        self.searchSuggestions = []
    }
}

// Identifiable annotation struct
struct AnnotatedPlace: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}


#Preview {
    LocationView(token: .constant(""), refreshToken: .constant(""), serverUrl: .constant(""), carLocation: .constant(nil))
}
