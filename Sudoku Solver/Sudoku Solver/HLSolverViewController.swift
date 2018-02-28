//
//  HLSolverViewController.swift
//  Sudoku Solver
//
//  Created by Matthew Homer on 7/13/15.
//  Copyright (c) 2015 Homer Labs. All rights reserved.
//

import UIKit

class HLSolverViewController: UIViewController, UICollectionViewDataSource {

    var importArray: [String] = Array()
    var puzzleName = ""

    var _solver = HLSolver()
    var nodeCount = 0
    
    var rowsSelected    = true
    var columnsSelected = true
    var blocksSelected  = true
    
    let defaults = UserDefaults.standard
    let rowSwitchKey    = "Row"
    let columnSwitchKey = "Column"
    let blockSwitchKey  = "Block"
    let modeSelectKey   = "mode"
    let archiveKey      = "Archive"
    
    @IBOutlet weak var blockStackView: UIStackView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var puzzleNameLabel: UILabel!
    @IBOutlet weak var nodeCountLabel: UILabel!
    @IBOutlet weak var algorithmSelect: UISegmentedControl!
    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var solveButton: UIButton!
    
    @IBOutlet weak var rowSwitch: UISwitch!
    @IBOutlet weak var columnSwitch: UISwitch!
    @IBOutlet weak var blockSwitch: UISwitch!
    
    
    @IBAction func undoAction(_ sender:UISwitch)
    {
        print( "HLSolverViewController-  undoAction" )
        _solver.dataSet = _solver.previousDataSet
        updateAndDisplayCells()
        
        undoButton.isEnabled = false
    }
    
    
    @IBAction func readAction()
    {
        _solver.read()
        puzzleNameLabel.text = _solver.puzzleName
 //       _solver.prunePuzzle(rows:true, columns:true, blocks:true)
        updateAndDisplayCells()
    }
    
    
    @IBAction func writeAction()
    {
        
        _solver.save()
    }

    
    @IBAction func settingsAction()
    {
        rowsSelected    = rowSwitch.isOn
        columnsSelected = columnSwitch.isOn
        blocksSelected  = blockSwitch.isOn
        
        defaults.set(!rowsSelected,     forKey:rowSwitchKey )
        defaults.set(!columnsSelected,  forKey:columnSwitchKey )
        defaults.set(!blocksSelected,   forKey:blockSwitchKey )
    }
    
    
    @IBAction func modeSelectAction()
    {
        defaults.set(algorithmSelect.selectedSegmentIndex, forKey: modeSelectKey)
        print( "algorithmSelect.selectedSegmentIndex: \(algorithmSelect.selectedSegmentIndex)" )
/*        if algorithmSelect.selectedSegmentIndex == 0    {
            blockStackView.isHidden = true
        }
        else if algorithmSelect.selectedSegmentIndex == 1    {
            blockStackView.isHidden = false
        }
        else if algorithmSelect.selectedSegmentIndex == 2    {
            blockStackView.isHidden = false
        }   */
    }
    
    
    @IBAction func solveAction(_ sender:UIButton)
    {
         
        _solver.previousDataSet = _solver.dataSet

       switch( algorithmSelect.selectedSegmentIndex )
        {
            case 0:     //  Mono Cell
                _solver.findMonoCells(rows: rowsSelected, columns: columnsSelected)
                break
            
            case 1:     //  Find Sets
                _solver.findPuzzleSets(rows: rowsSelected, columns: columnsSelected, blocks: blocksSelected)
                break
            
            case 2:     //  Mono Sectors
                _solver.findMonoSectors(rows: rowsSelected, columns: columnsSelected)
                break
            
            default:
                break
        }
        
        updateAndDisplayCells()
    }
    
    
    func updateAndDisplayCells()    {
        _solver.updateChangedCells()
        collectionView.reloadData()
        let unsolvedCount = _solver.unsolvedCount()
        nodeCountLabel.text = "Unsolved Nodes: \(unsolvedCount)"
        
        undoButton.isEnabled = true
        if unsolvedCount == 0   {   solveButton.isEnabled = false    }
        else                    {   solveButton.isEnabled = true     }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section:Int)->Int
    {
        return _solver.kCellCount
    }


    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath:IndexPath)->UICollectionViewCell
    {

        let  cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HLPuzzleCell",
                                        for: indexPath) as! HLCollectionViewCell
        
        let (_, status) = _solver.dataSet[indexPath.row]
        
        cell.hlLabel!.text = _solver.dataSet.description(indexPath.row)

       switch status {
            
            case .givenStatus:
                cell.hlLabel!.textColor = UIColor.brown
        
            case .solvedStatus:
                cell.hlLabel!.textColor = UIColor.green
        
            case .changedStatus:
                cell.hlLabel!.textColor = UIColor.red
        
            case .unsolvedStatus:
                cell.hlLabel!.textColor = UIColor.blue
        }

        return cell
    }


    override func viewDidLoad()     {
        super.viewDidLoad()

        let nib = UINib(nibName:"HLCollectionViewCell", bundle:nil)
        collectionView.register(nib, forCellWithReuseIdentifier:"HLPuzzleCell")
        
        algorithmSelect.selectedSegmentIndex = defaults.integer(forKey: modeSelectKey)
        rowsSelected        = !defaults.bool(forKey: rowSwitchKey)
        columnsSelected     = !defaults.bool(forKey: columnSwitchKey)
        blocksSelected      = !defaults.bool(forKey: blockSwitchKey)
        rowSwitch.isOn       = rowsSelected
        columnSwitch.isOn    = columnsSelected
        blockSwitch.isOn     = blocksSelected
        
        _solver.puzzleName = puzzleName
        puzzleNameLabel.text = _solver.puzzleName
        undoButton.isEnabled = false
        
//        _solver.read()
//        updateAndDisplayCells()
//        _solver.findSetsForRow(0, sizeOfSet: 3)
//        updateAndDisplayCells()

        _solver.load(importArray)
        _solver.prunePuzzle(rows:true, columns:true, blocks:true)
        nodeCountLabel.text = "Unsolved Nodes: \(_solver.unsolvedCount())"
    }
}
