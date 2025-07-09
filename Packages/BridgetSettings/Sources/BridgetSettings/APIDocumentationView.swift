import SwiftUI
import BridgetCore

public struct APIDocumentationView: View {
    @StateObject private var documentationAgent = APIDocumentationAgent()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    Text("API Documentation Generator")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Generate comprehensive documentation for all public APIs across the Bridget project's 10 Swift Package Manager modules.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                // Status Section
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: documentationAgent.isGenerating ? "gear.circle.fill" : "doc.text")
                            .font(.title2)
                            .foregroundColor(documentationAgent.isGenerating ? .blue : .green)
                        
                        VStack(alignment: .leading) {
                            Text(documentationAgent.isGenerating ? "Generating Documentation..." : "Ready to Generate")
                                .font(.headline)
                            
                            if documentationAgent.isGenerating {
                                Text("Current Package: \(documentationAgent.currentPackage)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if documentationAgent.isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    // Progress Bar
                    if documentationAgent.isGenerating {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Progress")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(documentationAgent.documentationProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: documentationAgent.documentationProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Error Display
                if let error = documentationAgent.lastError {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Package Status
                if !documentationAgent.generatedDocs.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Generated Documentation")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 10) {
                            ForEach(Array(documentationAgent.generatedDocs.keys.sorted()), id: \.self) { packageName in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(packageName)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(5)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                // Control Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        Task {
                            await documentationAgent.generateCompleteAPIDocumentation()
                        }
                    }) {
                        HStack {
                            Image(systemName: documentationAgent.isGenerating ? "stop.fill" : "doc.text.fill")
                            Text(documentationAgent.isGenerating ? "Stop Generation" : "Generate API Documentation")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(documentationAgent.isGenerating ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(documentationAgent.isGenerating)
                    
                    if !documentationAgent.generatedDocs.isEmpty {
                        Button(action: {
                            // Open documentation folder
                            openDocumentationFolder()
                        }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                Text("Open Documentation Folder")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("API Documentation")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func openDocumentationFolder() {
        // Implementation to open the documentation folder
        print("📁 [API Doc] Opening documentation folder...")
    }
}

#Preview {
    APIDocumentationView()
} 