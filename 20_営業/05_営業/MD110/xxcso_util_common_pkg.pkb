CREATE OR REPLACE PACKAGE BODY APPS.xxcso_util_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_util_common_pkg(BODY)
 * Description      : ���ʊ֐�(XXCSO���[�e�B���e�B�j
 * MD.050/070       :
 * Version          : 1.1
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_base_name             F    V     ���_���擾�֐�
 *  get_parent_base_code      F    V     �e���_�R�[�h�擾�֐�
 *  get_emp_parameter         F    V     �]�ƈ��p�����[�^�擾�֐�
 *  get_lookup_meaning        F    V     �N�C�b�N�R�[�h���e�擾�֐�(TYPE�̂�)
 *  get_lookup_description    F    V     �N�C�b�N�R�[�h�E�v�擾�֐�(TYPE�̂�)
 *  get_lookup_attribute      F    V     �N�C�b�N�R�[�hDFF�l�擾�֐�(TYPE�̂�)
 *  get_lookup_info           P    -     �N�C�b�N�R�[�h�擾����(TYPE�̂�)
 *  get_business_year         F    N     �N�x�擾�֐�
 *  check_date                F    B     ���t�����`�F�b�N�֐�
 *  check_ar_gl_period_status F    V     AR��v���ԃN���[�Y�`�F�b�N
 *  get_online_sysdate        F    D     �V�X�e�����t�擾�֐��i�I�����C���p�j
 *  get_ar_gl_period_from     F    D     AR��v���ԊJ�n���擾�֐�
 *  chk_exe_report_visite_sales
 *                            P    -     �K�┄��v��Ǘ��\�o�͔���֐�
 *  get_working_days          F    N     �c�Ɠ����擾�֐�
 *  chk_responsibility        F    -     ���O�C���ҐE�Ӕ���֐�
 *  conv_multi_byte           F    -     ���p�����S�p�u���֐�
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/07    1.0   H.Ogawa          �V�K�쐬
 *  2008/11/11    1.0   K.Hosoi          get_business_year(�N�x�擾�֐�)��ǋL
 *  2008/11/19    1.0   H.Ogawa          get_lookup_info�F����̌����������C��
 *  2008/11/25    1.0   H.Ogawa          get_lookup_info�F�ԋp�l��ݒ�
 *  2008/11/26    1.0   K.Hosoi          get_emp_parameter�Fid_issue_date�̌^��
 *                                       DATE����VARCHAR2�֏C��
 *  2008/11/26    1.0   H.Ogawa          ���_���擾�֐��ŋ��_����description����
 *                                       attribute4�ɏC��
 *  2008/12/04    1.0   K.Cho            check_date(���t�����`�F�b�N�֐�)��ǋL
 *  2008/12/04    1.0   H.Ogawa          get_emp_parameter�F���t�̏�����ǉ�
 *  2008/12/08    1.0   T.Kyo            check_ar_gl_period_status:AR��v���ԃN���[�Y�`�F�b�N 
 *  2008/12/16    1.0   H.Ogawa          LOOKUP_TYPE�݂̂ŃN�C�b�N�R�[�h���擾����֐���ǉ�
 *  2008/12/16    1.0   H.Ogawa          get_online_sysdate(�V�X�e�����t�擾�֐�
 *                                        (�I�����C���p))��ǉ�
 *  2008/12/19    1.0   M.maruyama       �]�ƈ��p�����[�^�擾�֐��̔��ߓ���'/'�O���������폜���A
 *                                       �^�`�F�b�N��ǉ� ���킹��issue_date��150���֕ύX
 *  2008/12/24    1.0   M.maruyama       �w�b�_�C��(Oracle�ł���SCS�ł�)
 *  2009/01/15    1.0   T.maruyama       get_ar_gl_period_from�iAR��v���ԊJ�n���擾�֐��j��ǉ�
 *  2009/01/16    1.0   T.maruyama       chk_exe_report_visite_sales
 *                                       �i�K�┄��v��Ǘ��\�o�͔���֐��j��ǉ�
 *                                       get_working_days�i�c�Ɠ����擾�֐��j��ǉ�
 *  2009/02/02    1.0   K.Boku           chk_responsibility�V�K�쐬
 *  2009/02/23    1.0   T.Mori           chk_exe_report_visite_sales�i�K�┄��v��Ǘ��\�o�͔���֐��j��
 *                                       ���b�Z�[�W��ǉ�
 *  2009/04/16    1.1   K.Satomura       conv_multi_byte�V�K�쐬(T1_0172�Ή�)
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897�Ή�
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_y                CONSTANT VARCHAR2(1)   := 'Y';
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_util_common_pkg';   -- �p�b�P�[�W��
--
   /**********************************************************************************
   * Function Name    : get_base_name
   * Description      : ���_���擾�֐�
   ***********************************************************************************/
  FUNCTION get_base_name(
    iv_base_code             IN  VARCHAR2,               -- ���_�R�[�h
    id_standard_date         IN  DATE                    -- ���
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_base_name';
    cv_set_of_books_id           CONSTANT VARCHAR2(16)    := 'GL_SET_OF_BKS_ID';
    cn_gl_application_id         CONSTANT NUMBER          := 101;
    cv_flex_code                 CONSTANT VARCHAR2(3)     := 'GL#';
    cv_column_name               CONSTANT VARCHAR2(8)     := 'SEGMENT2';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_base_name                 fnd_flex_values_tl.description%TYPE;
    ld_standard_date             DATE;
--
  BEGIN
--
    IF ( id_standard_date IS NULL ) THEN
--
      ld_standard_date := SYSDATE;
--
    ELSE
--
      ld_standard_date := id_standard_date;
--
    END IF;
--
    -- ���_���擾
    BEGIN
--
      SELECT   ffv.attribute4
      INTO     lv_base_name
      FROM     gl_sets_of_books        gsob
              ,fnd_id_flex_segments    fifs
              ,fnd_flex_values         ffv
      WHERE    ffv.flex_value                 = iv_base_code
        AND    gsob.set_of_books_id           = fnd_profile.value(cv_set_of_books_id)
        AND    fifs.application_id            = cn_gl_application_id
        AND    fifs.id_flex_code              = cv_flex_code
        AND    fifs.application_column_name   = cv_column_name
        AND    fifs.id_flex_num               = gsob.chart_of_accounts_id
        AND    ffv.flex_value_set_id          = fifs.flex_value_set_id
        AND    ffv.enabled_flag               = 'Y'
        AND    NVL(ffv.start_date_active, TRUNC(ld_standard_date)) <= TRUNC(ld_standard_date)
        AND    NVL(ffv.end_date_active,   TRUNC(ld_standard_date)) >= TRUNC(ld_standard_date)
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_base_name := NULL;
    END;
--
    RETURN lv_base_name;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_base_name;
--
   /**********************************************************************************
   * Function Name    : get_parent_base_code
   * Description      : �e���_�R�[�h�擾�֐�
   ***********************************************************************************/
  FUNCTION get_parent_base_code(
    iv_base_code             IN  VARCHAR2,               -- ���_�R�[�h
    id_standard_date         IN  DATE                    -- ���
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_parent_base_code';
    cv_set_of_books_id           CONSTANT VARCHAR2(16)    := 'GL_SET_OF_BKS_ID';
    cn_gl_application_id         CONSTANT NUMBER          := 101;
    cv_flex_code                 CONSTANT VARCHAR2(3)     := 'GL#';
    cv_column_name               CONSTANT VARCHAR2(8)     := 'SEGMENT2';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_parent_base_code          fnd_flex_value_norm_hierarchy.parent_flex_value%TYPE;
    ld_standard_date             DATE;
--
  BEGIN
--
    IF ( id_standard_date IS NULL ) THEN
--
      ld_standard_date := SYSDATE;
--
    ELSE
--
      ld_standard_date := id_standard_date;
--
    END IF;
--
    -- ���_���擾
    BEGIN
--
      SELECT   ffv.flex_value
      INTO     lv_parent_base_code
      FROM     gl_sets_of_books               gsob
              ,fnd_id_flex_segments           fifs
              ,fnd_flex_value_norm_hierarchy  ffvnh
              ,fnd_flex_values                ffv
      WHERE    ffvnh.child_flex_value_low     = iv_base_code
        AND    gsob.set_of_books_id           = fnd_profile.value(cv_set_of_books_id)
        AND    fifs.application_id            = cn_gl_application_id
        AND    fifs.id_flex_code              = cv_flex_code
        AND    fifs.application_column_name   = cv_column_name
        AND    fifs.id_flex_num               = gsob.chart_of_accounts_id
        AND    ffvnh.flex_value_set_id        = fifs.flex_value_set_id
        AND    ffv.flex_value                 = ffvnh.parent_flex_value
        AND    ffv.enabled_flag               = 'Y'
        AND    NVL(ffv.start_date_active, TRUNC(ld_standard_date)) <= TRUNC(ld_standard_date)
        AND    NVL(ffv.end_date_active,   TRUNC(ld_standard_date)) >= TRUNC(ld_standard_date)
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_parent_base_code := NULL;
    END;
--
    RETURN lv_parent_base_code;
    --
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_parent_base_code;
--
   /**********************************************************************************
   * Function Name    : get_emp_parameter
   * Description      : �]�ƈ��p�����[�^�擾�֐�
   ***********************************************************************************/
  FUNCTION get_emp_parameter(
    iv_parameter_new         IN  VARCHAR2,               -- �p�����[�^(�V)
    iv_parameter_old         IN  VARCHAR2,               -- �p�����[�^(��)
    iv_issue_date            IN  VARCHAR2,               -- ���ߓ�
    id_standard_date         IN  DATE                    -- ���
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_emp_parameter';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_parameter                 VARCHAR2(150);
    lv_issue_date                VARCHAR2(150);
    ld_issue_date                DATE;

--
  BEGIN
--
    
    lv_issue_date := iv_issue_date;  -- ������
    
    
    -- �^�`�F�b�N
    
    BEGIN
      SELECT TO_DATE(lv_issue_date, 'YYYYMMDD')
      INTO   ld_issue_date
      FROM   DUAL;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END;
  

--
    IF ( trunc(ld_issue_date) <= TRUNC(id_standard_date) ) THEN
--
     lv_parameter := iv_parameter_new;
--
    ELSE
--
     lv_parameter := iv_parameter_old;
--
    END IF;
--
    RETURN lv_parameter;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_emp_parameter;
--
   /**********************************************************************************
   * Function Name    : get_lookup_meaning(TYPE�̂�)
   * Description      : �N�C�b�N�R�[�h���e�擾�֐�
   ***********************************************************************************/
  FUNCTION get_lookup_meaning(
    iv_lookup_type           IN  VARCHAR2,               -- �^�C�v
    iv_lookup_code           IN  VARCHAR2,               -- �R�[�h
    id_standard_date         IN  DATE                    -- ���
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lookup_meaning';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_meaning             fnd_lookup_values_vl.meaning%TYPE;
    lv_description         fnd_lookup_values_vl.description%TYPE;
    lv_attribute1          fnd_lookup_values_vl.attribute1%TYPE;
    lv_attribute2          fnd_lookup_values_vl.attribute2%TYPE;
    lv_attribute3          fnd_lookup_values_vl.attribute3%TYPE;
    lv_attribute4          fnd_lookup_values_vl.attribute4%TYPE;
    lv_attribute5          fnd_lookup_values_vl.attribute5%TYPE;
    lv_attribute6          fnd_lookup_values_vl.attribute6%TYPE;
    lv_attribute7          fnd_lookup_values_vl.attribute7%TYPE;
    lv_attribute8          fnd_lookup_values_vl.attribute8%TYPE;
    lv_attribute9          fnd_lookup_values_vl.attribute9%TYPE;
    lv_attribute10         fnd_lookup_values_vl.attribute10%TYPE;
    lv_attribute11         fnd_lookup_values_vl.attribute11%TYPE;
    lv_attribute12         fnd_lookup_values_vl.attribute12%TYPE;
    lv_attribute13         fnd_lookup_values_vl.attribute13%TYPE;
    lv_attribute14         fnd_lookup_values_vl.attribute14%TYPE;
    lv_attribute15         fnd_lookup_values_vl.attribute15%TYPE;
    lv_retcode             VARCHAR2(1);
    lv_errbuf              VARCHAR2(4000);
    lv_errmsg              VARCHAR2(4000);
--
  BEGIN
--
    -- �N�C�b�N�R�[�h�擾
    xxcso_util_common_pkg.get_lookup_info(
      iv_lookup_type              => iv_lookup_type
     ,iv_lookup_code              => iv_lookup_code
     ,id_standard_date            => id_standard_date
     ,ov_meaning                  => lv_meaning
     ,ov_description              => lv_description
     ,ov_attribute1               => lv_attribute1
     ,ov_attribute2               => lv_attribute2
     ,ov_attribute3               => lv_attribute3
     ,ov_attribute4               => lv_attribute4
     ,ov_attribute5               => lv_attribute5
     ,ov_attribute6               => lv_attribute6
     ,ov_attribute7               => lv_attribute7
     ,ov_attribute8               => lv_attribute8
     ,ov_attribute9               => lv_attribute9
     ,ov_attribute10              => lv_attribute10
     ,ov_attribute11              => lv_attribute11
     ,ov_attribute12              => lv_attribute12
     ,ov_attribute13              => lv_attribute13
     ,ov_attribute14              => lv_attribute14
     ,ov_attribute15              => lv_attribute15
     ,ov_errbuf                   => lv_errbuf
     ,ov_retcode                  => lv_retcode
     ,ov_errmsg                   => lv_errmsg
    );
--
    RETURN lv_meaning;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_lookup_meaning;
--
   /**********************************************************************************
   * Function Name    : get_lookup_description(TYPE�̂�)
   * Description      : �N�C�b�N�R�[�h�E�v�擾�֐�
   ***********************************************************************************/
  FUNCTION get_lookup_description(
    iv_lookup_type           IN  VARCHAR2,               -- �^�C�v
    iv_lookup_code           IN  VARCHAR2,               -- �R�[�h
    id_standard_date         IN  DATE                    -- ���
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lookup_description';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_meaning             fnd_lookup_values_vl.meaning%TYPE;
    lv_description         fnd_lookup_values_vl.description%TYPE;
    lv_attribute1          fnd_lookup_values_vl.attribute1%TYPE;
    lv_attribute2          fnd_lookup_values_vl.attribute2%TYPE;
    lv_attribute3          fnd_lookup_values_vl.attribute3%TYPE;
    lv_attribute4          fnd_lookup_values_vl.attribute4%TYPE;
    lv_attribute5          fnd_lookup_values_vl.attribute5%TYPE;
    lv_attribute6          fnd_lookup_values_vl.attribute6%TYPE;
    lv_attribute7          fnd_lookup_values_vl.attribute7%TYPE;
    lv_attribute8          fnd_lookup_values_vl.attribute8%TYPE;
    lv_attribute9          fnd_lookup_values_vl.attribute9%TYPE;
    lv_attribute10         fnd_lookup_values_vl.attribute10%TYPE;
    lv_attribute11         fnd_lookup_values_vl.attribute11%TYPE;
    lv_attribute12         fnd_lookup_values_vl.attribute12%TYPE;
    lv_attribute13         fnd_lookup_values_vl.attribute13%TYPE;
    lv_attribute14         fnd_lookup_values_vl.attribute14%TYPE;
    lv_attribute15         fnd_lookup_values_vl.attribute15%TYPE;
    lv_retcode             VARCHAR2(1);
    lv_errbuf              VARCHAR2(4000);
    lv_errmsg              VARCHAR2(4000);
--
  BEGIN
--
    -- �N�C�b�N�R�[�h�擾
    xxcso_util_common_pkg.get_lookup_info(
      iv_lookup_type              => iv_lookup_type
     ,iv_lookup_code              => iv_lookup_code
     ,id_standard_date            => id_standard_date
     ,ov_meaning                  => lv_meaning
     ,ov_description              => lv_description
     ,ov_attribute1               => lv_attribute1
     ,ov_attribute2               => lv_attribute2
     ,ov_attribute3               => lv_attribute3
     ,ov_attribute4               => lv_attribute4
     ,ov_attribute5               => lv_attribute5
     ,ov_attribute6               => lv_attribute6
     ,ov_attribute7               => lv_attribute7
     ,ov_attribute8               => lv_attribute8
     ,ov_attribute9               => lv_attribute9
     ,ov_attribute10              => lv_attribute10
     ,ov_attribute11              => lv_attribute11
     ,ov_attribute12              => lv_attribute12
     ,ov_attribute13              => lv_attribute13
     ,ov_attribute14              => lv_attribute14
     ,ov_attribute15              => lv_attribute15
     ,ov_errbuf                   => lv_errbuf
     ,ov_retcode                  => lv_retcode
     ,ov_errmsg                   => lv_errmsg
    );
--
    RETURN lv_description;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_lookup_description;
--
   /**********************************************************************************
   * Function Name    : get_lookup_attribute(TYPE�̂�)
   * Description      : �N�C�b�N�R�[�hDFF�l�擾�֐�
   ***********************************************************************************/
  FUNCTION get_lookup_attribute(
    iv_lookup_type           IN  VARCHAR2,               -- �^�C�v
    iv_lookup_code           IN  VARCHAR2,               -- �R�[�h
    in_dff_number            IN  NUMBER,                 -- DFF�ԍ�
    id_standard_date         IN  DATE                    -- ���
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lookup_attribute';
    cn_dff1                      CONSTANT NUMBER          := 1;
    cn_dff2                      CONSTANT NUMBER          := 2;
    cn_dff3                      CONSTANT NUMBER          := 3;
    cn_dff4                      CONSTANT NUMBER          := 4;
    cn_dff5                      CONSTANT NUMBER          := 5;
    cn_dff6                      CONSTANT NUMBER          := 6;
    cn_dff7                      CONSTANT NUMBER          := 7;
    cn_dff8                      CONSTANT NUMBER          := 8;
    cn_dff9                      CONSTANT NUMBER          := 9;
    cn_dff10                     CONSTANT NUMBER          := 10;
    cn_dff11                     CONSTANT NUMBER          := 11;
    cn_dff12                     CONSTANT NUMBER          := 12;
    cn_dff13                     CONSTANT NUMBER          := 13;
    cn_dff14                     CONSTANT NUMBER          := 14;
    cn_dff15                     CONSTANT NUMBER          := 15;
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_meaning             fnd_lookup_values_vl.meaning%TYPE;
    lv_description         fnd_lookup_values_vl.description%TYPE;
    lv_attribute1          fnd_lookup_values_vl.attribute1%TYPE;
    lv_attribute2          fnd_lookup_values_vl.attribute2%TYPE;
    lv_attribute3          fnd_lookup_values_vl.attribute3%TYPE;
    lv_attribute4          fnd_lookup_values_vl.attribute4%TYPE;
    lv_attribute5          fnd_lookup_values_vl.attribute5%TYPE;
    lv_attribute6          fnd_lookup_values_vl.attribute6%TYPE;
    lv_attribute7          fnd_lookup_values_vl.attribute7%TYPE;
    lv_attribute8          fnd_lookup_values_vl.attribute8%TYPE;
    lv_attribute9          fnd_lookup_values_vl.attribute9%TYPE;
    lv_attribute10         fnd_lookup_values_vl.attribute10%TYPE;
    lv_attribute11         fnd_lookup_values_vl.attribute11%TYPE;
    lv_attribute12         fnd_lookup_values_vl.attribute12%TYPE;
    lv_attribute13         fnd_lookup_values_vl.attribute13%TYPE;
    lv_attribute14         fnd_lookup_values_vl.attribute14%TYPE;
    lv_attribute15         fnd_lookup_values_vl.attribute15%TYPE;
    lv_return_value        VARCHAR2(150);
    lv_retcode             VARCHAR2(1);
    lv_errbuf              VARCHAR2(4000);
    lv_errmsg              VARCHAR2(4000);
--
  BEGIN
--
    -- �N�C�b�N�R�[�h�擾
    xxcso_util_common_pkg.get_lookup_info(
      iv_lookup_type              => iv_lookup_type
     ,iv_lookup_code              => iv_lookup_code
     ,id_standard_date            => id_standard_date
     ,ov_meaning                  => lv_meaning
     ,ov_description              => lv_description
     ,ov_attribute1               => lv_attribute1
     ,ov_attribute2               => lv_attribute2
     ,ov_attribute3               => lv_attribute3
     ,ov_attribute4               => lv_attribute4
     ,ov_attribute5               => lv_attribute5
     ,ov_attribute6               => lv_attribute6
     ,ov_attribute7               => lv_attribute7
     ,ov_attribute8               => lv_attribute8
     ,ov_attribute9               => lv_attribute9
     ,ov_attribute10              => lv_attribute10
     ,ov_attribute11              => lv_attribute11
     ,ov_attribute12              => lv_attribute12
     ,ov_attribute13              => lv_attribute13
     ,ov_attribute14              => lv_attribute14
     ,ov_attribute15              => lv_attribute15
     ,ov_errbuf                   => lv_errbuf
     ,ov_retcode                  => lv_retcode
     ,ov_errmsg                   => lv_errmsg
    );
--
    IF ( in_dff_number = cn_dff1 ) THEN
--
     lv_return_value := lv_attribute1;
--
    ELSIF ( in_dff_number = cn_dff2 ) THEN
--
     lv_return_value := lv_attribute2;
--
    ELSIF ( in_dff_number = cn_dff3 ) THEN
--
     lv_return_value := lv_attribute3;
--
    ELSIF ( in_dff_number = cn_dff4 ) THEN
--
     lv_return_value := lv_attribute4;
--
    ELSIF ( in_dff_number = cn_dff5 ) THEN
--
     lv_return_value := lv_attribute5;
--
    ELSIF ( in_dff_number = cn_dff6 ) THEN
--
     lv_return_value := lv_attribute6;
--
    ELSIF ( in_dff_number = cn_dff7 ) THEN
--
     lv_return_value := lv_attribute7;
--
    ELSIF ( in_dff_number = cn_dff8 ) THEN
--
     lv_return_value := lv_attribute8;
--
    ELSIF ( in_dff_number = cn_dff9 ) THEN
--
     lv_return_value := lv_attribute9;
--
    ELSIF ( in_dff_number = cn_dff10 ) THEN
--
     lv_return_value := lv_attribute10;
--
    ELSIF ( in_dff_number = cn_dff11 ) THEN
--
     lv_return_value := lv_attribute11;
--
    ELSIF ( in_dff_number = cn_dff12 ) THEN
--
     lv_return_value := lv_attribute12;
--
    ELSIF ( in_dff_number = cn_dff13 ) THEN
--
     lv_return_value := lv_attribute13;
--
    ELSIF ( in_dff_number = cn_dff14 ) THEN
--
     lv_return_value := lv_attribute14;
--
    ELSIF ( in_dff_number = cn_dff15 ) THEN
--
     lv_return_value := lv_attribute15;
--
    ELSE
--
     lv_return_value := NULL;
--
    END IF;
--
    RETURN lv_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_lookup_attribute;
--
   /**********************************************************************************
   * Function Name    : get_lookup_info(TYPE�̂�)
   * Description      : �N�C�b�N�R�[�h�擾����
   ***********************************************************************************/
  PROCEDURE get_lookup_info(
    iv_lookup_type           IN  VARCHAR2,               -- �^�C�v
    iv_lookup_code           IN  VARCHAR2,               -- �R�[�h
    id_standard_date         IN  DATE,                   -- ���
    ov_meaning               OUT VARCHAR2,               -- ���e
    ov_description           OUT VARCHAR2,               -- �E�v
    ov_attribute1            OUT VARCHAR2,               -- DFF1
    ov_attribute2            OUT VARCHAR2,               -- DFF2
    ov_attribute3            OUT VARCHAR2,               -- DFF3
    ov_attribute4            OUT VARCHAR2,               -- DFF4
    ov_attribute5            OUT VARCHAR2,               -- DFF5
    ov_attribute6            OUT VARCHAR2,               -- DFF6
    ov_attribute7            OUT VARCHAR2,               -- DFF7
    ov_attribute8            OUT VARCHAR2,               -- DFF8
    ov_attribute9            OUT VARCHAR2,               -- DFF9
    ov_attribute10           OUT VARCHAR2,               -- DFF10
    ov_attribute11           OUT VARCHAR2,               -- DFF11
    ov_attribute12           OUT VARCHAR2,               -- DFF12
    ov_attribute13           OUT VARCHAR2,               -- DFF13
    ov_attribute14           OUT VARCHAR2,               -- DFF14
    ov_attribute15           OUT VARCHAR2,               -- DFF15
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- �V�X�e�����b�Z�[�W
    ov_retcode               OUT NOCOPY VARCHAR2,        -- ��������('0':����, '1':�x��, '2':�G���[)
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ���[�U�[���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_lookup_info';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ld_standard_date       DATE;
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- ����`�F�b�N
    IF ( id_standard_date IS NULL ) THEN
--
     ld_standard_date := SYSDATE;
--
    ELSE
--
     ld_standard_date := id_standard_date;
--
    END IF;
--
    -- �N�C�b�N�R�[�h�擾
    SELECT   flvv.meaning
            ,flvv.description
            ,flvv.attribute1
            ,flvv.attribute2
            ,flvv.attribute3
            ,flvv.attribute4
            ,flvv.attribute5
            ,flvv.attribute6
            ,flvv.attribute7
            ,flvv.attribute8
            ,flvv.attribute9
            ,flvv.attribute10
            ,flvv.attribute11
            ,flvv.attribute12
            ,flvv.attribute13
            ,flvv.attribute14
            ,flvv.attribute15
    INTO     ov_meaning
            ,ov_description
            ,ov_attribute1
            ,ov_attribute2
            ,ov_attribute3
            ,ov_attribute4
            ,ov_attribute5
            ,ov_attribute6
            ,ov_attribute7
            ,ov_attribute8
            ,ov_attribute9
            ,ov_attribute10
            ,ov_attribute11
            ,ov_attribute12
            ,ov_attribute13
            ,ov_attribute14
            ,ov_attribute15
    FROM     fnd_lookup_values_vl   flvv
    WHERE    flvv.lookup_type                 = iv_lookup_type
      AND    flvv.lookup_code                 = iv_lookup_code
      AND    flvv.enabled_flag                = 'Y'
      AND    NVL(flvv.start_date_active, TRUNC(ld_standard_date)) <= TRUNC(ld_standard_date)
      AND    NVL(flvv.end_date_active,   TRUNC(ld_standard_date)) >= TRUNC(ld_standard_date)
    ;
--
  EXCEPTION
    -- *** �f�[�^�Ȃ� ***
    WHEN NO_DATA_FOUND THEN
      ov_retcode    := xxcso_common_pkg.gv_status_error;
      ov_errbuf     := xxcso_common_pkg.gv_no_data_error_msg;
      ov_errmsg     := NULL;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_lookup_info;
--
   /**********************************************************************************
   * Function Name    : get_business_year
   * Description      : �N�x�擾�֐�
   ***********************************************************************************/
  FUNCTION get_business_year(
    iv_year_month      IN  VARCHAR2                      -- �N��
  )
  RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_business_year';
    cv_set_of_books_id           CONSTANT VARCHAR2(16)    := 'GL_SET_OF_BKS_ID';
    cv_first_date                CONSTANT VARCHAR2(2)     := '01';
    cv_no                        CONSTANT VARCHAR2(1)     := 'N';
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    ln_business_year             gl_periods.period_year%TYPE;
--
  BEGIN
--
    SELECT glp.period_year
    INTO   ln_business_year
    FROM   gl_periods  glp
          ,gl_sets_of_books  gls
    WHERE  glp.period_set_name = gls.period_set_name
      AND  gls.set_of_books_id = fnd_profile.value(cv_set_of_books_id)
      AND  glp.start_date <= TO_DATE(iv_year_month || cv_first_date, 'yyyymmdd')
      AND  glp.end_date   >= TO_DATE(iv_year_month || cv_first_date, 'yyyymmdd')
      AND  glp.adjustment_period_flag = cv_no
    ;
--
    RETURN ln_business_year;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN  NULL;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_business_year;
--
  /**********************************************************************************
   * Function Name    : check_date
   * Description      : ���t�����`�F�b�N�֐�
   ***********************************************************************************/
  FUNCTION check_date(
    iv_date         IN  VARCHAR2,                     -- ���t���͗��ɓ��͂��ꂽ�l
    iv_date_format  IN  VARCHAR2                      -- ���t�t�H�[�}�b�g�i����������j
  )
  RETURN BOOLEAN
  IS
    -- *** ���[�J���ϐ� ***
    ln_convert_temp    DATE;   -- �ϊ��`�F�b�N�p�ꎞ�̈�
--
  BEGIN
--
    ln_convert_temp := TO_DATE(iv_date, iv_date_format);

    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END check_date;
--
   /**********************************************************************************
   * Function Name    : check_ar_gl_period_status
   * Description      : AR��v���ԃN���[�Y�`�F�b�N
   ***********************************************************************************/
  FUNCTION check_ar_gl_period_status(
    id_standard_date         IN  DATE                    -- �`�F�b�N�Ώۓ�
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'check_ar_gl_period_status';
    cv_set_of_books_id           CONSTANT VARCHAR2(16)    := 'GL_SET_OF_BKS_ID';
    cv_app_short_name            CONSTANT VARCHAR2(2)     := 'AR';
    cv_closing_status_c          CONSTANT VARCHAR2(1)     := 'C';
    cv_adjmt_period_flag         CONSTANT VARCHAR2(1)     := 'N';
    cv_true                      CONSTANT VARCHAR2(4)     := 'TRUE';
    cv_false                     CONSTANT VARCHAR2(5)     := 'FALSE';  
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ld_standard_date             DATE;
    ln_books_id                  NUMBER;
    ln_gl_period_closed_cnt      NUMBER;
--
  BEGIN
--
    IF ( id_standard_date IS NULL ) THEN
--
      RETURN cv_false;
--
    ELSE
--
      ld_standard_date := TRUNC(id_standard_date);
      ln_books_id      := FND_PROFILE.VALUE(cv_set_of_books_id);
--
    END IF;
--
    -- �J�E���g���擾
--
    SELECT COUNT(*) cnt
    INTO   ln_gl_period_closed_cnt
    FROM   gl_period_statuses gps
          ,fnd_application fa
    WHERE  gps.set_of_books_id        = ln_books_id
      AND  fa.application_id          = gps.application_id
      AND  fa.application_short_name  = cv_app_short_name
      AND  gps.adjustment_period_flag = cv_adjmt_period_flag
      AND  gps.closing_status         = cv_closing_status_c
      AND  ld_standard_date BETWEEN gps.start_date AND gps.end_date
    ;
--
    IF ( ln_gl_period_closed_cnt > 0 ) THEN
      RETURN cv_false;
    ELSE
      RETURN cv_true;
    END IF;
--    
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END check_ar_gl_period_status;
--
   /**********************************************************************************
   * Function Name    : get_online_sysdate
   * Description      : �V�X�e�����t�擾�֐��i�I�����C���p�j
   ***********************************************************************************/
  FUNCTION get_online_sysdate
  RETURN DATE
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'check_ar_gl_period_status';
  BEGIN
--
    RETURN xxccp_common_pkg2.get_process_date;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_online_sysdate;
--
   /**********************************************************************************
   * Function Name    : get_ar_gl_period_from
   * Description      : AR��v���ԊJ�n���擾�֐�
   ***********************************************************************************/
  FUNCTION get_ar_gl_period_from
  RETURN DATE
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_ar_gl_period_from';
    cv_set_of_books_id           CONSTANT VARCHAR2(16)    := 'GL_SET_OF_BKS_ID';
    cv_app_short_name            CONSTANT VARCHAR2(2)     := 'AR';
    cv_closing_status_open       CONSTANT VARCHAR2(1)     := 'O';
    cv_adjmt_period_flag         CONSTANT VARCHAR2(1)     := 'N';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ld_start_date                DATE;
--
  BEGIN
--
    BEGIN
      --�I�[�v�����̉�v���Ԃ̈�ԌÂ��J�n�����擾
      SELECT min(gps.start_date) start_date  -- �J�n��
      INTO   ld_start_date
      FROM   gl_period_statuses gps          -- ��v���ԃX�e�[�^�X
            ,fnd_application fa
      WHERE  gps.set_of_books_id        = FND_PROFILE.VALUE(cv_set_of_books_id)
        AND  fa.application_id          = gps.application_id
        AND  fa.application_short_name  = cv_app_short_name
        AND  gps.adjustment_period_flag = cv_adjmt_period_flag
        AND  gps.closing_status         = cv_closing_status_open;
--  
    EXCEPTION
      WHEN OTHERS THEN
        ld_start_date := NULL;
    END;
--
    RETURN ld_start_date;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_ar_gl_period_from;
--
   /**********************************************************************************
   * Function Name    : chk_exe_report_visite_sales
   * Description      : �K�┄��v��Ǘ��\�o�͔���֐�
   ***********************************************************************************/
  PROCEDURE chk_exe_report_visite_sales(
    in_user_id               IN  NUMBER                  -- ���O�C�����[�U�h�c
   ,in_resp_id               IN  NUMBER                  -- ���O�C���ҐE�ӂh�c
   ,iv_base_code             IN  VARCHAR2                -- ���_�R�[�h�i�Q�Ɛ�j
   ,iv_report_type           IN  VARCHAR2                -- ���[���
   ,ov_ret_code              OUT VARCHAR2                -- ���茋�ʁi'TRUE�f�^�fFALSE�f�j
   ,ov_err_msg               OUT VARCHAR2                -- �G���[���R
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_exe_report_visite_sales';
    cv_true                      CONSTANT VARCHAR2(10)    := 'TRUE';
    cv_false                     CONSTANT VARCHAR2(10)    := 'FALSE';
    cv_auto_loolup_type          CONSTANT VARCHAR2(100)   := 'XXCSO1_VST_SLS_REP_AUTH_CTRL';
    cv_process_date              CONSTANT DATE := xxcso_util_common_pkg.get_online_sysdate;
    cv_c_null                    CONSTANT VARCHAR2(100)   := 'XXXXXXXXXX'; --null�̑�֒l
    cv_any_char                  CONSTANT VARCHAR2(100)   := '*';
    --���[�^�C�v
    cv_rep_eigyouin              CONSTANT VARCHAR2(1)     := '1'; -- �c�ƈ���
    cv_rep_group                 CONSTANT VARCHAR2(1)     := '2'; -- �c�ƈ��O���[�v��
    cv_rep_kyoten                CONSTANT VARCHAR2(1)     := '3'; -- ���_�^�ە�
    cv_rep_chiku                 CONSTANT VARCHAR2(1)     := '4'; -- �n��c�ƕ��^����
    cv_rep_honbu                 CONSTANT VARCHAR2(1)     := '5'; -- �n��c�Ɩ{��
    --�A�v���P�[�V�����Z�k��
    cv_app_name                  CONSTANT VARCHAR2(100)   := 'XXCSO';
    --���b�Z�[�W
    cv_msg_number_01             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00535';
        -- ���擾�G���[���b�Z�[�W
    cv_msg_number_02             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00536';
        -- �K�┄��v��Ǘ��\�o�͌������擾�G���[���b�Z�[�W
    cv_msg_number_03             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00537';
        -- �K�┄��v��Ǘ��\�o�͌������NULL�G���[���b�Z�[�W
    cv_msg_number_04             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00538';
        -- �o�͌����`�F�b�N�G���[���b�Z�[�W�i���O�C���ҁj
    cv_msg_number_05             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00539';
        -- �o�͌����`�F�b�N�G���[���b�Z�[�W
    cv_msg_number_06             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00540';
        -- �`�e�e����K�w���擾�G���[���b�Z�[�W
    cv_msg_number_07             CONSTANT VARCHAR2(100)   := 'APP-XXCSO1-00382';
        -- �p�����[�^���̓`�F�b�N�G���[���b�Z�[�W
    --�g�[�N����
    cv_tkn_info             CONSTANT VARCHAR2(100)   := 'INFO';  -- 
    cv_tkn_item             CONSTANT VARCHAR2(100)   := 'ITEM';  -- 
    cv_tkn_resp_name        CONSTANT VARCHAR2(100)   := 'RESP_NAME';  -- 
    cv_tkn_posit_cd         CONSTANT VARCHAR2(100)   := 'POSIT_CD';  -- 
    cv_tkn_job_type_cd      CONSTANT VARCHAR2(100)   := 'JOB_TYPE_CD';  -- 
    cv_tkn_base_code        CONSTANT VARCHAR2(100)   := 'BASE_CODE';  -- 
    cv_tkn_err_msg          CONSTANT VARCHAR2(100)   := 'ERR_MSG';  -- 
    --
    cv_tkn_msg_job_type     CONSTANT VARCHAR2(100)   := '�E�ӏ��';  -- 
    cv_tkn_msg_job_nm       CONSTANT VARCHAR2(100)   := '�E�Ӗ�';  -- 
    cv_tkn_msg_resorce_vw   CONSTANT VARCHAR2(100)   := '���\�[�X�}�X�^�i�ŐV�j�r���[';  -- 
    cv_tkn_msg_emp_info     CONSTANT VARCHAR2(100)   := '�]�ƈ����';  -- 
    cv_tkn_msg_report_type  CONSTANT VARCHAR2(100)   := '���[���';  -- 
    cv_tkn_msg_base         CONSTANT VARCHAR2(100)   := '���_';  -- 
    cv_tkn_msg_errmsg1      CONSTANT VARCHAR2(100)   := '�i�K�w���x���͈͊O�j';  -- 
    cv_tkn_msg_errmsg2      CONSTANT VARCHAR2(100)   := '�i�񒼊��͈́j';  -- 
    cv_tkn_msg_base2        CONSTANT VARCHAR2(100)   := '�w�肵�����_';  -- 
    cv_tkn_msg_base3        CONSTANT VARCHAR2(100)   := '���O�C���҂̋��_';  -- 
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lt_resp_key       fnd_responsibility_vl.responsibility_key%type; -- �E�Ӗ�
    lt_resp_name      fnd_responsibility_vl.responsibility_name%type; -- �E�Ӗ�
    lt_position_code  xxcso_resources_v2.position_code_new%type; -- �E�ʃR�[�h
    lt_job_type_code  xxcso_resources_v2.job_type_code_new%type; -- �E��R�[�h
    lt_work_base_code xxcso_resources_v2.work_base_code_new%type; -- �Ζ��n���_�R�[�h
    lv_max_rep_kind   VARCHAR2(1); -- �o�͉\���[���
    lv_max_base_lavel VARCHAR2(1); -- �o�͉\����K�w���x��
    lt_my_parent_base_cd    xxcso_aff_base_level_v2.base_code%type; 
                                    --���O�C�����[�U�[���_�̊K�w��ʋ��_���
    lt_param_parent_base_cd xxcso_aff_base_level_v2.base_code%type;
                                    --�p�����[�^���_�̊K�w��ʋ��_���
    
    
  BEGIN
--
    ------------------------------------------------------
    --�p�����[�^���̓`�F�b�N
    ------------------------------------------------------
    --IN�p�����[�^�F���[��ʓ��̓`�F�b�N
    IF (iv_report_type IS NULL) THEN
      ov_ret_code := cv_false;
      ov_err_msg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_number_07
                       ,iv_token_name1  => cv_tkn_item
                       ,iv_token_value1 => cv_tkn_msg_report_type
                      );
      RETURN;
    END IF;
--
    ------------------------------------------------------
    --���O�C���Ҋ�{���擾
    ------------------------------------------------------
    --���O�C���E�Ӗ��̎擾
    BEGIN
      SELECT  frv.responsibility_key  responsibility_key  --�E�ӃL�[
      ,       frv.responsibility_name responsibility_name --�E�Ӗ�
      INTO    lt_resp_key
      ,       lt_resp_name
      FROM    fnd_responsibility_vl frv 
      WHERE   frv.responsibility_id = in_resp_id; --�E�ӂh�c
    EXCEPTION
      WHEN OTHERS THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_01
                         ,iv_token_name1  => cv_tkn_info
                         ,iv_token_value1 => cv_tkn_msg_job_type
                         ,iv_token_name2  => cv_tkn_item
                         ,iv_token_value2 => cv_tkn_msg_job_nm
                        );
        RETURN;
    END;
--
    --���O�C�����[�U�[���擾
    BEGIN
      SELECT  CASE 
              WHEN xrv2.issue_date <= TO_CHAR(cv_process_date, 'YYYYMMDD') THEN
                xrv2.position_code_new
              ELSE
                xrv2.position_code_old
              END position_code        -- �E�ʂb�c
      ,       CASE 
              WHEN xrv2.issue_date <= TO_CHAR(cv_process_date, 'YYYYMMDD') THEN
                xrv2.job_type_code_new
              ELSE
                xrv2.job_type_code_old
              END job_type_code        -- �E��b�c
      ,       CASE 
              WHEN xrv2.issue_date <= TO_CHAR(cv_process_date, 'YYYYMMDD') THEN
                xrv2.work_base_code_new
              ELSE
                xrv2.work_base_code_old
              END work_base_code       -- ���_�b�c
      INTO    lt_position_code
      ,       lt_job_type_code
      ,       lt_work_base_code
      FROM    xxcso_resources_v2 xrv2    -- ���\�[�X�}�X�^�i�ŐV�j�r���[
      WHERE   xrv2.user_id = in_user_id; -- ���[�U�[�h�c
    EXCEPTION
      WHEN OTHERS THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_01
                         ,iv_token_name1  => cv_tkn_info
                         ,iv_token_value1 => cv_tkn_msg_resorce_vw
                         ,iv_token_name2  => cv_tkn_item
                         ,iv_token_value2 => cv_tkn_msg_emp_info
                        );
        RETURN;
    END;
--
    ------------------------------------------------------
    --�Q�ƃ^�C�v����K�┄��v��Ǘ��\�o�͌��������擾
    ------------------------------------------------------
    --�ȉ��̏����ɂđΏƂ̌��������擾����--------------
    --attribute3=���O�C���҂̐E�ӃL�[
    --attribute4=���O�C���҂̐E�ʂb�c
    --attribute5=���O�C���҂̐E��b�c
    ------------------------------------------------------
    --attribute4,attribute5�̏����ɂ���
    --�P�D'*'���ݒ肳��Ă���ꍇ�A�����𖳎��i���C���h�J�[�h�j
    --�Q�D���ݒ�inull�j�̏ꍇ�́A���O�C���҂̂b�c��null�ɂĈ�v
    ------------------------------------------------------
    BEGIN 
      SELECT flv.attribute1 max_rep_kind   -- �o�͉\���[���
      ,      flv.attribute2 max_base_lavel -- �o�͉\����K�w���x��
      into   lv_max_rep_kind
      ,      lv_max_base_lavel
      FROM   fnd_lookup_values_vl flv      -- �Q�ƃ^�C�v
      WHERE  flv.lookup_type  = cv_auto_loolup_type
      AND    flv.enabled_flag = 'Y'
      AND    TRUNC(cv_process_date) 
             BETWEEN TRUNC(nvl(flv.start_date_active, cv_process_date)) 
                 AND TRUNC(nvl(flv.end_date_active, cv_process_date))
      AND    flv.attribute3   = lt_resp_key                          -- �E�ӃL�[
      AND    DECODE(flv.attribute4, NULL, cv_c_null
                                  , cv_any_char, nvl(lt_position_code,cv_c_null)
                                  , flv.attribute4) 
                                             = nvl(lt_position_code,cv_c_null)  --�E�ʂb�c
      AND    DECODE(flv.attribute5, NULL, cv_c_null
                                  , cv_any_char, nvl(lt_job_type_code,cv_c_null)
                                  , flv.attribute5)
                                             = nvl(lt_job_type_code,cv_c_null)  --�E��b�c
      ;    
    EXCEPTION
      WHEN OTHERS THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_02
                         ,iv_token_name1  => cv_tkn_resp_name
                         ,iv_token_value1 => lt_resp_key  -- �E�ӃL�[
                         ,iv_token_name2  => cv_tkn_posit_cd
                         ,iv_token_value2 => lt_position_code  --�E�ʂb�c
                         ,iv_token_name3  => cv_tkn_job_type_cd
                         ,iv_token_value3 => lt_job_type_code  --�E��b�c
                        );
        RETURN;
    END;    
--
    IF ( lv_max_rep_kind IS NULL ) OR ( lv_max_base_lavel IS NULL ) THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_03
                        );
        RETURN;    
    END IF;
--
    ------------------------------------------------------
    --�����`�F�b�N�F���[���
    ------------------------------------------------------
    --�o�͉\���[��ʂ��傫���ꍇ�G���[
    IF ( iv_report_type > lv_max_rep_kind ) THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_05
                         ,iv_token_name1  => cv_tkn_item
                         ,iv_token_value1 => cv_tkn_msg_report_type
                         ,iv_token_name2  => cv_tkn_err_msg
                         ,iv_token_value2 => NULL
                        );
        RETURN;
    END IF;
--
    ------------------------------------------------------
    --�����`�F�b�N�F�w�苒�_�K�w���x��
    ------------------------------------------------------
    --���ȉ��A����_���i���O�C���҂̋��_����уp�����[�^�̋��_�j
    --�P�D�p�����[�^���_����n��̏o�͉\����K�w���x���ɂ�����
    --    ���_�b�c���擾�B
    --�Q�D"�P"���擾�ł��Ȃ��i�o�͉\���x���͈͊O�j��������
    --    ���O�C���҂̓���K�w���_�b�c�ƕs��v�i���Ǌ��n�����قȂ�j
    --    �̏ꍇ�A�G���[�B
    ------------------------------------------------------
    --�P�D�p�����[�^���_����n��̏o�͉\����K�w���x���ɂ����鋒�_�b�c�擾
    BEGIN
      SELECT v.base_code
      INTO   lt_param_parent_base_cd
      FROM   (
               --����_�����ʋ��_���ċA�ōŏ�ʂ܂Ŏ擾
               --�i����_�͎q�Ƃ��ăX�^�[�g���邽�ߐe�ɂ͏o�Ă��Ȃ��j
               SELECT  ROWNUM kaisou_level --�K�w���x��
               ,       up_base.base_code   --���_�b�c
               FROM   (
                       SELECT level           sqllev
                       ,      xabl1.base_code base_code
                       FROM   xxcso_aff_base_level_v2 xabl1 --AFF����K�w�r���[�i�ŐV�j
                       START WITH xabl1.child_base_code = iv_base_code  --����_
                       CONNECT BY PRIOR xabl1.base_code = xabl1.child_base_code
                       ORDER BY level DESC
                      ) up_base
               UNION
               --����_���ŉ��w�Ƃ���UNION�i����_�͎q�Ƃ��ăX�^�[�g���邽�߁j
               SELECT (
                       SELECT NVL(MAX(xabl3.sqllev), 0) + 1  max_level
                       FROM  (
                              --����_�����ʋ��_���ċA�Ŏ擾
                              SELECT level           sqllev
                              ,      xabl2.base_code base_code
                              FROM   xxcso_aff_base_level_v2 xabl2 --AFF����K�w�r���[�i�ŐV�j
                              START WITH xabl2.child_base_code = iv_base_code  --����_
                              CONNECT BY PRIOR xabl2.base_code = xabl2.child_base_code
                              ORDER BY level DESC
                             ) xabl3
                      ) kaisou_level
                     ,iv_base_code  base_code  --����_
               FROM DUAL
              ) v
        WHERE v.kaisou_level = TO_NUMBER(lv_max_base_lavel); --�K�w���x��
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_05
                         ,iv_token_name1  => cv_tkn_item
                         ,iv_token_value1 => cv_tkn_msg_base
                         ,iv_token_name2  => cv_tkn_err_msg
                         ,iv_token_value2 => cv_tkn_msg_errmsg1
                        );
        RETURN;      
      WHEN OTHERS THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_06
                         ,iv_token_name1  => cv_tkn_base_code
                         ,iv_token_value1 => cv_tkn_msg_base2
                        );
        RETURN;    
    END;
--
    --�Q�D���O�C���҂̋��_����n��̏o�͉\����K�w���x���ɂ����鋒�_�b�c�擾
    BEGIN
      SELECT v.base_code
      INTO   lt_my_parent_base_cd
      FROM   (
               --����_�����ʋ��_���ċA�ōŏ�ʂ܂Ŏ擾
               --�i����_�͎q�Ƃ��ăX�^�[�g���邽�ߐe�ɂ͏o�Ă��Ȃ��j
               SELECT  ROWNUM kaisou_level --�K�w���x��
               ,       up_base.base_code   --���_�b�c
               FROM   (
                       SELECT level           sqllev
                       ,      xabl1.base_code base_code
                       FROM   xxcso_aff_base_level_v2 xabl1 --AFF����K�w�r���[�i�ŐV�j
                       START WITH xabl1.child_base_code = lt_work_base_code  --����_
                       CONNECT BY PRIOR xabl1.base_code = xabl1.child_base_code
                       ORDER BY level DESC
                      ) up_base
               UNION
               --����_���ŉ��w�Ƃ���UNION�i����_�͎q�Ƃ��ăX�^�[�g���邽�߁j
               SELECT (
                       SELECT NVL(MAX(xabl3.sqllev), 0) + 1  max_level
                       FROM  (
                              --����_�����ʋ��_���ċA�Ŏ擾
                              SELECT level           sqllev
                              ,      xabl2.base_code base_code
                              FROM   xxcso_aff_base_level_v2 xabl2 --AFF����K�w�r���[�i�ŐV�j
                              START WITH xabl2.child_base_code = lt_work_base_code --	
                              CONNECT BY PRIOR xabl2.base_code = xabl2.child_base_code
                              ORDER BY level DESC
                             ) xabl3
                      ) kaisou_level
                     ,lt_work_base_code  base_code  --����_
               FROM DUAL
              ) v
        WHERE v.kaisou_level = TO_NUMBER(lv_max_base_lavel); --�K�w���x��
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_04
                        );
        RETURN;      
      WHEN OTHERS THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_06
                         ,iv_token_name1  => cv_tkn_base_code
                         ,iv_token_value1 => cv_tkn_msg_base3
                        );
        RETURN;    
    END;
--
    --�Q�D���O�C���ҋ��_�Ǝw�苒�_�̓���K�w���x�����_�b�c���r
    IF ( lt_param_parent_base_cd <> lt_my_parent_base_cd ) THEN
        ov_ret_code := cv_false;
        ov_err_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_number_05
                         ,iv_token_name1  => cv_tkn_item
                         ,iv_token_value1 => cv_tkn_msg_base
                         ,iv_token_name2  => cv_tkn_err_msg
                         ,iv_token_value2 => cv_tkn_msg_errmsg2
                        );
        RETURN;     
    END IF;
--
    ov_ret_code := cv_true;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_exe_report_visite_sales;
--
   /**********************************************************************************
   * Function Name    : get_working_days
   * Description      : �c�Ɠ����擾�֐�
   ***********************************************************************************/
  FUNCTION get_working_days(
    id_from_date             IN  DATE                    -- ��_���t
   ,id_to_date               IN  DATE                    -- �I�_���t
  )
  RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_working_days';
    cv_profile_name              CONSTANT VARCHAR2(100)   := 'XXCCP1_WORKING_CALENDAR';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    --**���[�J���ϐ�**
    ln_working_days      NUMBER;
  BEGIN
    --�J�����_����ғ������J�E���g
    SELECT count(*) cnt
    INTO   ln_working_days
    FROM   bom_calendar_dates bcd
    WHERE  bcd.calendar_code = FND_PROFILE.VALUE(cv_profile_name)
    AND    bcd.seq_num IS NOT NULL
    AND    bcd.calendar_date BETWEEN TRUNC(id_from_date) AND TRUNC(id_to_date)
    ;
--    
    RETURN ln_working_days;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_working_days;
--
   /**********************************************************************************
   * Function Name    : chk_responsibility
   * Description      : ���O�C���ҐE�Ӕ���֐�
   *                    �K�┄��v��Ǘ��\�o�͌����̎Q�ƃ^�C�v�𗘗p���A
   *                    ���O�C�����[�U�h�c�A�E�ӂh�c���A
   *                    �c�ƈ��܂��́A�c�ƈ��O���[�v�������肷��B
   ***********************************************************************************/
  FUNCTION chk_responsibility(
    in_user_id               IN  NUMBER                  -- ���O�C�����[�U�h�c
   ,in_resp_id               IN  NUMBER                  -- �E�ʂh�c
   ,iv_report_type           IN  VARCHAR2                -- ���[�^�C�v�i1:�c�ƈ��ʁA2:�c�ƈ��O���[�v�ʁA���̑��͎w��s�j
  ) RETURN VARCHAR2                                      -- 'TRUE':�`�F�b�N�n�j 'FALSE':�`�F�b�N�m�f
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'chk_responsibility';
    cv_auto_loolup_type          CONSTANT VARCHAR2(100)   := 'XXCSO1_VST_SLS_REP_AUTH_CTRL';
    cv_process_date              CONSTANT DATE := xxcso_util_common_pkg.get_online_sysdate;
    cv_c_null                    CONSTANT VARCHAR2(100)   := 'XXXXXXXXXX'; --null�̑�֒l
    cv_any_char                  CONSTANT VARCHAR2(100)   := '*';
    cv_true                      CONSTANT VARCHAR2(4)     := 'TRUE';
    cv_false                     CONSTANT VARCHAR2(5)     := 'FALSE';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lt_resp_key       fnd_responsibility_vl.responsibility_name%type; -- �E�ӃL�[
    lt_position_code  xxcso_resources_v2.position_code_new%type; -- �E�ʃR�[�h
    lt_job_type_code  xxcso_resources_v2.job_type_code_new%type; -- �E��R�[�h
    lv_max_rep_kind   VARCHAR2(1); -- �o�͉\���[���
--
--
  BEGIN
--
    ------------------------------------------------------
    --���O�C���Ҋ�{���擾
    ------------------------------------------------------
    --���O�C���E�Ӗ��̎擾
    SELECT  frv.responsibility_key  responsibility_key --�E�ӃL�[
      INTO  lt_resp_key
      FROM  fnd_responsibility_vl frv 
     WHERE  frv.responsibility_id = in_resp_id; --�E�ӂh�c
--
    --���O�C�����[�U�[���擾
    SELECT  CASE
              WHEN xrv2.issue_date <= TO_CHAR(cv_process_date, 'YYYYMMDD') THEN
                xrv2.position_code_new
              ELSE
                xrv2.position_code_old
            END position_code        -- �E�ʂb�c
           ,CASE
              WHEN xrv2.issue_date <= TO_CHAR(cv_process_date, 'YYYYMMDD') THEN
                xrv2.job_type_code_new
              ELSE
                xrv2.job_type_code_old
            END job_type_code        -- �E��b�c
      INTO  lt_position_code
           ,lt_job_type_code
      FROM  xxcso_resources_v2 xrv2    -- ���\�[�X�}�X�^�i�ŐV�j�r���[
     WHERE  xrv2.user_id = in_user_id; -- ���[�U�[�h�c
--
    ------------------------------------------------------
    --�Q�ƃ^�C�v����K�┄��v��Ǘ��\�o�͌��������擾
    ------------------------------------------------------
    --�ȉ��̏����ɂđΏƂ̌��������擾����--------------
    --attribute3=���O�C���҂̐E�Ӗ�
    --attribute4=���O�C���҂̐E�ʂb�c
    --attribute5=���O�C���҂̐E��b�c
    ------------------------------------------------------
    --attribute4,attribute5�̏����ɂ���
    --�P�D'*'���ݒ肳��Ă���ꍇ�A�����𖳎��i���C���h�J�[�h�j
    --�Q�D���ݒ�inull�j�̏ꍇ�́A���O�C���҂̂b�c��null�ɂĈ�v
    ------------------------------------------------------
    SELECT flv.attribute1 max_rep_kind   -- �o�͉\���[���
    into   lv_max_rep_kind
    FROM   fnd_lookup_values_vl flv      -- �Q�ƃ^�C�v
    WHERE  flv.lookup_type  = cv_auto_loolup_type
    AND    flv.enabled_flag = 'Y'
    AND    TRUNC(cv_process_date) 
           BETWEEN TRUNC(nvl(flv.start_date_active, cv_process_date)) 
               AND TRUNC(nvl(flv.end_date_active, cv_process_date))
    AND    flv.attribute3   = lt_resp_key                          -- �E�ӃL�[
    AND    DECODE(flv.attribute4, NULL, cv_c_null, cv_any_char, nvl(lt_position_code,cv_c_null), flv.attribute4) 
                                           = nvl(lt_position_code,cv_c_null)  --�E�ʂb�c
    AND    DECODE(flv.attribute5, NULL, cv_c_null, cv_any_char, nvl(lt_job_type_code,cv_c_null), flv.attribute5)
                                           = nvl(lt_job_type_code,cv_c_null)  --�E��b�c
    AND    ROWNUM = 1
    ;
--
    IF ( lv_max_rep_kind IS NULL ) THEN
        RETURN cv_false;
    END IF;
--
    ------------------------------------------------------
    --�����`�F�b�N�F���[���
    ------------------------------------------------------
    IF ( iv_report_type <> lv_max_rep_kind ) THEN
        RETURN cv_false;
    END IF;
--
    RETURN cv_true;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** NO_DATA_FOUND�n���h�� ***
    WHEN NO_DATA_FOUND THEN
      RETURN cv_false;

    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END chk_responsibility;
--
  /* 2009.04.16 K.Satomura T1_0172�Ή� START */
  /**********************************************************************************
   * Function Name    : conv_multi_byte
   * Description      :���p�����S�p�u���֐�
   ***********************************************************************************/
  FUNCTION conv_multi_byte(
    iv_char IN VARCHAR2 -- ������
  ) RETURN VARCHAR2 IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'conv_multi_byte';
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_char   VARCHAR2(5000);
    lv_return VARCHAR2(5000);
    --
  BEGIN
    --
    lv_char   := iv_char;
    lv_return := NULL;
    --
    IF (lv_char IS NULL) THEN
      RETURN NULL;
      --
    END IF;
    --
    -- ���_�E�����t�������̒u��
    IF (INSTRB(lv_char, '�') > 0
      OR INSTRB(lv_char, '�') > 0)
    THEN
      lv_char := REPLACE(lv_char, '��', '�K');
      lv_char := REPLACE(lv_char, '��', '�M');
      lv_char := REPLACE(lv_char, '��', '�O');
      lv_char := REPLACE(lv_char, '��', '�Q');
      lv_char := REPLACE(lv_char, '��', '�S');
      lv_char := REPLACE(lv_char, '��', '�U');
      lv_char := REPLACE(lv_char, '��', '�W');
      lv_char := REPLACE(lv_char, '��', '�Y');
      lv_char := REPLACE(lv_char, '��', '�[');
      lv_char := REPLACE(lv_char, '��', '�]');
      lv_char := REPLACE(lv_char, '��', '�_');
      lv_char := REPLACE(lv_char, '��', '�a');
      lv_char := REPLACE(lv_char, '��', '�d');
      lv_char := REPLACE(lv_char, '��', '�f');
      lv_char := REPLACE(lv_char, '��', '�h');
      lv_char := REPLACE(lv_char, '��', '�o');
      lv_char := REPLACE(lv_char, '��', '�r');
      lv_char := REPLACE(lv_char, '��', '�u');
      lv_char := REPLACE(lv_char, '��', '�x');
      lv_char := REPLACE(lv_char, '��', '�{');
      lv_char := REPLACE(lv_char, '��', '�p');
      lv_char := REPLACE(lv_char, '��', '�s');
      lv_char := REPLACE(lv_char, '��', '�v');
      lv_char := REPLACE(lv_char, '��', '�y');
      lv_char := REPLACE(lv_char, '��', '�|');
      --
    END IF;
    --
    -- ���p�J�i�����E���p�p�����̒u��
    lv_char := TRANSLATE(lv_char
               ,'�������������������������������������������ܦݧ���������' ||
                'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 '
               ,'�A�C�E�G�I�J�L�N�P�R�T�V�X�Z�\�^�`�c�e�g�i�j�k�l�m�n�q�t�w�z�}�~�����������������������������@�B�D�F�H�������b�[' ||
                '�`�a�b�c�d�e�f�g�h�i�j�k�l�m�n�o�p�q�r�s�t�u�v�w�x�y����������������������������������������������������' ||
                '�O�P�Q�R�S�T�U�V�W�X�@');
               --
    -- ���̑��̔��p�����̒u��
    FOR i IN 1..LENGTH(lv_char) LOOP
      IF (LENGTHB(SUBSTR(lv_char, i, 1)) = 1) THEN
        -- �P�������P�o�C�g�̏ꍇ
        lv_return := lv_return || '��';
        --
      ELSE
        lv_return := lv_return || SUBSTR(lv_char, i, 1);
        --
      END IF;
      --
    END LOOP;
    --
    RETURN lv_return;
    --
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END conv_multi_byte;

  /* 2009.04.16 K.Satomura T1_0172�Ή� END */
END xxcso_util_common_pkg;
/
