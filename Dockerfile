ARG MIRACL_VERSION=latest
FROM mgoubran/miracl:base-$MIRACL_VERSION

ADD . /code
RUN git clone https://github.com/sergivalverde/nifti_tools && \
    mv nifti_tools /code/depends/NIFTI_TOOLS
ENV MIRACL_HOME=/code
RUN python /code/setup.py install

###############################################################################
#--- Allen atlas alias ----

WORKDIR /tmp
RUN git clone https://github.com/vsoch/MIRACLextra && \
    cd MIRACLextra && \
    mv ara /code/atlases/ara

ENV aradir "${MIRACL_HOME}/atlases/ara"

# Templates (atlas images)
ENV allen10 "${MIRACL_HOME}/atlases/ara/template/average_template_10um.nii.gz"
ENV allen25 "${MIRACL_HOME}/atlases/ara/template/average_template_25um.nii.gz"
ENV allen50 "${MIRACL_HOME}/atlases/ara/template/average_template_50um.nii.gz"

# Annotations (labels)
ENV lbls10 "${MIRACL_HOME}/atlases/ara/annotation/annotation_hemi_combined_10um.nii.gz"
ENV lbls25 "${MIRACL_HOME}/atlases/ara/annotation/annotation_hemi_combined_25um.nii.gz"
ENV lbls50 "${MIRACL_HOME}/atlases/ara/annotation/annotation_hemi_combined_50um.nii.gz"

# Grand-parents labels
ENV gplbls25="${MIRACL_HOME}/atlases/ara/annotation/annotation_hemi_combined_25um_parent-level_3.nii.gz"
ENV gplbls50="${MIRACL_HOME}/atlases/ara/annotation/annotation_hemi_combined_50um_parent-level_3.nii.gz"

# ITK-snap LUT
ENV snaplut "${MIRACL_HOME}/atlases/ara/ara_snaplabels_lut.txt"
# Freeview LUT
ENV freelut "${MIRACL_HOME}/atlases/ara/ara_freeviewlabels_lut.txt"

# ANTs commands
RUN ln -s "${MIRACL_HOME}/depends/ants/antsRegistrationMIRACL.sh" /usr/bin/ants_miracl_clar && \
    chmod +x /usr/bin/ants_miracl_clar
RUN ln -s "${MIRACL_HOME}/depends/ants/antsRegistrationMIRACL_MRI.sh" /usr/bin/ants_miracl_mr && \
    chmod +x /usr/bin/ants_miracl_clar

################################################################################

# Clean up extra numpy
RUN  ls /opt/miniconda/lib/python2.7/site-packages/num*

ENTRYPOINT ["/opt/miniconda/bin/miracl"]
