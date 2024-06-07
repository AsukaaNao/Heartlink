import SwiftUI
import MapKit

struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var userName: String
    var profileImage: NSImage? = nil
}

struct UserAnnotationView: View {
    var userName: String
    var profileImage: NSImage?
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if let image = profileImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 46, height: 46)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 3)
                        .offset(y: -23)
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 46, height: 46)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 3)
                        .offset(y: -23)
                }
            }
            Text(userName)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(6)
                .background(Color.black.opacity(0.75))
                .clipShape(Capsule())
                .shadow(radius: 2)
                .offset(y: -20)
        }
    }
}

struct MainPage: View {
    @StateObject private var viewModel = MainPageVM()
    @Binding var showSignInView: Bool

    var body: some View {
        ZStack {
            Map(coordinateRegion: $viewModel.region, showsUserLocation: true, annotationItems: viewModel.userLocations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    UserAnnotationView(userName: location.userName, profileImage: location.profileImage)
                }
            }
            .edgesIgnoringSafeArea(.top)
            .accentColor(Color(.systemPink))
            .onAppear {
                viewModel.checkIfLocationServiceIsEnabled()
                viewModel.getUserUID()
            }
            .onDisappear {
                viewModel.stopUpdatingLocation()
                viewModel.stopFetchingLocations()
            }
            VStack {
                Spacer()
                Button("Log Out") {
                    Task {
                        do {
                            try viewModel.signOut()
                            showSignInView = true
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
                
                UserInfoView(userName: "Giselle", userLocation: "Unknown Location") // Replace with actual location if available
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .padding()
            }
            .padding()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Settings"),
                message: Text("Open System Preferences?"),
                primaryButton: .default(Text("Settings")) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.general") {
                        NSWorkspace.shared.open(url)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct UserInfoView: View {
    var userName: String
    var userLocation: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(userName)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(userLocation)
                .font(.caption)
                .foregroundColor(Color.gray)
            
            Spacer()
                .frame(height: 20)
            
            HStack {
                Button(action: {
                    // Nudge action
                    
                }) {
                    HStack {
                        Image(systemName: "hand.thumbsup")
                        Text("Nudge")
                    }
                }
                Spacer()
                Button(action: {
                    // View notifications action
                    
                }) {
                    HStack {
                        Image(systemName: "bell")
                        Text("Notification")
                    }
                }
            }
            .padding()
            Spacer()
                .frame(height: 50)
        }
        .padding()
    }
}

#Preview {
    MainPage(showSignInView: .constant(true))
}