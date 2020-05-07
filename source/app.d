module app;

import gtk.Main;

import ui.sudokuApp;

void main(string[] args)
{
    Main.init(args);
    auto sudokuApp = new SudokuApp();
    sudokuApp.run(args);
}
