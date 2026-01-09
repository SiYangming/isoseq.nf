process PICARD_FILENAME {
    tag "$meta.id"
    label 'process_low'

    conda "conda-forge::sed=4.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(bams)

    output:
    tuple val(meta), path("renamed/*.bam"), emit: bam
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p renamed
    
    for f in *.bam; do
        # Extract the number from the filename (e.g., T6.chunk_0001.bam -> 1)
        num=\$(echo "\$f" | sed 's/.*_0*//; s/\\.bam//')
        
        # Rename to format: {prefix}.chunk{num}.bam
        mv "\$f" "renamed/${prefix}.chunk\${num}.bam"
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sed: \$(echo \$(sed --version 2>&1) | sed 's/^.*GNU sed) //; s/ .*\$//')
    END_VERSIONS
    """
}
