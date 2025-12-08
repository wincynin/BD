package MainPackage;

import java.awt.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Clase que permite almacenar las diferentes Skins para cada personaje
 */
public class Skin {
    private String name;
    private List<String> color = new ArrayList<String>();

    public Skin() {
    }

    public Skin(String name, List<String> color) {
        this.name = name;
        this.color = color;
    }

    public Skin(String name, String color) {
        this.name = name;
        this.color.add(color);
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public List<String> getcolor() {
        return color;
    }

    public void setcolor(List<String> color) {
        this.color = color;
    }

    public void addcolor(String oneColor){ this.color.add(oneColor);}

    @Override
    public String toString() {
        return "Skin Name = " + name + ", Colors = "+ color;
    }
}
