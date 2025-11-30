import UIKit

class VideoResolutionViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var resolutions: [VideoResolution] = []
    private var selectedResolution: VideoResolution
    var onSelect: ((VideoResolution) -> Void)?
    
    init(currentResolution: VideoResolution, availableResolutions: [VideoResolution]) {
        self.selectedResolution = currentResolution
        self.resolutions = availableResolutions
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Video Resolution"
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
extension VideoResolutionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resolutions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let resolution = resolutions[indexPath.row]
        
        cell.textLabel?.text = resolution.displayName
        cell.accessoryType = resolution == selectedResolution ? .checkmark : .none
        cell.tintColor = .systemBlue
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Available Resolutions"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Higher resolutions and frame rates require more storage space and processing power."
    }
}

// MARK: - UITableViewDelegate
extension VideoResolutionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let resolution = resolutions[indexPath.row]
        selectedResolution = resolution
        
        // Animate checkmark change
        UIView.animate(withDuration: 0.3) {
            tableView.reloadData()
        }
        
        // Save and callback
        CameraSettings.shared.videoResolution = resolution
        onSelect?(resolution)
        
        // Show success feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Auto dismiss after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dismiss(animated: true)
        }
    }
}
