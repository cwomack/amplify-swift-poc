import Amplify
import Authenticator
import SwiftUI

struct ContentView: View {
    @State private var userAttributes: [AuthUserAttribute] = []
    @State private var showUpdateAttribute = false
    @State private var selectedAttribute: AuthUserAttribute?
    @State private var newAttributeValue = ""
    @State private var errorMessage: String?

    var body: some View {
        Authenticator { state in
            ScrollView {
                VStack(spacing: 20) {
                    Text("Welcome, \(state.user.username)")
                        .font(.title)

                    Button("Fetch User Attributes") {
                        Task {
                            await fetchUserAttributes()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    if !userAttributes.isEmpty {
                        ForEach(userAttributes, id: \.key) { attribute in
                            AttributeRow(attribute: attribute) {
                                selectedAttribute = attribute
                                newAttributeValue = attribute.value
                                showUpdateAttribute = true
                            }
                        }
                    }

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }

                    Button("Sign out") {
                        Task {
                            await state.signOut()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .sheet(isPresented: $showUpdateAttribute) {
                if let attribute = selectedAttribute {
                    UpdateAttributeView(
                        attribute: attribute,
                        attributeValue: $newAttributeValue,
                        updateAction: updateUserAttribute
                    )
                }
            }
        }
    }

    func fetchUserAttributes() async {
        do {
            userAttributes = try await Amplify.Auth.fetchUserAttributes()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to fetch user attributes: \(error.localizedDescription)"
        }
    }

    func updateUserAttribute() {
        guard let attribute = selectedAttribute else { return }

        Task {
            do {
                let updatedAttribute = AuthUserAttribute(attribute.key, value: newAttributeValue)
                let result = try await Amplify.Auth.update(userAttribute: updatedAttribute)
                print("Update result: \(result)")
                await fetchUserAttributes()
                errorMessage = nil
                showUpdateAttribute = false
            } catch {
                errorMessage = "Failed to update user attribute: \(error.localizedDescription)"
            }
        }
    }
}

struct AttributeRow: View {
    let attribute: AuthUserAttribute
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading) {
                Text(attribute.key.rawValue)
                    .font(.headline)
                Text(attribute.value)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UpdateAttributeView: View {
    let attribute: AuthUserAttribute
    @Binding var attributeValue: String
    let updateAction: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Update Attribute")) {
                    Text(attribute.key.rawValue)
                        .font(.headline)
                    
                    switch attribute.key.rawValue {
                    case "birthdate":
                        DatePicker("Birthdate", selection: Binding(
                            get: { DateFormatter.iso8601.date(from: attributeValue) ?? Date() },
                            set: { attributeValue = DateFormatter.iso8601.string(from: $0) }
                        ), displayedComponents: .date)
                    case "custom:display_name":
                        TextField("Display Name", text: $attributeValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    case "custom:favorite_number":
                        Stepper(value: Binding(
                            get: { Int(attributeValue) ?? 1 },
                            set: { attributeValue = String($0) }
                        ), in: 1...100) {
                            Text("Favorite Number: \(attributeValue)")
                        }
                    case "custom:is_beta_user":
                        Toggle("Is Beta User", isOn: Binding(
                            get: { attributeValue.lowercased() == "true" },
                            set: { attributeValue = $0 ? "true" : "false" }
                        ))
                    case "custom:started_free_trial":
                        DatePicker("Free Trial Start", selection: Binding(
                            get: { DateFormatter.iso8601.date(from: attributeValue) ?? Date() },
                            set: { attributeValue = DateFormatter.iso8601.string(from: $0) }
                        ), displayedComponents: [.date, .hourAndMinute])
                    default:
                        TextField("New Value", text: $attributeValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Section {
                    Button("Update") {
                        updateAction()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Update Attribute")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
