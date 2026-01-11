process GSTAMA_FILELIST {
    tag "$meta.id"
    label 'process_low'

    conda "conda-forge::sed=4.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(bed)
    val cap
    val order

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    for i in *.bed
    do
        # 1. Check the file status corresponding to the variable i
        #    The "-s" test option verifies two conditions simultaneously:
        #    - The file exists in the filesystem
        #    - The file has a size greater than 0 bytes (non-empty)
        # 2. If the above conditions are both satisfied (return true),
        #    append the formatted tab-separated content to the tsv file
        #    whose prefix is specified by the variable ${prefix}
        if [ -s "\${i}" ]; then
            echo -e "\${i}\\t${cap}\\t${order}\\t\${i}" >> ${prefix}.tsv
        fi
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        echo: \$( echo --version | head -n1 | sed -e 's/echo (GNU coreutils) //')
    END_VERSIONS
    """
}
