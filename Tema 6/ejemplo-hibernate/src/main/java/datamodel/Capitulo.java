package datamodel;

import javax.persistence.*;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "capitulo")
public class Capitulo {

    @Id
    @GeneratedValue
    @Column(name = "id")
    private Long id;

    @Column(name = "titulo", nullable = false)
    private String titulo;

    @Column(name = "duracion", nullable = false)
    private Integer duracion;

    @ManyToOne(optional = false, cascade = CascadeType.ALL)
    @JoinColumn(name = "serie")
    private Serie serie;

    @ManyToMany(mappedBy = "capitulos", cascade = CascadeType.ALL)
    private Set<Usuario> usuarios;

    public Capitulo () {
        // requerido por Hibernate
    }

    public Capitulo (String titulo, Integer duracion, Serie serie) {
        this.titulo = titulo;
        this.duracion = duracion;
        this.serie = serie;
        this.usuarios = new HashSet<Usuario>();
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

    public Integer getDuracion() {
        return duracion;
    }

    public void setDuracion(Integer duracion) {
        this.duracion = duracion;
    }

    public Serie getSerie () {
        return this.serie;
    }

    public void setSerie (Serie serie) {
        this.serie = serie;
    }

    public Set<Usuario> getUsuarios () {
        return this.usuarios;
    };
}
