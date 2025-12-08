package MainPackage;

import java.util.List;

/**
 * Clase que permite almacenar información de los personajes de Overwatch
 */
public class OverwatchCharacter {

    private String name;

    private List<String> skills;

    private String role;

    public OverwatchCharacter() {
    }

    public OverwatchCharacter(String name, List<String> skills, String role) {
        this.name = name;
        this.skills = skills;
        this.role = role;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public List<String> getskills() {
        return skills;
    }

    public void setskills(List<String> skills) {
        this.skills = skills;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    @Override
    public String toString() {
        return "Character Name = " + name + ", skills = "
                + skills + ", role = " + role;
    }

}
