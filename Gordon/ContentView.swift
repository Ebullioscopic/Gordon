//
//  ContentView.swift
//  Gordon
//
//  Created by admin63 on 15/10/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GordonViewModel()
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        NavigationView {
            VStack {
                chatList
                
                if viewModel.selectedImage != nil {
                    selectedImageView
                }
                
                inputArea
            }
            .navigationTitle("Gordon")
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $viewModel.selectedImage, sourceType: imageSource)
            }
        }
    }
    
    private var chatList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.chatHistory) { message in
                    ChatBubble(message: message)
                }
            }
            .padding()
        }
    }
    
    private var selectedImageView: some View {
        Image(uiImage: viewModel.selectedImage!)
            .resizable()
            .scaledToFit()
            .frame(height: 200)
            .cornerRadius(10)
            .padding()
    }
    
    private var inputArea: some View {
        VStack {
            HStack {
                TextField("Ask Gordon something...", text: $viewModel.userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(viewModel.userInput.isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal)
            
            HStack {
                Button(action: {
                    imageSource = .photoLibrary
                    isShowingImagePicker = true
                }) {
                    Image(systemName: "photo")
                    Text("Gallery")
                }
                
                Spacer()
                
                Button(action: {
                    imageSource = .camera
                    isShowingImagePicker = true
                }) {
                    Image(systemName: "camera")
                    Text("Camera")
                }
            }
            .padding()
        }
    }
}

struct ChatBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            VStack(alignment: message.role == .user ? .trailing : .leading) {
                Text(message.content.textContent ?? "")
                    .padding(10)
                    .background(message.role == .user ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                if case .image(let data) = message.content,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(10)
                }
            }
            
            if message.role == .model { Spacer() }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
