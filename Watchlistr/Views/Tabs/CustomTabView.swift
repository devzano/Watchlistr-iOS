//
//  CustomTabView.swift
//  Watchlistr
//
//  Created by Ruben Manzano on 10/27/23.
//
//
//import SwiftUI
//
//struct CustomTabView: View {
//    @EnvironmentObject var tabBarVisibilityManager: TabBarVisibilityManager
//    @State private var selectedTab = 1
//    @State private var resetKeys = [1: UUID(), 2: UUID(), 3: UUID()]
//    @ObservedObject private var keyboardResponder = KeyboardResponder()
//
//    var body: some View {
//        Group {
//            ZStack {
//                switch selectedTab {
//                case 1:
//                    MovieTabView()
//                case 2:
//                    ProfileTabView().id(resetKeys[2])
//                case 3:
//                    TVShowTabView()
//                default:
//                    EmptyView()
//                }
//                VStack {
//                    Spacer()
//                    if !tabBarVisibilityManager.isTabBarHidden && !keyboardResponder.isKeyboardVisible {
//                        pillTabBar
//                            .padding(.bottom, adjustedBottomPadding())
//                    }
//                }
//            }
////            .edgesIgnoringSafeArea(.bottom)
//            .navigationViewStyle(StackNavigationViewStyle())
//        }
//    }
//
//    private func adjustedBottomPadding() -> CGFloat {
//        let deviceType = UIDevice().type
//        let modelsWithReducedPadding: [Model] = [.iPhoneSE3, .iPhoneSE, .iPhone8Plus, .iPhone8, .iPhone7Plus, .iPhone7, .iPhone6SPlus, .iPhone6Plus, .iPhone6, .iPhone6S]
//        return modelsWithReducedPadding.contains(deviceType) ? getBottomSafeAreaHeight() - 15 : getBottomSafeAreaHeight() - 70
//    }
//
//    private func getBottomSafeAreaHeight() -> CGFloat {
//        return getKeyWindow()?.safeAreaInsets.bottom ?? 0
//    }
//    
//    private var pillTabBar: some View {
//        HStack {
//            tabItem(title: "Movies", image: "film", tag: 1)
//            Spacer()
//            tabItem(title: "Profile", image: "person", tag: 2)
//            Spacer()
//            tabItem(title: "TV Shows", image: "tv", tag: 3)
//        }
//        .padding()
//        .background(Color(.systemBackground)
//            .opacity(0.8)
//            .cornerRadius(25))
//        .padding(.horizontal)
//    }
//
//    private func tabItem(title: String, image: String, tag: Int) -> some View {
//        VStack {
//            Image(systemName: image)
//            Text(title)
//        }
//        .foregroundColor(selectedTab == tag ? .blue : .gray)
//        .onTapGesture {
//            if selectedTab == tag {
//                resetKeys[tag] = UUID()
//            } else {
//                selectedTab = tag
//            }
//        }
//    }
//}
//
//struct CustomTabView_Previews: PreviewProvider {
//    static var previews: some View {
//        CustomTabView()
//            .environmentObject(AuthViewModel())
//            .environmentObject(WatchlistState())
//            .environmentObject(TabBarVisibilityManager())
//    }
//}
//
//extension View {
//    func getKeyWindow() -> UIWindow? {
//        return UIApplication.shared.connectedScenes
//            .compactMap { $0 as? UIWindowScene }
//            .flatMap { $0.windows }
//            .first { $0.isKeyWindow }
//    }
//}
