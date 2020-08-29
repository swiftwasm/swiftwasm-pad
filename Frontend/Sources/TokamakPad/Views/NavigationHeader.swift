import TokamakDOM


struct NavigationHeader: View {
    var body: some View {
        HStack {
            Text("Tokamak")
                .font(.title)
                .padding()
            Spacer()
            Text("Draft.swift")
            Spacer()
        }
    }
}
