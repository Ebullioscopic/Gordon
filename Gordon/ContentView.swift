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
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                chatList
                
                if viewModel.selectedImage != nil {
                    selectedImageView
                }
                
                inputArea
            }
            .navigationTitle("Gordon")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $viewModel.selectedImage, sourceType: imageSource)
            }
        }
    }
    
    private var chatList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
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
            .frame(height: 150)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)
    }
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button(action: {
                    imageSource = .photoLibrary
                    isShowingImagePicker = true
                }) {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                TextField("Message", text: $viewModel.userInput)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.userInput.isEmpty && viewModel.selectedImage == nil)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
        }
    }
}

struct ChatBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if case .image(let data) = message.content,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(16)
                }
                
                Text(message.content.textContent ?? "")
                    .padding(12)
                    .background(message.role == .user ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(18)
            }
            .padding(.horizontal, 4)
            
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
