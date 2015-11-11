# Made with Framer
# by Weston Thayer
# @WestonThayer5
# www.framerjs.com

# ----------------------------------------------------------
# iOS Home Screen Rearrange
# ----------------------------------------------------------
#
# This works by creating a conceptual 3x9 grid of "drag
# cells" overtop of the icons. When an icon is being dragged,
# we react if its midpoint intersects with a drag cell. Some
# drag cells trigger rearrange, and others trigger folder
# creation. Use the configuration flag below to visualize
# the drag grid.
#
# The app icons are also stored as "icon cells" in a 3x4
# "icon grid" for easy access.
#
# An individual cell in a grid is referrered to by a
# coordinate, which is just a row and a column value.

# Import generic grid helpers
{Coord, Cell, Grid} = require("grids")

# ---- CONFIGURATION VARIABLES ----

Framer.Defaults.Animation = { time: 0.2 }

# Set this to true to visualize the drag cells. Red indicates a
# folder creation zone, blue indicates a rearrange zone
shouldDragCellsBeVisible = false

iconWidth = 120
iconHeight = 120

# ---- LAYER IMPORT ----

# This imports all the layers for "icons-ios7" into iconsIos7Layers
# Credit to @despoth on Behance
# https://www.behance.net/gallery/9254099/iOS-7-Home-Screen-With-100-Shape-Layers-FREE-PSD
homeLayers = Framer.Importer.load "imported/icons-ios7"

# ---- HELPER CLASSES AND FUNCTIONS ----

class DragCell extends Cell
	constructor: (data) ->
		super(data)

class DragGrid extends Grid
	constructor: () ->
		super(3, 9)
		
		xOffset = yOffset = 0
		rearrangeCellWidth = 32
		folderCellWidth = (Screen.width - (rearrangeCellWidth * 5)) / 4
	
		if shouldDragCellsBeVisible
			dragGridOverlay = new Layer
				backgroundColor: null
				y: homeLayers.iconGrid.y
				width: Screen.width
				height: 1000
	
		# Fill the 3x9 drag grid
		for r in [0..(@_grid.length - 1)]
			for c in [0..(@_grid[r].length - 1)]
				w = if c % 2 == 0 then rearrangeCellWidth else folderCellWidth
				t = if c % 2 == 0 then "rearrange" else "folder"
				
				cell = new DragCell
					type: t
					x1: xOffset
					y1: yOffset
					x2: xOffset + w
					y2: yOffset + iconHeight
				
				@insert(cell, new Coord(r, c))
				
				xOffset += w
	
				if shouldDragCellsBeVisible
					dragCellOverlay = new Layer
						superLayer: dragGridOverlay
						x: cell.data.x1
						y: cell.data.y1
						width: cell.data.x2 - cell.data.x1
						height: cell.data.y2 - cell.data.y1
						opacity: 0.7
						backgroundColor: if c % 2 == 0 then "red" else "blue"
			
			xOffset = 0
			yOffset += iconHeight + 51
	
	# Returns which drag cell the given layer's midpoint is in
	hovering: (layer) ->
		midPoint =
			x: homeLayers.iconGrid.x + layer.midX # x is relative to 0
			y: layer.midY - 16 # leave app icon's label out of this, so offset a bit
		
		c = undefined
		
		@_forEach (cell, coord) ->
			if cell.data.x1 <= midPoint.x and cell.data.x2 > midPoint.x and cell.data.y1 <= midPoint.y and cell.data.y2 > midPoint.y
				c = cell
	
		return c

class IconCell extends Cell
	constructor: (layer) ->
		data =
			layer: layer
			x1: layer.x
			y1: layer.y
		
		super(data)

class IconGrid extends Grid
	constructor: () ->
		super(3, 4)
		@isRearrangeMode = false
		
	findCellWithLayer: (layer) ->
		c = undefined
		
		@_forEach (cell, coord) ->
			if cell.data.layer is layer
				c = cell
		
		return c
	
	jiggleAllExcept: (layer) ->
		@_forEach (cell, coord) ->
			if cell.data.layer isnt layer
				cell.data.layer.states.switch("jiggling")
	
	# Move the given icon layer to the cell at the given coordinate
	rearrange: (cell, coord) ->
		# Work with linear indexes is a lot easier than 2D coordinates
		indexStart = @coordToIndex(cell.coord)
		indexEnd = @coordToIndex(coord)
		
		# Item is moving foreward
		lowIndex = indexStart + 1
		highIndex = indexEnd
		dir = -1
		
		if indexEnd < indexStart # Item is moving backward
			lowIndex = indexEnd
			highIndex = indexStart - 1
			dir = 1
			
		iconsToReindex = []
		
		# First reposition everything
		for i in [lowIndex..highIndex]
			curCell = iconGrid.at(@coordFromIndex(i))
			destCell = iconGrid.at(@coordFromIndex(i + dir))
			
			curCell.data.layer.animate
				properties:
					x: destCell.data.x1
					y: destCell.data.y1
			
			iconsToReindex[i] = curCell.data.layer
		
		# Store the layer being dragged, it's cell reference gets blown away in
		# the next loop
		layerCache = cell.data.layer
		
		# Assign new slots after positioning
		for i in [lowIndex..highIndex]
			curLayer = iconsToReindex[i]
			destCell = iconGrid.at(@coordFromIndex(i + dir))
			destCell.data.layer = curLayer
		
		# Record the swap on the primary item
		iconGrid.at(coord).data.layer = layerCache

# Given an icon grid coordinate, return a drag grid coordinate
# that is roughly equivalent
iconGridCoordToDragGridCoord = (iconCoord) ->
	return new Coord(iconCoord.row, (iconCoord.col * 2) + 1)

# Given a drag grid coordinate, return an icon grid coordinate that is
# roughly equivalent, or undefined if there's no match
dragGridCoordToIconGridCoord = (dragCoord) ->
	if dragCoord.col % 2 != 1
		return undefined
	
	return new Coord(dragCoord.row, (dragCoord.col - 1) / 2)

# ---- INITIALIZATION AND EVENT REGISTRATION ----

dragGrid = new DragGrid()
iconGrid = new IconGrid()

# Global reference so that we can switch out of the "hovering" state
hoveredIconCell = undefined

# Fill the 3x4 icon grid and initialize app icon states, events
for icon in homeLayers.iconGrid.subLayers
	icon.draggable.enabled = false
	
	# Add layer that shows on press
	pressPlate = new Layer
		superLayer: icon
		width: 120
		height: 120
		borderRadius: 25
		backgroundColor: "black"
		opacity: 0.5
		visible: false
	pressPlate.centerX()
	
	# Add layer that shows for folder creation
	folderPlate = new Layer
		superLayer: icon
		width: 120
		height: 120
		borderRadius: 25
		backgroundColor: "white"
		opacity: 0.5
		visible: false
	folderPlate.centerX()
	
	# Add jiggle animations
	icon.iconJiggleAnim1 = new Animation
		layer: icon
		properties: { rotation: 2 }
		time: 0.1
	
	icon.iconJiggleAnim2 = new Animation
		layer: icon
		properties: { rotation: -2 }
		time: 0.1
	
	# Store a reference back to the icon so that 'this' capture works correctly
	icon.iconJiggleAnim1.layer = icon
	icon.iconJiggleAnim2.layer = icon
	
	icon.iconJiggleAnim1.on Events.AnimationEnd, () -> @.layer.iconJiggleAnim2.start()
	icon.iconJiggleAnim2.on Events.AnimationEnd, () -> @.layer.iconJiggleAnim1.start()
	
	# Define the interaction states for the icon
	icon.states.add
		pressing: {}
		jiggling: {}
		dragging: { scale: 1.15, opacity: 0.7 }
		hovering: {}
	
	# Most properties are set here so that we can touch subLayers and states
	# can clean up after themselves
	icon.on Events.StateWillSwitch, (from, to, states) ->
		layer = states.layer
		
		switch from
			when "pressing"
				layer.subLayers[0].visible = false
			when "jiggling"
				layer.iconJiggleAnim1.stop()
				layer.iconJiggleAnim2.stop()
				layer.rotation = 0
			when "dragging"
				layer.draggable.enabled = false
				layer.subLayers[0].visible = false
				layer.scale = 1.0
				layer.opacity = 1.0
			when "hovering"
				layer.subLayers[1].scale = 1.0
				layer.subLayers[1].borderRadius = 25
				layer.subLayers[1].visible = false
		
		switch to
			when "pressing"
				layer.subLayers[0].visible = true
			when "jiggling"
				layer.iconJiggleAnim1.start()
			when "dragging"
				layer.bringToFront()
				layer.draggable.enabled = true
				layer.subLayers[0].visible = true
			when "hovering"
				layer.subLayers[1].visible = true
				layer.subLayers[1].animate
					properties: { scale: 1.2, borderRadius: 30 }
	
	# Register for interaction events
	
	icon.on Events.TouchStart, (event, layer) ->
		if !iconGrid.isRearrangeMode
			layer.states.switchInstant("pressing")
			
			# Long-press time is about 800ms
			Utils.delay 0.8, () ->
				if layer.states.current is "pressing"
					iconGrid.isRearrangeMode = true
					layer.states.switch("dragging")
					iconGrid.jiggleAllExcept(layer)
		else
			layer.states.switch("dragging")
	
	icon.on Events.DragMove, (event) ->
		layer = @
		
		iconCell = iconGrid.findCellWithLayer(layer)
		dragCell = dragGrid.at(iconGridCoordToDragGridCoord(iconCell.coord))
		hoveredDragCell = dragGrid.hovering(layer)
		
		# If we are over a drag cell
		if hoveredDragCell
			hoveredIconCellCoord = dragGridCoordToIconGridCoord(hoveredDragCell.coord)
			tmpHoveredIconCell = if hoveredIconCellCoord then iconGrid.at(hoveredIconCellCoord)
			
			# And it's not our own
			if iconCell isnt tmpHoveredIconCell
				# de-hover the currently hovering cell, if there is one
				if hoveredIconCell and hoveredIconCell isnt tmpHoveredIconCell
					hoveredIconCell.data.layer.states.switch("jiggling")
					
				hoveredIconCell = tmpHoveredIconCell
				
				# If we're over a different row or over a non-adjacent drag cell...
				if dragCell.coord.row != hoveredDragCell.coord.row or Math.abs(dragCell.coord.col - hoveredDragCell.coord.col) > 1
					if hoveredDragCell.data.type is "folder"
						if hoveredIconCell.data.layer.states.current isnt "hovering"
							hoveredIconCell.data.layer.states.switch("hovering")
					else # it's a rearrange zone
						folderDragCoord = undefined
						
						if dragCell.coord.lessThan(hoveredDragCell.coord)
							# Special case for the start of a row
							if dragCell.coord.row != hoveredDragCell.coord.row and hoveredDragCell.coord.col == 0
								folderDragCoord = dragGrid.incrementCoord(hoveredDragCell.coord)
							else
								folderDragCoord = dragGrid.decrementCoord(hoveredDragCell.coord)
						else
							# Special case for the end of a row
							if dragCell.coord.row != hoveredDragCell.coord.row and hoveredDragCell.coord.col == 8
								folderDragCoord = dragGrid.decrementCoord(hoveredDragCell.coord)
							else
								folderDragCoord = dragGrid.incrementCoord(hoveredDragCell.coord)
						
						iconGrid.rearrange(iconCell, dragGridCoordToIconGridCoord(folderDragCoord))
	
	icon.on Events.DragEnd, (event) ->
		layer = @
		
		if layer.states.current is "dragging"
			cell = iconGrid.findCellWithLayer(layer)
			layer.animate
				properties:
					x: cell.data.x1
					y: cell.data.y1
		
			layer.states.switch("jiggling")

	icon.on Events.TouchEnd, (event, layer) ->
		if layer.states.current is "pressing"
			layer.states.switch("default")
	
	iconGrid.add(new IconCell(icon))