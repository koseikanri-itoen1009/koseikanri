CREATE OR REPLACE PACKAGE BODY xxcso_ib_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_IB_COMMON_PKG(BODY)
 * Description      : ���ʊ֐��iXXCSOIB���ʁj
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 * ----------------------  ----  ----  ------------------------------------------------------
 *  Name                   Type  Ret   Description
 * ----------------------  ----  ----  ------------------------------------------------------
 *  get_ib_ext_attribs     F     V     �����}�X�^�ǉ������l�擾�֐�
 *  get_ib_ext_attribs2    F     V     �����}�X�^�ǉ������l�擾�֐��Q
 *  get_ib_ext_attribs_id  F     V     �����}�X�^�ǉ�����ID�擾�֐�
 *  get_ib_ext_attrib_info2 F    R     �����}�X�^�ǉ������l���擾�֐��Q
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   N.Yabuki         �V�K�쐬
 *  2009/01/16    1.1   N.Yabuki         �����}�X�^�ǉ������l���擾�֐��Q��ǉ�
 *  2009/01/29    1.2   kyo              �����}�X�^�ǉ������l���擾�֐��Q�̏C��
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_ib_common_pkg';   -- �p�b�P�[�W��
--
  /**********************************************************************************
   * Function Name    : get_ib_ext_attribs
   * Description      : �����}�X�^�ǉ������l�擾�֐�
   ***********************************************************************************/
  FUNCTION get_ib_ext_attribs(
    in_instance_id       IN  NUMBER,   -- �C���X�^���XID
    iv_attribute_code    IN  VARCHAR2  -- ������`
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100)  := 'get_ib_ext_attribs';
    cv_attribute_level        CONSTANT VARCHAR2(30)   := 'XXCSO1_IB_ATTRIBUTE_LEVEL';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_attribute_level        VARCHAR2(15);
    ld_date                   DATE;
    lv_attribute_value        VARCHAR2(240);
--
  BEGIN
--
    -- �V�X�e�����t�擾�i�����b�͐؂�̂āj
    ld_date := TRUNC(SYSDATE);
--
    -- �v���t�@�C���擾�iXXCSO:IB�g�������e���v���[�g�A�N�Z�X���x���j
    lv_attribute_level := FND_PROFILE.VALUE( cv_attribute_level );
--
    IF lv_attribute_level IS NULL THEN
      RETURN NULL;
    END IF;
--
    -- �����l�擾
    BEGIN
--
      SELECT
          civ.attribute_value  attribute_value
      INTO
          lv_attribute_value
      FROM
          csi_i_extended_attribs  ciea  -- �ݒu�@��g��������`���e�[�u��
        , csi_iea_values          civ   -- �ݒu�@��g�������l���e�[�u��
      WHERE
          ciea.attribute_level = lv_attribute_level
      AND ciea.attribute_code  = iv_attribute_code
      AND civ.instance_id      = in_instance_id
      AND ciea.attribute_id    = civ.attribute_id
      AND NVL( ciea.active_start_date, ld_date ) <= ld_date
      AND NVL( ciea.active_end_date, ld_date )   >= ld_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;
--
    RETURN lv_attribute_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt( gv_pkg_name, cv_prg_name );
--
--#####################################  �Œ蕔 END   ##########################################
  END get_ib_ext_attribs;
--
  /**********************************************************************************
   * Function Name    : get_ib_ext_attribs2
   * Description      : �����}�X�^�ǉ������l�擾�֐��Q
   ***********************************************************************************/
  FUNCTION get_ib_ext_attribs2(
    in_instance_id       IN  NUMBER,   -- �C���X�^���XID
    iv_attribute_code    IN  VARCHAR2  -- ������`
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100)  := 'get_ib_ext_attribs2';
    cv_attribute_level        CONSTANT VARCHAR2(30)   := 'XXCSO1_IB_ATTRIBUTE_LEVEL';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_attribute_level        VARCHAR2(15);
    ld_date                   DATE;
    lv_attribute_value        VARCHAR2(240);
--
  BEGIN
--
    -- �Ɩ��������t�擾�i�����b�͐؂�̂āj
    ld_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ld_date IS NULL THEN
      RETURN NULL;
    END IF;
--
    -- �v���t�@�C���擾�iXXCSO:IB�g�������e���v���[�g�A�N�Z�X���x���j
    lv_attribute_level := FND_PROFILE.VALUE( cv_attribute_level );
--
    IF lv_attribute_level IS NULL THEN
      RETURN NULL;
    END IF;
--
    -- �����l�擾
    BEGIN
--
      SELECT
          civ.attribute_value  attribute_value
      INTO
          lv_attribute_value
      FROM
          csi_i_extended_attribs  ciea  -- �ݒu�@��g��������`���e�[�u��
        , csi_iea_values          civ   -- �ݒu�@��g�������l���e�[�u��
      WHERE
          ciea.attribute_level = lv_attribute_level
      AND ciea.attribute_code  = iv_attribute_code
      AND civ.instance_id      = in_instance_id
      AND ciea.attribute_id    = civ.attribute_id
      AND NVL( ciea.active_start_date, ld_date ) <= ld_date
      AND NVL( ciea.active_end_date, ld_date )   >= ld_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;
--
    RETURN lv_attribute_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt( gv_pkg_name, cv_prg_name );
--
--#####################################  �Œ蕔 END   ##########################################
  END get_ib_ext_attribs2;
--
  /**********************************************************************************
   * Function Name    : get_ib_ext_attribs_id
   * Description      : �����}�X�^�ǉ�����ID�擾�֐�
   ***********************************************************************************/
  FUNCTION get_ib_ext_attribs_id(
    iv_attribute_code    IN  VARCHAR2,  -- �����R�[�h
    id_standard_date     IN  DATE       -- ���
  )
  RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100)  := 'get_ib_ext_attribs_id';
    cv_attribute_level        CONSTANT VARCHAR2(30)   := 'XXCSO1_IB_ATTRIBUTE_LEVEL';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_attribute_id           NUMBER;
    ld_standard_date          DATE;
    lv_attribute_level        VARCHAR2(15);
--
  BEGIN
--
    -- ����擾�i�����b�͐؂�̂āj
    ld_standard_date := TRUNC( id_standard_date );
--
    IF ld_standard_date IS NULL THEN
      RETURN NULL;
    END IF;
--
    -- �v���t�@�C���擾�iXXCSO:IB�g�������e���v���[�g�A�N�Z�X���x���j
    lv_attribute_level := FND_PROFILE.VALUE( cv_attribute_level );
--
    IF lv_attribute_level IS NULL THEN
      RETURN NULL;
    END IF;
--
    BEGIN
      SELECT
          ciea.attribute_id  attribute_id
      INTO
          ln_attribute_id
      FROM
          csi_i_extended_attribs  ciea  -- �ݒu�@��g��������`���e�[�u��
      WHERE
          ciea.attribute_level = lv_attribute_level
      AND ciea.attribute_code  = iv_attribute_code
      AND NVL( ciea.active_start_date, ld_standard_date ) <= ld_standard_date
      AND NVL( ciea.active_end_date, ld_standard_date )   >= ld_standard_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;
--
    RETURN ln_attribute_id;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt( gv_pkg_name, cv_prg_name );
--
--#####################################  �Œ蕔 END   ##########################################
  END get_ib_ext_attribs_id;
--
  /**********************************************************************************
   * Function Name    : get_ib_ext_attrib_info2
   * Description      : �����}�X�^�ǉ������l�擾�֐��Q
   ***********************************************************************************/
  FUNCTION get_ib_ext_attrib_info2(
    in_instance_id       IN  NUMBER,   -- �C���X�^���XID
    iv_attribute_code    IN  VARCHAR2  -- ������`
  )
  RETURN CSI_IEA_VALUES%ROWTYPE
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100)  := 'get_ib_ext_attrib_info2';
    cv_attribute_level        CONSTANT VARCHAR2(30)   := 'XXCSO1_IB_ATTRIBUTE_LEVEL';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_attribute_level        VARCHAR2(15);
    ld_date                   DATE;
    l_ext_attrib_rec          csi_iea_values%ROWTYPE;
--
  BEGIN
--
    -- �Ɩ��������t�擾�i�����b�͐؂�̂āj
    ld_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ld_date IS NULL THEN
      RETURN NULL;
    END IF;
--
    -- �v���t�@�C���擾�iXXCSO:IB�g�������e���v���[�g�A�N�Z�X���x���j
    lv_attribute_level := FND_PROFILE.VALUE( cv_attribute_level );
--
    IF lv_attribute_level IS NULL THEN
      RETURN NULL;
    END IF;
--
    -- �����l���擾
    BEGIN
--
      SELECT civ.attribute_value_id     attribute_value_id
           , civ.attribute_value        attribute_value
           , civ.object_version_number  object_version_number
           , civ.attribute_id           attribute_id
      INTO   l_ext_attrib_rec.attribute_value_id
           , l_ext_attrib_rec.attribute_value
           , l_ext_attrib_rec.object_version_number
           , l_ext_attrib_rec.attribute_id
      FROM   csi_i_extended_attribs  ciea  -- �ݒu�@��g��������`���e�[�u��
           , csi_iea_values          civ   -- �ݒu�@��g�������l���e�[�u��
      WHERE  ciea.attribute_level = lv_attribute_level
      AND    ciea.attribute_code  = iv_attribute_code
      AND    civ.instance_id      = in_instance_id
      AND    ciea.attribute_id    = civ.attribute_id
      AND    NVL( ciea.active_start_date, ld_date ) <= ld_date
      AND    NVL( ciea.active_end_date, ld_date )   >= ld_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;
--
    RETURN l_ext_attrib_rec;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt( gv_pkg_name, cv_prg_name );
--
--#####################################  �Œ蕔 END   ##########################################
  END get_ib_ext_attrib_info2;
--
END xxcso_ib_common_pkg;
/
