# Made with Framer
# by Weston Thayer
# @WestonThayer5
# www.framerjs.com

# ----------------------------------------------------------
# grids.coffee
# ----------------------------------------------------------
#
# A generic set of classes that let you deal with grids of
# cells in a left-to-right, top-to-bottom (also known as
# Screen) coordintate space.
#
# Include via {Coord, Cell, Grid} = require("grids")


# Simple coordinate object for describing the row/column of a cell
# within a grid
class exports.Coord
	constructor: (row, col) ->
		@row = row
		@col = col
	
	# Perform a value comparison of two Coords
	equals: (coord) ->
		return @row == coord.row and @col == coord.col
	
	# Returns true if the given Coord comes after this Coord in the grid
	# (left-to-right, top-to-bottom)
	lessThan: (coord) ->
		return @row < coord.row or (@row == coord.row and @col < coord.col)
	
	# Returns true if the given Coord comes before this Coord in the grid
	# (left-to-right, top-to-bottom)
	greaterThan: (coord) ->
		return @row > coord.row or (@row == coord.row and @col > coord.col)
	
	toString: () ->
		return '{"row": ' + @row + ', "col": ' + @col + '}'

# A Cell occupies a Grid Coord. It knows its Coord and some arbitrary data.
class exports.Cell
	constructor: (data) ->
		@data = data
		@coord = undefined

# A left-to-right, top-to-bottom Grid containing Cells.
class exports.Grid
	# Initializes the Grid with the given dimensions. Every Coord is
	# initially null
	constructor: (rows, columns) ->
		@_rows = rows
		@_columns = columns
		@_grid = []
		
		for r in [0..(rows - 1)]
			@_grid[r] = []
			
			for c in [0..(columns - 1)]
				@_grid[r][c] = null
	
	_forEach: (callback) ->
		for r in [0..(@_grid.length - 1)]
			for c in [0..(@_grid[r].length - 1)]
				callback(@_grid[r][c], new exports.Coord(r, c))
	
	# Add to the next available (non-null) grid slot
	add: (cell) ->
		isAdded = false
		
		@_forEach (c, coord) =>
			if not isAdded and c is null
				cell.coord = coord
				@_grid[coord.row][coord.col] = cell
				isAdded = true
		
		if not isAdded
			throw new Error("The grid is full!")
					
	# Insert the given Cell at a specific Coord, replacing if need be
	insert: (cell, coord) ->
		cell.coord = coord
		@_grid[coord.row][coord.col] = cell
	
	# Returns the Cell at the given Coord, or null
	at: (coord) ->
		return @_grid[coord.row][coord.col]

	# Returns a number (linear) representation of the given Coord for
	# this Grid
	coordToIndex: (coord) ->
		return (coord.row * @_columns) + coord.col
	
	# Returns a Coord for this Grid from a numeric index
	coordFromIndex: (index) ->
		r = Math.floor(index / @_columns)
		
		return new exports.Coord(r, index - (r * @_columns))

	# Returns a Coord that is just before the one given, or undefined if the given
	# Coord has no predecessor
	decrementCoord: (coord) ->
		i = @coordToIndex(coord)

		if i > 0
			i--
			return @coordFromIndex(i)
		else
			return undefined

	# Returns a Coord that is just after the one given, or undefined if the given
	# Coord has no successor
	incrementCoord: (coord) ->
		i = @coordToIndex(coord)
		upper = @coordToIndex(new exports.Coord(@_rows - 1, @_columns - 1))

		if i < upper
			i++
			return @coordFromIndex(i)
		else
			return undefined