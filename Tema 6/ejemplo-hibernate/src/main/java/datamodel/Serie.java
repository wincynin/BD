package datamodel;


import javax.persistence.*;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "serie")
public class Serie {

    @Id
    @GeneratedValue
    @Column(name = "id")
    private Long id;

    @Column(name = "titulo", nullable = false)
    private String titulo;

    @Column(name = "genero", nullable = false)
    private String genero;

    @OneToMany(mappedBy = "serie", cascade = CascadeType.ALL)
    private Set<Capitulo> capitulos;

    public Serie () {
        // requerido por Hibernate
    }

    public Serie (String titulo, String genero) {
        this.titulo = titulo;
        this.genero = genero;
        this.capitulos = new HashSet<Capitulo>();
    }

    public Long getId() {
        return id;
    }

    public String getTitulo() {
        return titulo;
    }

    public void setTitulo(String titulo) {
        this.titulo = titulo;
    }

    public String getGenero() {
        return genero;
    }

    public void setGenero(String genero) {
        this.genero = genero;
    }

    public Set <Capitulo> getCapitulos() {
        return this.capitulos;
    }
}
