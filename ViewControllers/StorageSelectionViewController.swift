import UIKit

protocol StorageSelectionDelegate: AnyObject {
    func didSelectStorage(type: StorageType)
}

class StorageSelectionViewController: UIViewController {
    
    weak var delegate: StorageSelectionDelegate?
    private let storageManager = StorageManager.shared
    private var storages: [StorageInfo] = []
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadStorages()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Container
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        
        // Title
        titleLabel.text = "Select Storage Location"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        
        // TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StorageCell.self, forCellReuseIdentifier: "StorageCell")
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .clear
        containerView.addSubview(tableView)
        
        // Layout
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 340),
            containerView.heightAnchor.constraint(equalToConstant: 300),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func loadStorages() {
        storages = storageManager.getAvailableStorages()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension StorageSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StorageCell", for: indexPath) as! StorageCell
        let storage = storages[indexPath.row]
        cell.configure(with: storage)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension StorageSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let storage = storages[indexPath.row]
        
        if !storage.isAvailable {
            showAlert(title: "Not Available", message: "External storage is not connected. Please connect USB drive via Lightning Camera Connection Kit.")
            return
        }
        
        delegate?.didSelectStorage(type: storage.type)
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - StorageCell
class StorageCell: UITableViewCell {
    
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let pathLabel = UILabel()
    private let statusLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
        contentView.addSubview(iconImageView)
        
        // Name
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        contentView.addSubview(nameLabel)
        
        // Path
        pathLabel.font = .systemFont(ofSize: 12)
        pathLabel.textColor = .secondaryLabel
        pathLabel.numberOfLines = 2
        contentView.addSubview(pathLabel)
        
        // Status
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.textAlignment = .right
        contentView.addSubview(statusLabel)
        
        // Layout
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        pathLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),
            
            pathLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            pathLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            pathLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            
            statusLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            statusLabel.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func configure(with storage: StorageInfo) {
        switch storage.type {
        case .internal:
            iconImageView.image = UIImage(systemName: "internaldrive.fill")
            iconImageView.tintColor = .systemBlue
        case .external:
            iconImageView.image = UIImage(systemName: "externaldrive.fill")
            iconImageView.tintColor = storage.isAvailable ? .systemGreen : .systemGray
        }
        
        nameLabel.text = storage.name
        pathLabel.text = storage.path
        
        if storage.isAvailable {
            statusLabel.text = "Available"
            statusLabel.textColor = .systemGreen
            accessoryType = .disclosureIndicator
            selectionStyle = .default
        } else {
            statusLabel.text = "Not Connected"
            statusLabel.textColor = .systemRed
            accessoryType = .none
            selectionStyle = .none
        }
    }
}
