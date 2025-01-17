//
//  BudgetViewController.swift
//  SmartWallet
//
//  Created by Soheil on 25/04/2018.
//  Copyright © 2018 Soheil Novinfard. All rights reserved.
//

import UIKit
import CoreData

class BudgetViewController: UITableViewController, NSFetchedResultsControllerDelegate {

	@IBOutlet weak var editButton: UIBarButtonItem!
	var editingMode = false
	var fetchedResultsController: NSFetchedResultsController<Categories>!
	var totalBudget = 0.0
	var maxBudget = 0.0

	override func viewDidLoad() {
        super.viewDidLoad()

		loadData()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		loadData()
	}

	@IBAction func editPressed(_ sender: Any) {

		if editingMode == true {
			// save the data
			saveData()
			editingEnd()
		} else {
			editingBegin()
		}
	}

	func editingBegin() {
		editingMode = true
		editButton.style = .done
		editButton.title = "Save"
		tableView.reloadData()
	}

	func editingEnd() {
		editingMode = false
		editButton.style = .plain
		editButton.title = "Edit"
	}

	func loadData() {
		// prepare result controller
		if fetchedResultsController == nil {
			let request = Categories.createFetchRequest()
			let sort = NSSortDescriptor(key: "sortId", ascending: false)
			request.sortDescriptors = [sort]
			request.fetchBatchSize = 20

			fetchedResultsController = NSFetchedResultsController(
				fetchRequest: request,
				managedObjectContext: Facade.share.model.container.viewContext,
				sectionNameKeyPath: "direction",
				cacheName: nil)
			fetchedResultsController.delegate = self
		}

		let predicate = NSPredicate(format: "direction = %d", -1)
		fetchedResultsController.fetchRequest.predicate = predicate

		do {
			try fetchedResultsController.performFetch()

			// set total & max budget
			totalBudget = Facade.share.model.getTotalBudget()
			maxBudget = Facade.share.model.getMaxAmountInBudget()

			tableView.reloadData()
			loadFooter()
		} catch {
			print("Fetch failed")
		}

	}

	func loadFooter() {
		let footerView: UIView = UIView.init(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 45))
		footerView.backgroundColor = UIColor.white

		let labelView: UILabel = UILabel.init(frame: CGRect(x: 0, y: 5, width: tableView.frame.width, height: 30))
		labelView.textAlignment = .center
		labelView.text = "Total: \(getCurrencyLabel())\(totalBudget.clean)"

		footerView.addSubview(labelView)
		tableView.tableFooterView = footerView
	}

	func saveData() {
		for cell in tableView.visibleCells as! [BudgetTableViewCell] {
			let category = fetchedResultsController.object(at: tableView.indexPath(for: cell)!)
			if let amount = cell.budgetAmount.text, amount != "" {
				category.budget = getDoubleFromLocalNumber(input: amount)
			} else {
				category.budget = 0.0
			}
		}

		Facade.share.model.saveContext()

		loadData()
	}
}

extension BudgetViewController {
	override func numberOfSections(in tableView: UITableView) -> Int {
		return fetchedResultsController.sections?.count ?? 0
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sectionInfo = fetchedResultsController.sections![section]
		return sectionInfo.numberOfObjects
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "budgetCell", for: indexPath) as! BudgetTableViewCell
		let category = fetchedResultsController.object(at: indexPath)
		cell.categoryLabel.text = category.name
		cell.amountLabel.text = getCurrencyLabel()

		if category.budget != 0 {
			cell.budgetAmount.text = "\(category.budget.clean)"
		} else {
			cell.budgetAmount.text = ""
			cell.budgetPercentage.progress = 0
		}

		if category.budget != 0 && totalBudget != 0 {
			let share = category.budget / totalBudget
			let maxShare = maxBudget / totalBudget
			cell.budgetPercentage.progress = Float(share * (1 / maxShare))
		} else {
			cell.budgetPercentage.progress = 0
		}

		if editingMode {
			cell.budgetAmount.isEnabled = true
		} else {
			cell.budgetAmount.isEnabled = false
		}

		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if editingMode {
			let cell = tableView.dequeueReusableCell(withIdentifier: "budgetCell", for: indexPath) as! BudgetTableViewCell
			cell.makeFirstResponder()
		}
	}
}
