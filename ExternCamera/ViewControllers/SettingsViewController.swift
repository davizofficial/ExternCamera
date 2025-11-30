import UIKit

class SettingsViewController: UIViewController {
    
    private let settings = CameraSettings.shared
    private let storageManager = StorageManager.shared
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    var onStorageChange: ((StorageType) -> Void)?
    var currentStorageType: StorageType = .internal
    
    private enum Section: Int, CaseIterable {
        case storage
        case camera
        case photo
        case video
        case about
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Settings"
        view.backgroundColor = .systemBackground
        
        // Close button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(didTapDone)
        )
        
        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(SwitchCell.self, forCellReuseIdentifier: "SwitchCell")
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func didTapDone() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        
        switch section {
        case .storage: return 3
        case .camera: return 2
        case .photo: return 2
        case .video: return 1
        case .about: return 2
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch section {
        case .storage:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                cell.textLabel?.text = "Current Storage"
                cell.detailTextLabel?.text = currentStorageType == .external ? "USB Drive" : "Internal"
                cell.accessoryType = .disclosureIndicator
                return cell
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                cell.textLabel?.text = "USB Drive Status"
                let isConnected = storageManager.isExternalStorageAvailable()
                cell.detailTextLabel?.text = isConnected ? "Connected ✅" : "Not Connected"
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                cell.textLabel?.text = "USB Path"
                if let url = storageManager.getUSBDriveURL() {
                    cell.detailTextLabel?.text = url.path
                } else {
                    cell.detailTextLabel?.text = "Not Available"
                }
                cell.detailTextLabel?.font = .systemFont(ofSize: 11)
                cell.selectionStyle = .none
                return cell
            }
            
        case .camera:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
                cell.configure(
                    title: "Grid",
                    isOn: settings.showGrid,
                    onChange: { [weak self] isOn in
                        self?.settings.showGrid = isOn
                    }
                )
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                cell.textLabel?.text = "Preserve Settings"
                cell.detailTextLabel?.text = "Camera Mode, Filter"
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            
        case .photo:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
                cell.configure(
                    title: "Auto HDR",
                    isOn: settings.hdrEnabled,
                    onChange: { [weak self] isOn in
                        self?.settings.hdrEnabled = isOn
                    }
                )
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
                cell.configure(
                    title: "Live Photo",
                    isOn: settings.livePhotoEnabled,
                    onChange: { [weak self] isOn in
                        self?.settings.livePhotoEnabled = isOn
                    }
                )
                return cell
            }
            
        case .video:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = "Record Video"
            let resolution = settings.videoResolution
            cell.detailTextLabel?.text = resolution.displayName
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .about:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.selectionStyle = .none
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "Version"
                cell.detailTextLabel?.text = "1.0.0"
            } else {
                cell.textLabel?.text = "USB Path"
                cell.detailTextLabel?.text = "/private/var/mobile/Media/USBDRIVE/"
                cell.detailTextLabel?.font = .systemFont(ofSize: 10)
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        
        switch section {
        case .storage: return "Storage"
        case .camera: return "Camera"
        case .photo: return "Photo"
        case .video: return "Video"
        case .about: return "About"
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        
        switch section {
        case .storage:
            return "Connect USB drive via Lightning Camera Connection Kit. USB must be formatted as FAT32."
        case .photo:
            return "HDR blends the best parts of separate exposures into a single photo. Live Photo captures 1.5 seconds of motion."
        default:
            return nil
        }
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        if section == .storage && indexPath.row == 0 {
            showStorageSelection()
        } else if section == .video && indexPath.row == 0 {
            showVideoResolutionSelection()
        }
    }
    
    private func showStorageSelection() {
        let storageVC = StorageSelectionViewController()
        storageVC.delegate = self
        storageVC.modalPresentationStyle = .overFullScreen
        storageVC.modalTransitionStyle = .crossDissolve
        present(storageVC, animated: true)
    }
    
    private func showVideoResolutionSelection() {
        let cameraManager = CameraManager()
        let availableResolutions = cameraManager.getSupportedResolutions()
        let currentResolution = settings.videoResolution
        
        let resolutionVC = VideoResolutionViewController(
            currentResolution: currentResolution,
            availableResolutions: availableResolutions
        )
        
        resolutionVC.onSelect = { [weak self] resolution in
            self?.tableView.reloadData()
            
            // Show success animation
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        let navController = UINavigationController(rootViewController: resolutionVC)
        navController.modalPresentationStyle = .pageSheet
        
        // Animate presentation
        present(navController, animated: true)
    }
}

// MARK: - StorageSelectionDelegate
extension SettingsViewController: StorageSelectionDelegate {
    func didSelectStorage(type: StorageType) {
        currentStorageType = type
        onStorageChange?(type)
        tableView.reloadData()
    }
}

// MARK: - SwitchCell
class SwitchCell: UITableViewCell {
    private let switchControl = UISwitch()
    private var onChange: ((Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        accessoryView = switchControl
        switchControl.addTarget(self, action: #selector(didToggleSwitch), for: .valueChanged)
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(title: String, isOn: Bool, onChange: @escaping (Bool) -> Void) {
        textLabel?.text = title
        switchControl.isOn = isOn
        self.onChange = onChange
    }
    
    @objc private func didToggleSwitch() {
        onChange?(switchControl.isOn)
    }
}
