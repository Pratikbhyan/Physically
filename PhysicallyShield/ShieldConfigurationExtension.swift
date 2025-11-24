import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    // MARK: - Configuration
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Customize the shield as needed for applications.
        return ShieldConfiguration(
            backgroundColor: .systemGray,
            icon: UIImage(named: "ShieldLogo"),
            title: ShieldConfiguration.Label(text: " ", color: .clear),
            subtitle: ShieldConfiguration.Label(text: " ", color: .clear),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Use Banked Minutes", color: .white),
            primaryButtonBackgroundColor: .black,
            secondaryButtonLabel: nil
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield as needed for applications shielded because of their category.
        return ShieldConfiguration(
            backgroundBlurStyle: .dark
        )
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Customize the shield as needed for web domains.
        return ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0),
            icon: UIImage(systemName: "dumbbell.fill"),
            title: ShieldConfiguration.Label(text: "Access Denied", color: .white),
            subtitle: ShieldConfiguration.Label(text: "Price: 5 Squats", color: .white),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Pay the Toll", color: .black),
            primaryButtonBackgroundColor: .white
        )
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield as needed for web domains shielded because of their category.
        return ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0),
            icon: UIImage(systemName: "dumbbell.fill"),
            title: ShieldConfiguration.Label(text: "Access Denied", color: .white),
            subtitle: ShieldConfiguration.Label(text: "Price: 5 Squats", color: .white),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Pay the Toll", color: .black),
            primaryButtonBackgroundColor: .white
        )
    }
}
