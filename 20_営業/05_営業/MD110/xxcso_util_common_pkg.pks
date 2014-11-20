CREATE OR REPLACE PACKAGE APPS.xxcso_util_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_UTIL_COMMON_PKG(SPEC)
 * Description      : ���ʊ֐�(XXCSO���[�e�B���e�B�j
 * MD.050/070       :
 * Version          : 1.3
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
 *  conv_ng_char_vdms         F    -     ���̋@�Ǘ�S�֑������ϊ��֐�
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/07    1.0   H.Ogawa          �V�K�쐬
 *  2008/11/11    1.0   K.Hosoi          get_business_year(�N�x�擾�֐�)��ǋL
 *  2008/11/26    1.0   K.Hosoi          get_emp_parameter�Fid_issue_date�̌^��
 *                                       DATE����VARCHAR2�֏C��
 *  2008/12/04    1.0   K.Cho            check_date(���t�����`�F�b�N�֐�)��ǋL
 *  2008/12/08    1.0   T.Kyo            check_ar_gl_period_status:AR��v���ԃN���[�Y�`�F�b�N
 *  2008/12/16    1.0   H.Ogawa          LOOKUP_TYPE�݂̂ŃN�C�b�N�R�[�h���擾����֐���ǉ�
 *  2008/12/16    1.0   H.Ogawa          get_online_sysdate(�V�X�e�����t�擾�֐�
 *                                        (�I�����C���p))��ǉ�
 *  2008/12/24    1.0   M.maruyama       �w�b�_�C��(Oracle�ł���SCS�ł�)
 *  2009/01/15    1.0   T.mori           get_ar_gl_period_from�iAR��v���ԊJ�n���擾�֐��j��ǉ�
 *  2009/01/16    1.0   T.mori           chk_exe_report_visite_sales
 *                                       �i�K�┄��v��Ǘ��\�o�͔���֐��j��ǉ�
 *                                       get_working_days�i�c�Ɠ����擾�֐��j��ǉ�
 *  2009/02/02    1.0   K.Boku           chk_responsibility�V�K�쐬
 *  2009/04/16    1.1   K.Satomura       conv_multi_byte�V�K�쐬(T1_0172�Ή�)
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897�Ή�
 *  2009/05/12    1.3   K.Satomura       get_rs_base_code
 *                                       get_current_rs_base_code �V�K�쐬(T1_0593�Ή�)
 *  2009/12/14    1.4   T.Maruyama       E_�{�ғ�_00469�Ή� conv_ng_char_vdms�V�K�쐬
 *****************************************************************************************/
--
  /**********************************************************************************
   * Function Name    : get_base_name
   * Description      : ���_���擾�֐�
   ***********************************************************************************/
  FUNCTION get_base_name(
    iv_base_code             IN  VARCHAR2,               -- ���_�R�[�h
    id_standard_date         IN  DATE                    -- ���
  )
  RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_parent_base_code
   * Description      : �e���_�R�[�h�擾�֐�
   ***********************************************************************************/
  FUNCTION get_parent_base_code(
    iv_base_code             IN  VARCHAR2,               -- ���_�R�[�h
    id_standard_date         IN  DATE                    -- ���
  )
  RETURN VARCHAR2;
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
  RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_lookup_meaning
   * Description      : �N�C�b�N�R�[�h���e�擾�֐�(TYPE�̂�)
   ***********************************************************************************/
  FUNCTION get_lookup_meaning(
    iv_lookup_type           IN  VARCHAR2,               -- �^�C�v
    iv_lookup_code           IN  VARCHAR2,               -- �R�[�h
    id_standard_date         IN  DATE                    -- ���
  )
  RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_lookup_description
   * Description      : �N�C�b�N�R�[�h�E�v�擾�֐�(TYPE�̂�)
   ***********************************************************************************/
  FUNCTION get_lookup_description(
    iv_lookup_type           IN  VARCHAR2,               -- �^�C�v
    iv_lookup_code           IN  VARCHAR2,               -- �R�[�h
    id_standard_date         IN  DATE                    -- ���
  )
  RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_lookup_attribute
   * Description      : �N�C�b�N�R�[�hDFF�l�擾�֐�(TYPE�̂�)
   ***********************************************************************************/
  FUNCTION get_lookup_attribute(
    iv_lookup_type           IN  VARCHAR2,               -- �^�C�v
    iv_lookup_code           IN  VARCHAR2,               -- �R�[�h
    in_dff_number            IN  NUMBER,                 -- DFF�ԍ�
    id_standard_date         IN  DATE                    -- ���
  )
  RETURN VARCHAR2;
--
  /**********************************************************************************
   * Procedure Name    : get_lookup_info
   * Description      :�N�C�b�N�R�[�h�擾����(TYPE�̂�)
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
  );
--
   /**********************************************************************************
   * Function Name    : get_business_year
   * Description      :�N�x�擾�֐�
   ***********************************************************************************/
  FUNCTION get_business_year(
    iv_year_month    IN  VARCHAR2                        -- �N��
  )
  RETURN NUMBER;
--
   /**********************************************************************************
   * Function Name    : check_date
   * Description      :���t�����`�F�b�N�֐�
   ***********************************************************************************/
  FUNCTION check_date(
    iv_date         IN  VARCHAR2,                     -- ���t���͗��ɓ��͂��ꂽ�l
    iv_date_format  IN  VARCHAR2                      -- ���t�t�H�[�}�b�g�i����������j
  )
  RETURN BOOLEAN;
--
   /**********************************************************************************
   * Function Name    : check_ar_gl_period_status
   * Description      :AR��v���ԃN���[�Y�`�F�b�N
   ***********************************************************************************/
  FUNCTION check_ar_gl_period_status(
    id_standard_date         IN  DATE                    -- �`�F�b�N�Ώۓ�
  )
  RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_online_sysdate
   * Description      :�V�X�e�����t�擾�֐��i�I�����C���p�j
   ***********************************************************************************/
  FUNCTION get_online_sysdate RETURN DATE;
--
  /**********************************************************************************
   * Function Name    : get_online_sysdate
   * Description      :AR��v���ԊJ�n���擾�֐�
   ***********************************************************************************/
  FUNCTION get_ar_gl_period_from RETURN DATE;
--
  /**********************************************************************************
   * Procedure Name    : chk_exe_report_visite_sales
   * Description      :�K�┄��v��Ǘ��\�o�͔���֐�
   ***********************************************************************************/
  PROCEDURE chk_exe_report_visite_sales(
    in_user_id               IN  NUMBER                  -- ���O�C�����[�U�h�c
   ,in_resp_id               IN  NUMBER                  -- ���O�C���ҐE�ӂh�c
   ,iv_base_code             IN  VARCHAR2                -- ���_�R�[�h�i�Q�Ɛ�j
   ,iv_report_type           IN  VARCHAR2                -- ���[���
   ,ov_ret_code              OUT VARCHAR2                -- ���茋�ʁi'TRUE�f�^�fFALSE�f�j
   ,ov_err_msg               OUT VARCHAR2                -- �G���[���R
  );
--
  /**********************************************************************************
   * Function Name    : get_working_days
   * Description      :�c�Ɠ����擾�֐�
   ***********************************************************************************/
  FUNCTION get_working_days(
    id_from_date             IN  DATE                    -- ��_���t
   ,id_to_date               IN  DATE                    -- �I�_���t
  )
   RETURN NUMBER;
--
  -- ���O�C���ҐE�Ӕ���֐�
  FUNCTION chk_responsibility(
    in_user_id               IN  NUMBER                  -- ���O�C�����[�U�h�c
   ,in_resp_id               IN  NUMBER                  -- �E�ʂh�c
   ,iv_report_type           IN  VARCHAR2                -- ���[�^�C�v�i1:�c�ƈ��ʁA2:�c�ƈ��O���[�v�ʁA���̑��͎w��s�j
  ) RETURN VARCHAR2;                                     -- 'TRUE':�`�F�b�N�n�j 'FALSE':�`�F�b�N�m�f
--
  /* 2009.04.16 K.Satomura T1_0172�Ή� START */
  /**********************************************************************************
   * Function Name    : conv_multi_byte
   * Description      : ���p�����S�p�u���֐�
   ***********************************************************************************/
  FUNCTION conv_multi_byte(
    iv_char IN VARCHAR2 -- ������
  ) RETURN VARCHAR2;
  /* 2009.04.16 K.Satomura T1_0172�Ή� END */
--
  /* 2009.05.12 K.Satomura T1_0593�Ή� START */
  /**********************************************************************************
   * Function Name    : get_rs_base_code
   * Description      : �������_�擾�i���\�[�XID�A����w��j
   ***********************************************************************************/
  FUNCTION  get_rs_base_code(
    in_resource_id   IN NUMBER
   ,id_standard_date IN DATE
  ) RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_current_rs_base_code
   * Description      : ���������_�擾�i���O�C�����[�U�[�j
   ***********************************************************************************/
  FUNCTION  get_current_rs_base_code
  RETURN VARCHAR2;
  /* 2009.05.12 K.Satomura T1_0593�Ή� END */
--
  /* 2009.12.14 T.Maruyama E_�{�ғ�_00469 START */
  /**********************************************************************************
   * Function Name    : conv_ng_char_vdms
   * Description      : ���̋@�Ǘ�S�֑������ϊ��֐�
   ***********************************************************************************/
  FUNCTION conv_ng_char_vdms(
    iv_char IN VARCHAR2 -- ������
  ) RETURN VARCHAR2;
  /* 2009.12.14 T.Maruyama E_�{�ғ�_00469 END */
--
END xxcso_util_common_pkg;
--
/
