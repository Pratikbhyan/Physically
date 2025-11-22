import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @ObservedObject var model = BlockingManager.shared
    @State private var isPickerPresented = false
    
    var body: some View {
        VStack {
            Button("Select Apps to Block") {
                isPickerPresented = true
            }
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $model.selection)
            .onChange(of: model.selection) {
                model.updateShield()
            }
        }
    }
}
