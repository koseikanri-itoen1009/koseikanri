CREATE OR REPLACE PACKAGE BODY xxwsh_common910_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh_common910_pkg(BODY)
 * Description            : ���ʊ֐�(BODY)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.15
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  comp_round_up          F         �����_�؂�グ�֐�
 *  calc_total_value       P         B.�ύڌ����`�F�b�N(���v�l�Z�o)
 *  calc_load_efficiency   P         C.�ύڌ����`�F�b�N(�ύڌ����Z�o)
 *  check_lot_reversal     P         D.���b�g�t�]�h�~�`�F�b�N
 *  check_fresh_condition  P         E.�N�x�����`�F�b�N
 *  calc_lead_time         P         F.���[�h�^�C���Z�o
 *  check_shipping_judgment
 *                         P         G.�o�׉ۃ`�F�b�N
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/03/13   1.0   ORACLE�Γn���a   �V�K�쐬
 *  2008/05/19   1.1   ORACLE�Γn���a   ���b�Z�[�W�C��
 *  2008/05/23   1.2   ORACLE�k�������v �N�x�����`�F�b�N��OTHERS��O�����R�[�h��
 *                                      global_api_others_expt�ɕύX
 *                                      �N�x�����`�F�b�N�̓��̓p�����[�^�����b�gNo����
 *                                      ���b�gID�ɕύX
 *  2008/05/24   1.3   ORACLE�k�������v �N�x�����`�F�b�N�̑N�x�����敪�̃G���[�`�F�b�N��
 *                                      NULL�̏ꍇ��ǉ��B
 *                                      �N�x�����敪����ʂ̏ꍇ�A�ܖ��������Z�b�g�����
 *                                      ���Ȃ��ꍇ�A�G���[�Ƃ���悤�ɏC��
 *  2008/05/28   1.4   ORACLE�Γn���a   [���b�g�t�]�h�~�`�F�b�N]
 *                                      �ړ����b�g�ڍׂ̃��R�[�h�^�C�v�l���C��
 *  2008/05/30   1.5   ORACLE�Ŗ����\   �����ύX�v��#116�Ή�
 *  2008/06/02   1.6   ORACLE�Γn���a   [�o�׉ۃ`�F�b�N] �t�H�[�L���X�g�̒��o�����ύX
 *                                      [�ύڌ����`�F�b�N(�ύڌ����Z�o)]���o��������
 *  2008/06/13   1.7   ORACLE�Γn���a   [���b�g�t�]�h�~�`�F�b�N] �ړ��w���̒���������ύX
 *  2008/06/19   1.8   ORACLE�R����_   [�o�׉ۃ`�F�b�N] �����ύX�v��No143�Ή�
 *  2008/06/26   1.9   ORACLE�Γn���a   [�o�׉ۃ`�F�b�N] �ړ��w���̒���������ύX
 *  2008/07/08   1.10  ORACLE�Ŗ����\   [�o�׉ۃ`�F�b�N] ST�s�#405�Ή�
 *  2008/07/14   1.11  ORACLE���c����   [�ύڌ����`�F�b�N(�ύڌ����Z�o)] �ύX�v���Ή�#95
 *  2008/07/17   1.12  ORACLE���c����   [�ύڌ����`�F�b�N(�ύڌ����Z�o)] �ύX�v���Ή�#95�̃o�O�Ή�
 *  2008/07/30   1.13  ORACLE���R�m��   [�o�׉ۃ`�F�b�N]�����ύX�v��#182�Ή�
 *  2008/08/04   1.14  ORACLE�ɓ��ЂƂ� [�ύڌ����`�F�b�N(�ύڌ����Z�o)] �ύX�v���Ή�#95�̃o�O�Ή�
 *  2008/08/06   1.14  ORACLE�ɓ��ЂƂ� [�ύڌ����`�F�b�N(�ύڌ����Z�o)] �ύX�v���Ή�#164�Ή�
 *  2008/08/22   1.15  ORACLE�ɓ��ЂƂ� [�o�׉ۃ`�F�b�N] PT 2-2_15 �w�E20
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
--  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_status_error  CONSTANT VARCHAR2(1) := '1';
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh_common910_pkg'; -- �p�b�P�[�W��
  --
  gv_cnst_xxwsh    CONSTANT VARCHAR2(5)   := 'XXWSH';
  --
  gv_yyyymmdd      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /************************************************************************
   * Procedure Name  : comp_round_up
   * Description     : �����_�؂�グ�֐�
   ************************************************************************/
  FUNCTION comp_round_up(
    pn_number1  IN NUMBER  -- �Ώۂ̐��l
   ,pn_number2  IN NUMBER  -- �؏��̏�����
  ) RETURN  NUMBER         -- �؏��̐��l
  IS
  BEGIN
--
    RETURN TRUNC(pn_number1 + (0.9 / POWER(10, pn_number2)), pn_number2);
--
  END comp_round_up;
--
  /**********************************************************************************
   * Procedure Name   : calc_total_value
   * Description      : �ύڌ����`�F�b�N(���v�l�Z�o)
   ***********************************************************************************/
  PROCEDURE calc_total_value(
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,   -- 1.�i�ڃR�[�h
    in_quantity                   IN  NUMBER,                          -- 2.����
    ov_retcode                    OUT NOCOPY VARCHAR2,                 -- 3.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                 -- 4.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                 -- 5.�G���[���b�Z�[�W
    on_sum_weight                 OUT NOCOPY NUMBER,                   -- 6.���v�d��
    on_sum_capacity               OUT NOCOPY NUMBER,                   -- 7.���v�e��
    on_sum_pallet_weight          OUT NOCOPY NUMBER                    -- 8.���v�p���b�g�d��
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_total_value';        --�v���O������
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�WID
    cv_xxwsh_no_data_found_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12551'; -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
    cv_xxwsh_palette_steps_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12552'; -- �p���b�g����ő�i���l�[���G���[���b�Z�[�W
    cv_xxwsh_get_prof_err      CONSTANT VARCHAR2(100) := 'APP-XXWSH-12553'; -- �v���t�@�C���擾�G���[���b�Z�[�W
    cv_xxwsh_get_deliv_qty_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12554'; -- �z���l�[���G���[���b�Z�[�W
    cv_xxwsh_indispensable_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12555'; -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
    cv_xxwsh_num_of_case_err   CONSTANT VARCHAR2(100) := 'APP-XXWSH-12556'; -- �P�[�X�����l�[���G���[���b�Z�[�W
    cv_xxwsh_d_num_of_case_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12557'; -- �h�����N�P�[�X�����l�[���G���[���b�Z�[�W
    -- �g�[�N��
    cv_tkn_item_code      CONSTANT VARCHAR2(100) := 'ITEM_CODE';
    cv_tkn_prof_name      CONSTANT VARCHAR2(100) := 'PROF_NAME';
    cv_tkn_in_parm        CONSTANT VARCHAR2(100) := 'IN_PARM';
    -- �g�[�N���Z�b�g�l
    cv_item_code_char     CONSTANT VARCHAR2(100) := '�i�ڃR�[�h';
    cv_qty_char           CONSTANT VARCHAR2(100) := '����';
    -- �v���t�@�C��
    cv_prof_mast_org_id   CONSTANT VARCHAR2(30)  := 'XXCMN_MASTER_ORG_ID'; -- XXCMN:�}�X�^�g�D
    cv_prof_pallet_waight CONSTANT VARCHAR2(30)  := 'XXWSH_PALLET_WEIGHT'; -- XXWSH:�p���b�g�d��
    -- ���i�敪
    cv_prod_class_drink   CONSTANT VARCHAR2(1)   := '2';                   -- �h�����N
    -- �i�ڋ敪
    cv_item_class_product CONSTANT VARCHAR2(1)   := '5';                   -- ���i
    -- �؂�グ�p�萔
    cn_rounup_const_no    CONSTANT NUMBER        := 0.9;
    -- �ۂߌ���
    cn_roundup_digits     CONSTANT NUMBER        := 0;
    -- �P�ʊ��Z(1) ���@�Z���`���[�g��->�������[�g��
    cn_conv_cm3_to_m3     CONSTANT NUMBER        := 1000000;
    -- �P�ʊ��Z(2) �O����->�L���O����
    cn_conv_g_to_kg       CONSTANT NUMBER        := 1000;
--
    -- *** ���[�J���ϐ� ***
    -- �G���[�ϐ�
    lv_errmsg             VARCHAR2(1000);
    lv_err_cd             VARCHAR2(30);
--
    -- �v���t�@�C���ϐ�
    ln_mst_org_id         mtl_parameters.organization_id%TYPE;            -- �}�X�^�g�DID
    ln_pallet_waight      NUMBER;                                         -- �p���b�g�d��
--
    -- �i�ڃ}�X�^����
    ln_weight             NUMBER;                                         -- �d��
    ln_capacity           NUMBER;                                         -- �e��
    ln_delivery_qty       NUMBER;                                         -- �z��
    ln_max_palette_steps  NUMBER;                                         -- �p���b�g����ő�i��
    ln_num_of_cases       NUMBER;                                         -- �P�[�X����
    lv_conv_unit          xxcmn_item_mst_v.conv_unit%TYPE;                -- ���o�Ɋ��Z�P��
    lv_prod_class_code    xxcmn_item_categories5_v.prod_class_code%TYPE;  -- ���i�敪
    lv_item_class_code    xxcmn_item_categories5_v.item_class_code%TYPE;  -- �i�ڋ敪
--
    ln_pallet_qty         NUMBER DEFAULT 0;                               -- �p���b�g����
    ln_pallet_sum_weight  NUMBER DEFAULT 0;                               -- ���v�p���b�g�d��
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    /*************************************
     *  �v���t�@�C���擾(B-1)            *
     *************************************/
    --
    ln_mst_org_id    := to_number( fnd_profile.valuE( cv_prof_mast_org_id ));   -- �i�ڃ}�X�^�g�DID
    ln_pallet_waight := to_number( fnd_profile.valuE( cv_prof_pallet_waight )); -- �p���b�g�d��
    --
    -- �G���[����
    -- �uXXCMN:�}�X�^�g�D�v�擾���s
    IF ( ln_mst_org_id    IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_get_prof_err,
                                            cv_tkn_prof_name,
                                            cv_prof_mast_org_id);
      lv_err_cd := cv_xxwsh_get_prof_err;
      RAISE global_api_expt;
    --
    -- �uXXWSH:�p���b�g�d�ʁv�擾���s
    ELSIF ( ln_pallet_waight IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_get_prof_err,
                                            cv_tkn_prof_name,
                                            cv_prof_pallet_waight);
      lv_err_cd := cv_xxwsh_get_prof_err;
      RAISE global_api_expt;
    END IF;
--
    /*************************************
     *  �K�{���̓p�����[�^�`�F�b�N(B-2)  *
     *************************************/
    --
    -- �i�ڃR�[�h
    IF ( iv_item_no  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_indispensable_err,
                                            cv_tkn_in_parm,
                                            cv_item_code_char);
      lv_err_cd := cv_xxwsh_indispensable_err;
      RAISE global_api_expt;
    --
    -- ����
    ELSIF ( in_quantity IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_indispensable_err,
                                            cv_tkn_in_parm,
                                            cv_qty_char);
      lv_err_cd := cv_xxwsh_indispensable_err;
      RAISE global_api_expt;
    END IF;
--
    /*************************************
     *  �i�ڃ}�X�^���o(B-3)              *
     *************************************/
    --
    BEGIN
      SELECT  to_number( ximv.unit ),               -- �d��
              to_number( ximv.capacity ),           -- �e��
              to_number( ximv.delivery_qty ),       -- �z��
              to_number( ximv.max_palette_steps ),  -- �p���b�g����ő�i��
              to_number( ximv.num_of_cases ),       -- �P�[�X����
              ximv.conv_unit,                       -- ���o�Ɋ��Z�P��
              xicv.prod_class_code,                 -- ���i�敪
              xicv.item_class_code                  -- �i�ڋ敪
      INTO    ln_weight,
              ln_capacity,
              ln_delivery_qty,
              ln_max_palette_steps,
              ln_num_of_cases,
              lv_conv_unit,
              lv_prod_class_code,
              lv_item_class_code
      FROM    xxcmn_item_mst2_v         ximv,      -- OPM�i�ڏ��VIEW2
              xxcmn_item_categories5_v  xicv       -- OPM�i�ڃJ�e�S���������VIEW5
      WHERE   ximv.item_no           =  iv_item_no
        AND   xicv.item_id           =  ximv.item_id
        AND   ROWNUM                 =  1
      ;
    EXCEPTION
      WHEN  NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_no_data_found_err,
                                              cv_tkn_item_code,
                                              iv_item_no);
        lv_err_cd := cv_xxwsh_no_data_found_err;
        RAISE global_api_expt;
    END;
--
     -- �Ɩ���O�`�F�b�N
    -- �h�����N�����i�̕i�ڂ̏ꍇ
    IF (  ( lv_prod_class_code = cv_prod_class_drink   )
      AND ( lv_item_class_code = cv_item_class_product )) THEN
    --
    -- �z����0�܂���NULL�Ȃ�G���[
      IF ( NVL(ln_delivery_qty, 0) = 0 ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_get_deliv_qty_err,
                                              cv_tkn_item_code,
                                              iv_item_no);
        lv_err_cd := cv_xxwsh_get_deliv_qty_err;
        RAISE global_api_expt;
    --
    -- �p���b�g����ő�i����0�܂���NULL�Ȃ�G���[
      ELSIF ( NVL(ln_max_palette_steps, 0) = 0 ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_palette_steps_err,
                                              cv_tkn_item_code,
                                              iv_item_no);
        lv_err_cd := cv_xxwsh_palette_steps_err;
        RAISE global_api_expt;
    --
    -- �P�[�X������0�܂���NULL�Ȃ�G���[
      ELSIF ( NVL(ln_num_of_cases, 0) = 0 ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_d_num_of_case_err,
                                              cv_tkn_item_code,
                                              iv_item_no);
        lv_err_cd := cv_xxwsh_d_num_of_case_err;
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- ���o�Ɋ��Z�P�ʂ�NULL�ȊO�̏ꍇ�A�P�[�X������0�܂���NULL�Ȃ�G���[
    IF (  ( lv_conv_unit IS NOT NULL )
      AND ( NVL(ln_num_of_cases, 0) = 0 ) ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_num_of_case_err,
                                              cv_tkn_item_code,
                                              iv_item_no);
        lv_err_cd := cv_xxwsh_num_of_case_err;
        RAISE global_api_expt;
    END IF;
--
    /**********************************
     *  ���v�p���b�g�d�ʂ̎Z�o(B-4)   *
     **********************************/
    --
    -- �h�����N���i�̏ꍇ�̂݁A���ʕ��̃p���b�g�d�ʂ��Z�o����B
    IF (  ( lv_prod_class_code = cv_prod_class_drink   )
      AND ( lv_item_class_code = cv_item_class_product ) )
    THEN
      --�u�p���b�g�����v�̎Z�o
      ln_pallet_qty
        := ( (  ( in_quantity   / ln_num_of_cases  ) / ln_delivery_qty  ) / ln_max_palette_steps);
      ln_pallet_qty
        := TRUNC( ln_pallet_qty + cn_rounup_const_no , cn_roundup_digits );
      --
      -- �u���v�p���b�g�d�ʁv�̎Z�o
      ln_pallet_sum_weight
                    := ln_pallet_qty * ln_pallet_waight;
    END IF;
    --
--
    /**********************************
     *  ���v�l�̎Z�o(B-5)             *
     **********************************/
    --
    -- �o�̓p�����[�^�u���v�e�ρv�u���v�d�ʁv
    on_sum_capacity      := ( ln_capacity * in_quantity ) / cn_conv_cm3_to_m3;
    on_sum_weight        := ( ln_weight   * in_quantity ) / cn_conv_g_to_kg;
    -- �o�̓p�����[�^�u���v�p���b�g�d�ʁv
    on_sum_pallet_weight := ln_pallet_sum_weight;
    --
    -- �X�e�[�^�X�R�[�h�Z�b�g
    ov_retcode           := gv_status_normal;   -- ���^�[���R�[�h
    ov_errmsg_code       := NULL;               -- �G���[���b�Z�[�W�R�[�h
    ov_errmsg            := NULL;               -- �G���[���b�Z�[�W
    --
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg      := lv_errmsg;
      ov_errmsg_code := lv_err_cd;
      ov_retcode     := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END calc_total_value;
--
  /**********************************************************************************
   * Procedure Name   : calc_load_efficiency
   * Description      : �ύڌ����`�F�b�N(�ύڌ����Z�o)
   ***********************************************************************************/
  PROCEDURE calc_load_efficiency(
    in_sum_weight                 IN  NUMBER,                                              -- 1.���v�d��
    in_sum_capacity               IN  NUMBER,                                              -- 2.���v�e��
    iv_code_class1                IN  xxcmn_ship_methods.code_class1%TYPE,                 -- 3.�R�[�h�敪�P
    iv_entering_despatching_code1 IN  xxcmn_ship_methods.entering_despatching_code1%TYPE,  -- 4.���o�ɏꏊ�R�[�h�P
    iv_code_class2                IN  xxcmn_ship_methods.code_class2%TYPE,                 -- 5.�R�[�h�敪�Q
    iv_entering_despatching_code2 IN  xxcmn_ship_methods.entering_despatching_code2%TYPE,  -- 6.���o�ɏꏊ�R�[�h�Q
    iv_ship_method                IN  xxcmn_ship_methods.ship_method%TYPE,                 -- 7.�o�ו��@
    iv_prod_class                 IN  xxcmn_item_categories_v.segment1%TYPE,               -- 8.���i�敪
    iv_auto_process_type          IN  VARCHAR2,                                            -- 9.�����z�ԑΏۋ敪
    id_standard_date              IN  DATE    DEFAULT SYSDATE,                      -- 10.���(�K�p�����)
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 11.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 12.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 13.�G���[���b�Z�[�W
    ov_loading_over_class         OUT NOCOPY VARCHAR2,                                     -- 14.�ύڃI�[�o�[�敪
    ov_ship_methods               OUT NOCOPY xxcmn_ship_methods.ship_method%TYPE,          -- 15.�o�ו��@
    on_load_efficiency_weight     OUT NOCOPY NUMBER,                                       -- 16.�d�ʐύڌ���
    on_load_efficiency_capacity   OUT NOCOPY NUMBER,                                       -- 17.�e�ϐύڌ���
    ov_mixed_ship_method          OUT NOCOPY VARCHAR2                                      -- 18.���ڔz���敪
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_load_efficiency'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�WID
    cv_xxwsh_wt_cap_set_err    CONSTANT VARCHAR2(100) := 'APP-XXWSH-12601'; -- �ύڏd�ʗe�ςȂ��G���[���b�Z�[�W
    cv_xxwsh_auto_type_err     CONSTANT VARCHAR2(100) := 'APP-XXWSH-12602'; -- ���̓p�����[�^�u�����z�ԑΏۋ敪�v�s��
    cv_xxwsh_unconformity_err  CONSTANT VARCHAR2(100) := 'APP-XXWSH-12603'; -- ���̓p�����[�^�s����
    cv_xxwsh_in_prod_class_err CONSTANT VARCHAR2(100) := 'APP-XXWSH-12604'; -- ���̓p�����[�^�u���i�敪�v�s��
    cv_xxwsh_in_param_set_err  CONSTANT VARCHAR2(100) := 'APP-XXWSH-12605'; -- ���̓p�����[�^�s��
    -- �g�[�N��
    cv_tkn_item_code               CONSTANT VARCHAR2(100) := 'ITEM_CODE';
    cv_tkn_prof_name               CONSTANT VARCHAR2(100) := 'PROF_NAME';
    cv_tkn_in_parm                 CONSTANT VARCHAR2(100) := 'IN_PARAM';
    -- �g�[�N���Z�b�g�l
    cv_code_class1_char            CONSTANT VARCHAR2(100) := '�R�[�h�敪From';
    cv_entering_despatch_cd1_char  CONSTANT VARCHAR2(100) := '���o�ɏꏊFrom';
    cv_code_class2_char            CONSTANT VARCHAR2(100) := '�R�[�h�敪To';
    cv_entering_despatch_cd2_char  CONSTANT VARCHAR2(100) := '���o�ɏꏊTo';
    cv_prod_class_char             CONSTANT VARCHAR2(100) := '���i�敪';
--
    -- ���i�敪
    cv_prod_class_leaf             CONSTANT VARCHAR2(1) := '1';  -- ���[�t
    cv_prod_class_drink            CONSTANT VARCHAR2(1) := '2';  -- �h�����N
--
    -- �ڋq�敪
    cv_cust_class_base             CONSTANT VARCHAR2(1) := '1';  -- ���_
    cv_cust_class_deliver          CONSTANT VARCHAR2(1) := '9';  -- �z����
--
    -- �ύڃI�[�o�[�敪
    cv_not_loading_over            CONSTANT VARCHAR2(1) := '0';  -- ����
    cv_loading_over                CONSTANT VARCHAR2(1) := '1';  -- �ύڃI�[�o�[
--
    cv_all_4                       CONSTANT VARCHAR2(4) := 'ZZZZ';      -- 2008/07/14 �ύX�v���Ή�#95
    cv_all_9                       CONSTANT VARCHAR2(9) := 'ZZZZZZZZZ'; -- 2008/07/14 �ύX�v���Ή�#95
--
-- 2008/08/04 Add H.Itou Start
  -- �R�[�h�敪
    cv_code_class_whse       CONSTANT VARCHAR2(10) := '4';  -- �z����
    cv_code_class_ship       CONSTANT VARCHAR2(10) := '9';  -- �o��
    cv_code_class_supply     CONSTANT VARCHAR2(10) := '11'; -- �x��
-- 2008/08/04 Add H.Itou End
-- 2008/08/04 H.Itou Del Start ���ISQL���~�̂��ߍ폜
--    -- ���ISQL��
--    -- ���C��SQL
--    cv_main_sql1                   CONSTANT VARCHAR2(32000)
--      :=    ' SELECT'
--         || '   xdlv.ship_method             AS ship_method_code,';
--    cv_main_sql2                   CONSTANT VARCHAR2(32000)
--      :=    '   xsmv.mixed_ship_method_code  AS mixed_ship_method_code  '
--         || ' FROM'
--         || '   xxcmn_delivery_lt2_v  xdlv,'
--         || '   xxwsh_ship_method2_v  xsmv'
--         || ' WHERE'
--         || '   xdlv.code_class1                = :iv_code_class1'
--         || '   AND'
--         || '   xdlv.entering_despatching_code1 = :iv_entering_despatching_code1'
--         || '   AND'
--         || '   xdlv.code_class2                = :iv_code_class2'
--         || '   AND'
--         || '   xdlv.entering_despatching_code2 = :iv_entering_despatching_code2'
--         || '   AND'
--         || '   xdlv.lt_start_date_active      <= trunc(:id_standard_date)'
--         || '   AND'
--         || '   xdlv.lt_end_date_active        >= trunc(:id_standard_date)'
--         || '   AND'
--         || '   xdlv.sm_start_date_active      <= trunc(:id_standard_date)'
--         || '   AND'
--         || '   xdlv.sm_end_date_active        >= trunc(:id_standard_date)'
--         || '   AND'
--         || '   (( xsmv.start_date_active      <= trunc(:id_standard_date))'
--         || '     OR'
--         || '    ( xsmv.start_date_active IS NULL ))'
--         || '   AND'
--         || '   (( xsmv.end_date_active        >= trunc(:id_standard_date))'
--         || '     OR'
--         || '    ( xsmv.end_date_active   IS NULL ))'
--         || '   AND'
--         || '   xdlv.ship_method           = NVL( :iv_ship_method, xdlv.ship_method )'
--         || '   AND'
--         || '   xsmv.ship_method_code      = xdlv.ship_method'
--         || '   AND'
--         || '   NVL( xsmv.auto_process_type, ''0'' )'
--         || '       = NVL( :iv_auto_process_type, NVL(xsmv.auto_process_type,''0'') )';
----         || '   AND';
--
--    -- �o�ו��@���w�肵�Ȃ������ꍇ�̒ǉ�����
--    cv_main_sql3                   CONSTANT VARCHAR2(32000)
--      :=  ' AND'
--       || ' xsmv.mixed_class = ''0'' '
--       || ' AND';
----
--    -- OUTPUT_COLUMN
--    cv_column_w1                   CONSTANT VARCHAR2(32000)
--      := 'xdlv.drink_deadweight          AS deadweight,';
--    cv_column_w2                   CONSTANT VARCHAR2(32000)
--      := 'xdlv.leaf_deadweight           AS deadweight,';
--    cv_column_c1                   CONSTANT VARCHAR2(32000)
--      := 'xdlv.drink_loading_capacity    AS loading_capacity,';
--    cv_column_c2                   CONSTANT VARCHAR2(32000)
--      := 'xdlv.leaf_loading_capacity     AS loading_capacity,';
--    -- ORDER BY
--    cv_order_by1                   CONSTANT VARCHAR2(32000)
--      :=    '   xdlv.drink_deadweight > 0'
--         || ' ORDER BY'
--         || '   xdlv.drink_deadweight DESC';
--    cv_order_by2                   CONSTANT VARCHAR2(32000)
--      :=    '   xdlv.leaf_deadweight > 0'
--         || ' ORDER BY'
--         || '   xdlv.leaf_deadweight  DESC';
--    cv_order_by3                   CONSTANT VARCHAR2(32000)
--      :=    '   xdlv.drink_loading_capacity > 0'
--         || ' ORDER BY'
--         || '   xdlv.drink_loading_capacity DESC';
--    cv_order_by4                   CONSTANT VARCHAR2(32000)
--      :=    '   xdlv.leaf_loading_capacity > 0'
--         || ' ORDER BY'
--         || '   xdlv.leaf_loading_capacity  DESC';
-- 2008/08/04 H.Itou Del End
--
    -- *** ���[�J���ϐ� ***
    -- �G���[�ϐ�
    lv_err_cd             VARCHAR2(30);
    -- ���ISQL�i�[�p
    lv_sql                     VARCHAR2(32000);
    lv_column_w                VARCHAR2(32000);
    lv_column_c                VARCHAR2(32000);
    lv_order_by                VARCHAR2(32000);
    --
    -- �֘A�f�[�^�i�[�p
    lv_base_code               VARCHAR2(4);                                       -- ���_�R�[�h
    ln_load_efficiency         NUMBER;                                            -- �ύڌ���
    ln_ship_method             xxcmn_delivery_lt2_v.ship_method%TYPE;             -- �o�ו��@
    ln_mixed_ship_method_code  xxwsh_ship_method2_v.mixed_ship_method_code%TYPE;  -- ���ڔz���敪
    lv_auto_process_type       xxwsh_ship_method2_v.auto_process_type%TYPE;       -- �����z�ԑΏۋ敪
-- 2008/08/04 H.Itou Add Start
    ln_sum_weight                 NUMBER;                                              -- ���v�d��
    ln_sum_capacity               NUMBER;                                              -- ���v�e��
    lv_code_class1                xxcmn_ship_methods.code_class1%TYPE;                 -- �R�[�h�敪�P
    lv_code_class2                xxcmn_ship_methods.code_class2%TYPE;                 -- �R�[�h�敪�Q
    lv_ship_method                xxcmn_ship_methods.ship_method%TYPE;                 -- �o�ו��@
    lv_prod_class                 xxcmn_item_categories_v.segment1%TYPE;               -- ���i�敪
    ld_standard_date              DATE;                                                -- ���(�K�p�����)
-- 2008/08/04 H.Itou Add End
--
    -- �ޔ�p
    ln_load_efficiency_tmp     NUMBER;                                              -- �ύڌ���
    ln_ship_method_tmp           xxcmn_delivery_lt2_v.ship_method%TYPE;             -- �o�ו��@
    ln_mixed_ship_method_cd_tmp  xxwsh_ship_method2_v.mixed_ship_method_code%TYPE;  -- ���ڔz���敪
    --
    lv_entering_despatching_code1  xxcmn_delivery_lt2_v.entering_despatching_code1%TYPE; -- 2008/07/14 �ύX�v���Ή�#95
    lv_entering_despatching_code2  xxcmn_delivery_lt2_v.entering_despatching_code2%TYPE; -- 2008/07/14 �ύX�v���Ή�#95
--
    -- *** ���[�J���E�J�[�\�� ***
-- 2008/08/04 H.Itou Add Start
    -- �ύڌ����擾�J�[�\��
    CURSOR lc_ref IS
      SELECT subsql.ship_method              ship_method            -- �o�ו��@
            ,subsql.mixed_ship_method_code   mixed_ship_method_code -- ���ڔz���敪
            ,subsql.deadweight               deadweight             -- �ύڏd��
            ,subsql.loading_capacity         loading_capacity       -- �ύڗe��
      FROM  ( SELECT xdlv.ship_method                ship_method            -- �o�ו��@
                    ,xsmv.mixed_ship_method_code     mixed_ship_method_code -- ���ڔz���敪
                    ,CASE
                      -- ���i�敪 1:���[�t�̏ꍇ�A���[�t�d�ʂ�ύڏd�ʂƂ���B
                      WHEN (lv_prod_class = cv_prod_class_leaf) THEN
                        xdlv.leaf_deadweight
                      -- ���i�敪 2:�h�����N �̏ꍇ�A�h�����N�d�ʂ�ύڏd�ʂƂ���B
                      WHEN (lv_prod_class = cv_prod_class_drink) THEN
                        xdlv.drink_deadweight
                     END  deadweight  -- �ύڏd��
                    ,CASE
                      -- ���i�敪 1:���[�t�̏ꍇ�A���[�t�e�ς�ύڗe�ςƂ���B
                      WHEN (lv_prod_class = cv_prod_class_leaf) THEN
                        xdlv.leaf_loading_capacity
                      -- ���i�敪 2:�h�����N �̏ꍇ�A�h�����N�e�ς�ύڗe�ςƂ���B
                      WHEN (lv_prod_class = cv_prod_class_drink) THEN
                        xdlv.drink_loading_capacity
                     END  loading_capacity  -- �ύڗe��
                    ,CASE
                       -- �D��@ ���o�ɏꏊ�i�ʁ|�ʁj
                       WHEN ((xdlv.entering_despatching_code1 = lv_entering_despatching_code1)
                        AND  (xdlv.entering_despatching_code2 = lv_entering_despatching_code2)) THEN
                          1
                       -- �D��A ���o�ɏꏊ�iZZZZ�|�ʁj
                       WHEN ((xdlv.entering_despatching_code1 = cv_all_4)
                         AND (xdlv.entering_despatching_code2 = lv_entering_despatching_code2)) THEN
                          2
                       -- �D��B ���o�ɏꏊ�i�ʁ|ZZZZ�j
                       WHEN ((xdlv.entering_despatching_code1 = lv_entering_despatching_code1)
                         AND ((((xdlv.code_class2 IN (cv_code_class_whse, cv_code_class_supply)) AND (xdlv.entering_despatching_code2 = cv_all_4)))
                           OR (((xdlv.code_class2 = cv_code_class_ship) AND (xdlv.entering_despatching_code2 = cv_all_9))))) THEN
                          3
                       -- �D��C ���o�ɏꏊ�iZZZZ�|ZZZZ�j
                       WHEN ((xdlv.entering_despatching_code1 = cv_all_4)
                         AND (((xdlv.code_class2 IN (cv_code_class_whse, cv_code_class_supply)) AND (xdlv.entering_despatching_code2 = cv_all_4))
                           OR ((xdlv.code_class2 = cv_code_class_ship) AND (xdlv.entering_despatching_code2 = cv_all_9)))) THEN
                          4
                     END  sql_sort         -- ���o�ɏꏊ�D�揇
              FROM   xxcmn_delivery_lt2_v  xdlv        -- �z��L/T���VIEW2
                    ,xxwsh_ship_method2_v  xsmv        -- �z���敪���VIEW2
              WHERE xsmv.ship_method_code      = xdlv.ship_method  -- ��������
                AND xdlv.code_class1 = lv_code_class1  -- �R�[�h�敪�P
                AND xdlv.code_class2 = lv_code_class2  -- �R�[�h�敪�Q
                AND xdlv.lt_start_date_active      <= TRUNC(ld_standard_date)
                AND xdlv.lt_end_date_active        >= TRUNC(ld_standard_date)
                AND xdlv.sm_start_date_active      <= TRUNC(ld_standard_date)
                AND xdlv.sm_end_date_active        >= TRUNC(ld_standard_date)
                AND (( xsmv.start_date_active      <= TRUNC(ld_standard_date))
                  OR ( xsmv.start_date_active IS NULL ))
                AND (( xsmv.end_date_active        >= TRUNC(ld_standard_date))
                  OR ( xsmv.end_date_active   IS NULL ))
                AND xdlv.ship_method           = NVL( lv_ship_method, xdlv.ship_method ) -- �o�ו��@
                AND NVL( xsmv.auto_process_type, '0' ) = NVL(lv_auto_process_type, NVL(xsmv.auto_process_type,'0')) -- �����z�ԑΏۋ敪
                -- �D��@ ���o�ɏꏊ�i�ʁ|�ʁj
                AND(((xdlv.entering_despatching_code1 = lv_entering_despatching_code1)
                 AND (xdlv.entering_despatching_code2 = lv_entering_despatching_code2))
                -- �D��A ���o�ɏꏊ�iZZZZ�|�ʁj
                  OR ((xdlv.entering_despatching_code1 = cv_all_4)
                   AND (xdlv.entering_despatching_code2 = lv_entering_despatching_code2))
                -- �D��B ���o�ɏꏊ�i�ʁ|ZZZZ�j
                  OR (((xdlv.entering_despatching_code1 = lv_entering_despatching_code1))
                   AND (((xdlv.code_class2 IN (cv_code_class_whse, cv_code_class_supply)) AND (xdlv.entering_despatching_code2 = cv_all_4))
                     OR ((xdlv.code_class2 = cv_code_class_ship) AND (xdlv.entering_despatching_code2 = cv_all_9))))
                -- �D��C ���o�ɏꏊ�iZZZZ�|ZZZZ�j
                  OR (((xdlv.entering_despatching_code1 = cv_all_4))
                   AND (((xdlv.code_class2 IN (cv_code_class_whse, cv_code_class_supply)) AND (xdlv.entering_despatching_code2 = cv_all_4))
                     OR ((xdlv.code_class2 = cv_code_class_ship) AND (xdlv.entering_despatching_code2 = cv_all_9)))))
                -- �o�ו��@�ɒl�Ȃ� ���A���i�敪 1:���[�t ���� ���v�d�ʂɒl���� �̏ꍇ�A���[�t�d�ʂ������ɒǉ�
                AND (((lv_ship_method IS NULL) AND (lv_prod_class = cv_prod_class_leaf)  AND (ln_sum_weight IS NOT NULL)  AND (xdlv.leaf_deadweight > 0))
                -- �o�ו��@�ɒl�Ȃ� ���A���i�敪 1:���[�t ���� ���v�d�ʂɒl�Ȃ� �̏ꍇ�A���[�t�e�ς������ɒǉ�
                  OR ((lv_ship_method IS NULL) AND (lv_prod_class = cv_prod_class_leaf)  AND (ln_sum_weight IS NULL)      AND (xdlv.leaf_loading_capacity > 0))
                -- �o�ו��@�ɒl�Ȃ� ���A���i�敪 2:�h�����N ���� ���v�d�ʂɒl���� �̏ꍇ�A�h�����N�d�ʂ������ɒǉ�
                  OR ((lv_ship_method IS NULL) AND (lv_prod_class = cv_prod_class_drink) AND (ln_sum_weight IS  NOT NULL) AND (xdlv.drink_deadweight > 0))
                -- �o�ו��@�ɒl�Ȃ� ���A���i�敪 2:�h�����N ���� ���v�d�ʂɒl�Ȃ� �̏ꍇ�A�h�����N�e�ς������ɒǉ�
                  OR ((lv_ship_method IS NULL) AND (lv_prod_class = cv_prod_class_drink) AND (ln_sum_weight IS NULL)      AND (xdlv.drink_loading_capacity > 0))
                -- �o�ו��@�ɒl����̏ꍇ�́A�ύڏd�ʁE�ύڗe�ς������Ƃ��Ȃ��B
                  OR ((lv_ship_method IS NOT NULL)))
              ) subsql
      ORDER BY subsql.ship_method DESC  -- �o�ו��@         �~��
              ,subsql.sql_sort          -- ���o�ɏꏊ�D�揇 ����
    ;
-- 2008/08/04 H.Itou Add End
-- 2008/08/04 H.Itou Del Start ���ISQL���~�̂��ߍ폜
--    TYPE ref_cursor   IS REF CURSOR ;           -- 1. �q��(�ʃR�[�h)�|�z����(�ʃR�[�h)�̌����`�F�b�N�p�J�[�\��
--    lc_ref     ref_cursor ;
--    --
--    TYPE ref_cursor2  IS REF CURSOR ;           -- 1.��NOTFOUND�ŁA2.3.4.�̂����ꂩ��FOUND�����ꍇ�Ɏg�p����J�[�\��
--    lc_ref2    ref_cursor2 ;
----
--    -- 2008/07/14 �ύX�v���Ή�#95 Start ------------------------
--    TYPE fnd_chk_cursor2   IS REF CURSOR ;      -- 2. �q��(ALL�l)�|�z����(�ʃR�[�h)�̌����`�F�b�N�p�J�[�\��
--    lc_fnd_chk2     fnd_chk_cursor2 ;
--    --
--    TYPE fnd_chk_cursor3   IS REF CURSOR ;      -- 3. �q��(�ʃR�[�h)�|�z����(ALL�l)�̌����`�F�b�N�p�J�[�\��
--    lc_fnd_chk3     fnd_chk_cursor3 ;
--    --
--    TYPE fnd_chk_cursor4   IS REF CURSOR ;      -- 4. �q��(ALL�l)�|�z����(ALL�l)�̌����`�F�b�N�p�J�[�\��
--    lc_fnd_chk4     fnd_chk_cursor4 ;
--    -- 2008/07/14 �ύX�v���Ή�#95 End ---------------------------
-- 2008/08/04 H.Itou Del End
--
    -- *** ���[�J���E���R�[�h ***
-- 2008/08/04 H.Itou Add Start
    lr_ref  lc_ref%ROWTYPE;  -- �J�[�\���p���R�[�h
-- 2008/08/04 H.Itou Add End
--
-- 2008/08/04 H.Itou Del Start ���ISQL���~�̂��ߍ폜
--    TYPE ret_value  IS RECORD
--      (
--        ship_method                xxcmn_delivery_lt2_v.ship_method%TYPE        -- �o�ו��@
--       ,deadweight                 NUMBER                                       -- �ύڏd��
--       ,loading_capacity           NUMBER                                       -- �ύڗe��
--       ,mixed_ship_method_code     xxwsh_ship_method2_v.mixed_ship_method_code%TYPE -- ���ڔz���敪
--      );
--    lr_ref        ret_value ;
--    lr_ref2       ret_value ;
--    lr_fnd_chk2   ret_value ;      -- 2008/07/14 �ύX�v���Ή�#95
--    lr_fnd_chk3   ret_value ;      -- 2008/07/14 �ύX�v���Ή�#95
--    lr_fnd_chk4   ret_value ;      -- 2008/07/14 �ύX�v���Ή�#95
-- 2008/08/04 H.Itou Del End
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --
    /**********************************
     *  �p�����[�^�`�F�b�N(C-1)       *
     **********************************/
    -- �K�{���̓p�����[�^�`�F�b�N
    -- �R�[�h�敪From
    IF ( iv_code_class1  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_code_class1_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- ���o�ɏꏊFrom
    ELSIF ( iv_entering_despatching_code1  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_entering_despatch_cd1_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- �R�[�h�敪To
    ELSIF ( iv_code_class2  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_code_class2_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- ���o�ɏꏊTo
    ELSIF ( iv_entering_despatching_code2  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_entering_despatch_cd2_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- ���i�敪
    ELSIF ( iv_prod_class  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_prod_class_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    --
    -- �u���v�d�ʁv�Ɓu���v�e�ρv�����ꂩ����̂݃Z�b�g
    ELSIF (( ( in_sum_weight   IS NULL )
         AND ( in_sum_capacity IS NULL ) )
      OR (   ( in_sum_weight   IS NOT NULL )
         AND ( in_sum_capacity IS NOT NULL ) ) ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_unconformity_err);
      lv_err_cd := cv_xxwsh_unconformity_err;
      RAISE global_api_expt;
    --
    -- �u���i�敪�v�ɁA�P�i���[�t�j�A�Q�i�h�����N�j�ȊO���Z�b�g����Ă��Ȃ���
    ELSIF ( iv_prod_class NOT IN ( cv_prod_class_leaf ,cv_prod_class_drink ) ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_prod_class_err);
      lv_err_cd := cv_xxwsh_in_prod_class_err;
      RAISE global_api_expt;
    --
    -- ���̓p�����[�^�u�o�ו��@�v���Z�b�g����Ă��Ȃ��ꍇ�A
    -- ���̓p�����[�^�u�����z�ԑΏۋ敪�v���Z�b�g����Ă��邩�B
    ELSIF (( iv_ship_method       IS NULL  )
      AND  ( iv_auto_process_type IS NULL  ) ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_auto_type_err);
      lv_err_cd := cv_xxwsh_auto_type_err;
      RAISE global_api_expt;
    END IF;
    --
    -- ���̓p�����[�^�u�o�ו��@�v���Z�b�g����A����
    -- ���̓p�����[�^�u�����z�ԑΏۋ敪�v���Z�b�g����Ă���ꍇ�A���o�����Ƃ��Ȃ��B
    IF   ( ( iv_ship_method       IS NOT NULL  )
      AND  ( iv_auto_process_type IS NOT NULL  ) ) THEN
      lv_auto_process_type := NULL;
    ELSE
      lv_auto_process_type := iv_auto_process_type;
    END IF;
--
--
    /**********************************
     *  �ύڌ����Z�o(C-2)             *
     **********************************/
-- 2008/08/04 H.Itou Del Start ���ISQL���~�̂��ߍ폜
--    -- ���ISQL�̏o�͍��ڂ�ORDER BY������߂�
--    IF ( iv_prod_class = cv_prod_class_leaf ) THEN
--      IF ( in_sum_weight IS NOT NULL ) THEN
--        lv_order_by := cv_order_by2;          -- ���[�t�d��
--      ELSE
--        lv_order_by := cv_order_by4;          -- ���[�t�e��
--      END IF;
--      --
--      lv_column_w := cv_column_w2;            -- ���[�t�ύڏd��
--      lv_column_c := cv_column_c2;            -- ���[�t�ύڗe��
--    ELSE
--      IF ( in_sum_weight IS NOT NULL ) THEN
--        lv_order_by := cv_order_by1;          -- �h�����N�d��
--      ELSE
--        lv_order_by := cv_order_by3;          -- �h�����N�e��
--      END IF;
--      lv_column_w := cv_column_w1;            -- �h�����N�ύڏd��
--      lv_column_c := cv_column_c1;            -- �h�����N�ύڗe��
--    END IF;
--    --
--    -- ���ISQL�{�������߂�
--    -- �o�ו��@���Z�b�g����Ă��Ȃ��ꍇ
--    IF ( iv_ship_method IS NULL ) THEN
--      lv_sql :=   cv_main_sql1
--               || lv_column_w
--               || lv_column_c
--               || cv_main_sql2
--               || cv_main_sql3
--               || lv_order_by;
----
--    ELSE
--      lv_sql :=   cv_main_sql1
--               || lv_column_w
--               || lv_column_c
--               || cv_main_sql2;
----               || lv_order_by;
--    END IF;
--    --
--    -- SQL�̎��s
--    OPEN lc_ref FOR lv_sql
--      USING
--        iv_code_class1,                      -- �R�[�h�敪From
--        iv_entering_despatching_code1,       -- ���o�ɏꏊFrom
--        iv_code_class2,                      -- �R�[�h�敪To
--        iv_entering_despatching_code2,       -- ���o�ɏꏊTo
--        id_standard_date,                    -- �K�p��
--        id_standard_date,
--        id_standard_date,
--        id_standard_date,
--        id_standard_date,
--        id_standard_date,
--        iv_ship_method,                      -- �o�ו��@
--        lv_auto_process_type;                -- �����z�ԑΏۋ敪
-- 2008/08/04 H.Itou Del End
-- 2008/08/04 H.Itou Add Start
    -- ���[�J���ϐ���IN�p�����[�^���Z�b�g
-- 2008/08/06 H.Itou Mod Start ���v�d�ʁE���v�e�ϥ�������_���ʂ�؂�グ�Čv�Z����B
--    ln_sum_weight                 := in_sum_weight;                  -- ���v�d��
    ln_sum_weight                 := CEIL(TRUNC(in_sum_weight, 1));  -- ���v�d��
--    ln_sum_capacity               := in_sum_capacity;                -- ���v�e��
    ln_sum_capacity               := CEIL(TRUNC(in_sum_capacity, 1));-- ���v�e��
-- 2008/08/06 H.Itou Mod End
    lv_code_class1                := iv_code_class1;                 -- �R�[�h�敪�P
    lv_entering_despatching_code1 := iv_entering_despatching_code1;  -- ���o�ɏꏊ�R�[�h�P
    lv_code_class2                := iv_code_class2;                 -- �R�[�h�敪�Q
    lv_entering_despatching_code2 := iv_entering_despatching_code2;  -- ���o�ɏꏊ�R�[�h�Q
    lv_ship_method                := iv_ship_method;                 -- �o�ו��@
    lv_prod_class                 := iv_prod_class;                  -- ���i�敪
    ld_standard_date              := NVL(id_standard_date, SYSDATE); -- ���(�K�p�����)
--
    -- �J�[�\���I�[�v��
    OPEN lc_ref;
-- 2008/08/04 H.Itou Add End
--
    /**********************************
     *  �œK�o�ו��@�̎Z�o(C-3)       *
     **********************************/
    -- FETCH
    FETCH lc_ref INTO lr_ref;
--
    -- �����ł�����
    IF ( lc_ref%FOUND ) THEN
--
      -- �o�ו��@���Z�b�g����Ă��Ȃ��ꍇ�́A���[�v����B
      IF ( iv_ship_method IS NULL ) THEN
        -- �����ł����ꍇ
        << delv_lt_loop >>
        LOOP
-- 2008/08/04 H.Itou Add Start ����o�ו��@���A���o�ɏꏊ�D�揇���ŗD��̃��R�[�h�Ŕ�r����B
          -- �o�ו��@���u���C�N�����ꍇ�A�ύڌ������擾�B
          IF  ((ln_ship_method_tmp <> lr_ref.ship_method)
            OR (ln_ship_method_tmp IS NULL)) THEN
-- 2008/08/04 H.Itou Add End
-- 2008/08/04 H.Itou Mod Start
            -- �ύڌ����Z�o
            IF ( in_sum_weight IS NOT NULL ) THEN
              ln_load_efficiency_tmp
-- 2008/08/06 H.Itou Mod Start ���v�d�ʁE���v�e�ϥ�������_���ʂ�؂�グ�Čv�Z����B
--                 := ( in_sum_weight   / lr_ref.deadweight       ) * 100;
                 := ( ln_sum_weight   / lr_ref.deadweight       ) * 100;
-- 2008/08/06 H.Itou Mod End
            ELSE
              ln_load_efficiency_tmp
-- 2008/08/06 H.Itou Mod Start ���v�d�ʁE���v�e�ϥ�������_���ʂ�؂�グ�Čv�Z����B
--                 := ( in_sum_capacity / lr_ref.loading_capacity ) * 100;
                 := ( ln_sum_capacity / lr_ref.loading_capacity ) * 100;
-- 2008/08/06 H.Itou Mod End
            END IF;
--
-- 2008/08/06 H.Itou Add Start ������O�ʂ�؂�グ
            ln_load_efficiency_tmp := comp_round_up(ln_load_efficiency_tmp, 2);
-- 2008/08/06 H.Itou Add End
            -- ���̑����
            ln_ship_method_tmp          := lr_ref.ship_method;             -- �o�ו��@
            ln_mixed_ship_method_cd_tmp := lr_ref.mixed_ship_method_code;  -- ���ڔz���敪
            -- 100%�𒴂����ꍇ�A���[�v�I��
            EXIT WHEN ( ln_load_efficiency_tmp > 100 );
-- 2008/08/04 H.Itou Mod End
-- 2008/08/04 H.Itou Add Start
          END IF;
-- 2008/08/04 H.Itou Add End
          -- �����R�[�h����
          FETCH lc_ref INTO lr_ref;
          --
          -- �f�[�^���Ȃ��Ȃ����ꍇ�A���[�v�I��
          EXIT WHEN ( lc_ref%NOTFOUND );
          --
          -- �f�[�^�ޔ�
          ln_load_efficiency         := ln_load_efficiency_tmp;
          --
          ln_ship_method             := ln_ship_method_tmp;           -- �o�ו��@
          ln_mixed_ship_method_code  := ln_mixed_ship_method_cd_tmp;  -- ���ڔz���敪
          --
        END LOOP delv_lt_loop;
--
        -- 100%�𒴂��ă��[�v�I�������ꍇ�́A���̒l���Z�b�g���Ȃ�
        IF ( ln_load_efficiency_tmp <= 100 ) THEN
          ln_load_efficiency         := ln_load_efficiency_tmp;
          --
          ln_ship_method             := ln_ship_method_tmp;           -- �o�ו��@
          ln_mixed_ship_method_code  := ln_mixed_ship_method_cd_tmp;  -- ���ڔz���敪
        END IF;
--
      -- �o�ו��@���Z�b�g����Ă�ꍇ�́A1���ڂ̃f�[�^���Ώۃf�[�^�Ȃ̂Ń��[�v���Ȃ��B
      ELSE
        --
        -- �ύڌ����Z�o
        IF ( in_sum_weight IS NOT NULL ) THEN
          IF ( NVL(lr_ref.deadweight, 0) = 0 ) THEN
            ln_load_efficiency := 0;
          ELSE
            ln_load_efficiency
-- 2008/08/06 H.Itou Mod Start ���v�d�ʁE���v�e�ϥ�������_���ʂ�؂�グ�Čv�Z����B
--               := ( in_sum_weight   / lr_ref.deadweight       ) * 100;
               := ( ln_sum_weight   / lr_ref.deadweight       ) * 100;
-- 2008/08/06 H.Itou Mod End
          END IF;
--
        ELSE
--
          IF ( NVL(lr_ref.loading_capacity, 0) = 0 ) THEN
            ln_load_efficiency := 0;
          ELSE
            ln_load_efficiency
-- 2008/08/06 H.Itou Mod Start ���v�d�ʁE���v�e�ϥ�������_���ʂ�؂�グ�Čv�Z����B
--               := ( in_sum_capacity / lr_ref.loading_capacity ) * 100;
               := ( ln_sum_capacity / lr_ref.loading_capacity ) * 100;
-- 2008/08/06 H.Itou Mod End
          END IF;
--
        END IF;
        --
-- 2008/08/06 H.Itou Add Start ������O�ʂ�؂�グ
        ln_load_efficiency := comp_round_up(ln_load_efficiency, 2);
-- 2008/08/06 H.Itou Add End
        -- ���̑����
        ln_ship_method             := lr_ref.ship_method;             -- �o�ו��@
        ln_mixed_ship_method_code  := lr_ref.mixed_ship_method_code;  -- ���ڔz���敪
        --
      END IF;
    --
    ELSE
-- 2008/08/04 H.Itou Add Start
      -- �Ώۃf�[�^�Ȃ�
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_wt_cap_set_err);
      lv_err_cd := cv_xxwsh_wt_cap_set_err;
      -- �J�[�\���N���[�Y
      CLOSE lc_ref;
      --
      RAISE global_api_expt;
-- 2008/08/04 H.Itou Add End
-- 2008/08/04 H.Itou Del Start
--      -- �����ł��Ȃ������ꍇ
--      -- �R�[�h�敪2���u�z����v���`�F�b�N
--      IF ( iv_code_class2 = cv_cust_class_deliver ) THEN  -- �R�[�h�敪2=�u9:�z���v�̏ꍇ�͈ȉ�2.3.4.�ōČ�������
--        --
--        -- 2008/07/14 �ύX�v���Ή�#95 Add Start ----------------------------------------------
--        -- 1.�Ō�����Ȃ������̂ŁA2. �q��(ALL�l)�|�z����(�ʃR�[�h)�ōČ���
--        OPEN lc_fnd_chk2 FOR lv_sql
--          USING
--            iv_code_class1,                      -- �R�[�h�敪From
--            cv_all_4,                            -- ���o�ɏꏊFrom  (=ALL'Z'�Ō���)
--            iv_code_class2,                      -- �R�[�h�敪To
--            iv_entering_despatching_code2,       -- ���o�ɏꏊTo
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            iv_ship_method,                      -- �o�ו��@
--            lv_auto_process_type;                -- �����z�ԑΏۋ敪
--        --
--        FETCH lc_fnd_chk2 INTO lr_fnd_chk2;
--        --
--        IF ( lc_fnd_chk2%NOTFOUND ) THEN         -- 2.�ŊY���f�[�^�Ȃ��̏ꍇ
--          CLOSE lc_fnd_chk2;                     -- �J�[�\���N���[�Y
--          --
--          -- 2.�Ō�����Ȃ������̂ŁA3. �q��(�ʃR�[�h)�|�z����(ALL�l)�ōČ���
--          OPEN lc_fnd_chk3 FOR lv_sql
--            USING
--              iv_code_class1,                      -- �R�[�h�敪From
--              iv_entering_despatching_code1,       -- ���o�ɏꏊFrom
--              iv_code_class2,                      -- �R�[�h�敪To
--              cv_all_9,                            -- ���o�ɏꏊTo  (=ALL'Z'�Ō���)
--              id_standard_date,
--              id_standard_date,
--              id_standard_date,
--              id_standard_date,
--              id_standard_date,
--              id_standard_date,
--              iv_ship_method,                      -- �o�ו��@
--              lv_auto_process_type;                -- �����z�ԑΏۋ敪
--          --
--          FETCH lc_fnd_chk3 INTO lr_fnd_chk3;
--          --
--          IF ( lc_fnd_chk3%NOTFOUND ) THEN         -- 3.�ŊY���f�[�^�Ȃ��̏ꍇ
--            CLOSE lc_fnd_chk3;                     -- �J�[�\���N���[�Y
--            --
--            -- 3.�Ō�����Ȃ������̂ŁA4. �q��(ALL�l)�|�z����(ALL�l)�ōČ���
--            OPEN lc_fnd_chk4 FOR lv_sql
--              USING
--                iv_code_class1,                      -- �R�[�h�敪From
--                cv_all_4,                            -- ���o�ɏꏊFrom (=ALL'Z'�Ō���)
--                iv_code_class2,                      -- �R�[�h�敪To
--                cv_all_9,                            -- ���o�ɏꏊTo   (=ALL'Z'�Ō���)
--                id_standard_date,
--                id_standard_date,
--                id_standard_date,
--                id_standard_date,
--                id_standard_date,
--                id_standard_date,
--                iv_ship_method,                      -- �o�ו��@
--                lv_auto_process_type;                -- �����z�ԑΏۋ敪
--            --
--            FETCH lc_fnd_chk4 INTO lr_fnd_chk4;
--            --
--            IF ( lc_fnd_chk4%NOTFOUND ) THEN         -- 4.�ŊY���f�[�^�Ȃ��̏ꍇ
--              CLOSE lc_fnd_chk4;                     -- �J�[�\���N���[�Y
--              --1.����4.���ׂĊY���f�[�^�Ȃ̂ŁA�Ώۃf�[�^�Ȃ��ŏ�������
--              lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,cv_xxwsh_wt_cap_set_err);
--              lv_err_cd := cv_xxwsh_wt_cap_set_err;
--              RAISE global_api_expt;
--            --
--            ELSE  -- 4.�ŊY���f�[�^����̏ꍇ
--              CLOSE lc_fnd_chk4;                     -- �J�[�\���N���[�Y
--              lv_entering_despatching_code1 := cv_all_4;  -- (=ALL'Z'�Ō���)
--              lv_entering_despatching_code2 := cv_all_9;  -- (=ALL'Z'�Ō���)
--            END IF;
--          --
--          ELSE  -- 3.�ŊY���f�[�^����̏ꍇ
--              CLOSE lc_fnd_chk3;                     -- �J�[�\���N���[�Y
--              lv_entering_despatching_code1 := iv_entering_despatching_code1;  -- �ʃR�[�h�Ō���
--              lv_entering_despatching_code2 := cv_all_9;                       -- (=ALL'Z'�Ō���)
--          END IF;
--        --
--        ELSE  -- 2.�ŊY���f�[�^����̏ꍇ
--            CLOSE lc_fnd_chk2;                     -- �J�[�\���N���[�Y
--            lv_entering_despatching_code1 := cv_all_4;                       -- (=ALL'Z'�Ō���)
--            lv_entering_despatching_code2 := iv_entering_despatching_code2;  -- �ʃR�[�h�Ō���
--        END IF;
--        -- 2008/07/14 �ύX�v���Ή�#95 Add End ----------------------------------------------
--        --
--        -- 2008/07/14 �ύX�v���Ή�#95 Del Start --------------------------------------------
--        ---- �R�[�h�敪2���u���_�v�Ō�������
--        --BEGIN
--        --  SELECT  xcasv.base_code                                            -- ���_�R�[�h
--        --  INTO    lv_base_code
--        --  FROM    xxcmn_cust_acct_sites2_v  xcasv                            -- �ڋq�T�C�g���View2
--        --  WHERE   xcasv.ship_to_no         =  iv_entering_despatching_code2  -- �z����ԍ�
--        --    AND   xcasv.start_date_active <=  trunc(id_standard_date)        -- �K�p��
--        --    AND   xcasv.end_date_active   >=  trunc(id_standard_date);
--        --EXCEPTION
--        --  WHEN  NO_DATA_FOUND  THEN
--        --    lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--        --                                          cv_xxwsh_wt_cap_set_err);
--        --    lv_err_cd := cv_xxwsh_in_param_set_err;
--        --    -- �J�[�\���N���[�Y
--        --    CLOSE lc_ref;
--        --    --
--        --    RAISE global_api_expt;
--        --  --
--        --  WHEN  OTHERS THEN
--        --    -- �J�[�\���N���[�Y
--        --    CLOSE lc_ref;
--        --    --
--        --    RAISE global_api_others_expt;
--        --END;
--        -- 2008/07/14 �ύX�v���Ή�#95 Del End -------------------------------------------
--        --
--        -- SQL�̎��s
--        OPEN lc_ref2 FOR lv_sql
--          USING
--            iv_code_class1,                      -- �R�[�h�敪From
--            --iv_entering_despatching_code1,       -- ���o�ɏꏊFrom   -- 2008/07/14 �ύX�v���Ή�#95
--            lv_entering_despatching_code1,       -- ���o�ɏꏊFrom     -- 2008/07/14 �ύX�v���Ή�#95
--            --cv_cust_class_base,                  -- �R�[�h�敪To(���_)  -- 2008/07/17 �ύX�v���Ή�#95�̃o�O�Ή�
--            cv_cust_class_deliver,               -- �R�[�h�敪To(�z����)  -- 2008/07/17 �ύX�v���Ή�#95�̃o�O�Ή�
--            --lv_base_code,                        -- ���o�ɏꏊTo(�Ǌ����_)  -- 2008/07/14 �ύX�v���Ή�#95
--            lv_entering_despatching_code2,       -- ���o�ɏꏊFrom            -- 2008/07/14 �ύX�v���Ή�#95
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            id_standard_date,
--            iv_ship_method,                      -- �o�ו��@
--            lv_auto_process_type;                -- �����z�ԑΏۋ敪
----
--        -- FETCH
--        FETCH lc_ref2 INTO lr_ref2;
--        --
--        -- �����ł�����
--        IF ( lc_ref2%FOUND ) THEN
--        --
--          -- �o�ו��@���Z�b�g����Ă��Ȃ��ꍇ�́A����Ɍ�������B
--          IF ( iv_ship_method IS NULL ) THEN
--            --
--            -- �����ł����ꍇ
--            << delv_lt_loop2 >>
--            LOOP
--              -- �ύڌ����Z�o
--              IF ( in_sum_weight IS NOT NULL ) THEN
--                ln_load_efficiency_tmp
--                   := ( in_sum_weight   / lr_ref2.deadweight       ) * 100;
--              ELSE
--                ln_load_efficiency_tmp
--                   := ( in_sum_capacity / lr_ref2.loading_capacity ) * 100;
--              END IF;
--              --
--              -- ���̑����
--              ln_ship_method_tmp           := lr_ref2.ship_method;             -- �o�ו��@
--              ln_mixed_ship_method_cd_tmp  := lr_ref2.mixed_ship_method_code;  -- ���ڔz���敪
--              --
--              -- 100%�𒴂����ꍇ�A���[�v�I��
--              EXIT WHEN ( ln_load_efficiency_tmp > 100 );
--              --
--              -- �����R�[�h����
--              FETCH lc_ref2 INTO lr_ref2;
--              --
--              -- �f�[�^���Ȃ��Ȃ����ꍇ�A���[�v�I��
--              EXIT WHEN ( lc_ref2%NOTFOUND );
--              --
--              -- �f�[�^�ޔ�
--              ln_load_efficiency         := ln_load_efficiency_tmp;
--              --
--              ln_ship_method             := ln_ship_method_tmp;           -- �o�ו��@
--              ln_mixed_ship_method_code  := ln_mixed_ship_method_cd_tmp;  -- ���ڔz���敪
--              --
--            END LOOP delv_lt_loop2;
--            --
--            -- 100%�𒴂��ă��[�v�I�������ꍇ�́A���̒l���Z�b�g���Ȃ�
--            IF ( ln_load_efficiency_tmp <= 100 ) THEN
--              ln_load_efficiency         := ln_load_efficiency_tmp;
--              --
--              ln_ship_method             := ln_ship_method_tmp;           -- �o�ו��@
--              ln_mixed_ship_method_code  := ln_mixed_ship_method_cd_tmp;  -- ���ڔz���敪
--            END IF;
--          ELSE
--            --
--            -- �ύڌ����Z�o
--            --IF ( in_sum_weight IS NOT NULL ) THEN
--            --  ln_load_efficiency
--            --     := ( in_sum_weight   / lr_ref2.deadweight       ) * 100;
--            --ELSE
--            --  ln_load_efficiency
--            --     := ( in_sum_capacity / lr_ref2.loading_capacity ) * 100;
--            --END IF;
--            IF ( in_sum_weight IS NOT NULL ) THEN
----
--              IF ( NVL(lr_ref2.deadweight, 0) = 0 ) THEN
--                ln_load_efficiency := 0;
--              ELSE
--                ln_load_efficiency
--                   := ( in_sum_weight   / lr_ref2.deadweight       ) * 100;
--              END IF;
----
--            ELSE
----
--              IF ( NVL(lr_ref2.loading_capacity, 0) = 0 ) THEN
--                ln_load_efficiency := 0;
--              ELSE
--                ln_load_efficiency
--                   := ( in_sum_capacity / lr_ref2.loading_capacity ) * 100;
--              END IF;
----
--            END IF;
--            --
--            -- ���̑����
--            ln_ship_method             := lr_ref2.ship_method;             -- �o�ו��@
--            ln_mixed_ship_method_code  := lr_ref2.mixed_ship_method_code;  -- ���ڔz���敪
--            --
--          END IF;
--        ELSE
--          -- �Ώۃf�[�^�Ȃ�
--          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                                cv_xxwsh_wt_cap_set_err);
--          lv_err_cd := cv_xxwsh_wt_cap_set_err;
--          -- �J�[�\���N���[�Y
--          CLOSE lc_ref;
--          --
--          RAISE global_api_expt;
--          --
--        END IF;
--        -- �J�[�\���N���[�Y
--        CLOSE lc_ref2;
--      ELSE
--        -- �Ώۃf�[�^�Ȃ�
--        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                              cv_xxwsh_wt_cap_set_err);
--        lv_err_cd := cv_xxwsh_wt_cap_set_err;
--        -- �J�[�\���N���[�Y
--        CLOSE lc_ref;
--        --
--        RAISE global_api_expt;
--        --
--      END IF;
-- 2008/08/04 H.Itou Del End
    END IF;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref;
--
--
    /**********************************
     *  OUT�p�����[�^�Z�b�g(C-4)      *
     **********************************/
    -- �X�e�[�^�X
    ov_retcode                  := gv_status_normal;        -- ���^�[���R�[�h
    ov_errmsg_code              := NULL;                    -- �G���[���b�Z�[�W�R�[�h
    ov_errmsg                   := NULL;                    -- �G���[���b�Z�[�W
    --
    -- �ύڃI�[�o�[�敪
    IF ( ln_load_efficiency <= 100 ) THEN
      ov_loading_over_class        := cv_not_loading_over;  -- ����
    ELSE
      ov_loading_over_class        := cv_loading_over;      -- �ύڃI�[�o�[
    END IF;
    --
    -- �o�ו��@
    IF ( iv_ship_method IS NOT NULL ) THEN
      ov_ship_methods              := iv_ship_method;       -- ���̓p�����[�^
    ELSE
      ov_ship_methods              := ln_ship_method;       -- �o�ו��@
    END IF;
    --
    -- �ύڌ���
    IF ( in_sum_weight IS NOT NULL ) THEN
      on_load_efficiency_weight    :=  ln_load_efficiency;
      on_load_efficiency_capacity  :=  NULL;
    ELSE
      on_load_efficiency_weight    :=  NULL;
      on_load_efficiency_capacity  :=  ln_load_efficiency;
    END IF;
    --
    -- ���ڔz���敪
    ov_mixed_ship_method           :=  ln_mixed_ship_method_code;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg      := lv_errmsg;
      ov_errmsg_code := lv_err_cd;
      ov_retcode     := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END calc_load_efficiency;
--
  /**********************************************************************************
   * Procedure Name   : check_lot_reversal
   * Description      : ���b�g�t�]�h�~�`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_lot_reversal(
    iv_lot_biz_class              IN  VARCHAR2,                            -- 1.���b�g�t�]�������
    iv_item_no                    IN  xxcmn_item_mst_v.item_no%TYPE,       -- 2.�i�ڃR�[�h
    iv_lot_no                     IN  ic_lots_mst.lot_no%TYPE,             -- 3.���b�gNo
    iv_move_to_id                 IN  NUMBER,                              -- 4.�z����ID/���ɐ�ID
    iv_arrival_date               IN  DATE,                                -- 5.����
    id_standard_date              IN  DATE  DEFAULT SYSDATE,               -- 6.���(�K�p�����)
    ov_retcode                    OUT NOCOPY VARCHAR2,                     -- 7.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                     -- 8.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                     -- 9.�G���[���b�Z�[�W
    on_result                     OUT NOCOPY NUMBER,                       -- 10.��������
    on_reversal_date              OUT NOCOPY DATE                          -- 11.�t�]���t
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_lot_reversal'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�WID
    cv_xxwsh_in_pram_set_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-12651'; -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
    cv_xxwsh_in_pram_lot_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-12652'; -- ���̓p�����[�^�u���b�g�t�]������ʁv�Z�b�g���e�G���[
    cv_xxwsh_in_pram_arr_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-12653'; -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W
    cv_xxwsh_in_no_lot_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-12654'; -- �Ώۃ��b�g�f�[�^�Ȃ��G���[���b�Z�[�W
    -- �g�[�N��
    cv_tkn_in_parm                 CONSTANT VARCHAR2(30)  := 'in_param';
    cv_tkn_lot_no                  CONSTANT VARCHAR2(30)  := 'lot_no';
    -- �g�[�N���Z�b�g�l
    cv_ship_move_class_char        CONSTANT VARCHAR2(30)  := '���b�g�t�]�������';
    cv_item_code_char              CONSTANT VARCHAR2(30)  := '�i�ڃR�[�h';
    cv_lot_no_char                 CONSTANT VARCHAR2(30)  := '���b�gNo';
    cv_move_to_char                CONSTANT VARCHAR2(30)  := '�z����ID/���ɐ�ID';
    --
    -- ���b�g�t�]�������
    cv_ship_plan                   CONSTANT VARCHAR2(1)   := '1';         -- �o�׎w��
    cv_ship_result                 CONSTANT VARCHAR2(1)   := '2';         -- �o�׎���
    cv_move_plan                   CONSTANT VARCHAR2(1)   := '5';         -- �ړ��w��
    cv_move_result                 CONSTANT VARCHAR2(1)   := '6';         -- �ړ�����
    --
    -- �o�׈˗��X�e�[�^�X
    cv_request_status_03           CONSTANT VARCHAR2(2)   := '03';        -- ���ߍς�
    cv_request_status_04           CONSTANT VARCHAR2(2)   := '04';        -- �o�׎��ьv���
    -- �ړ��X�e�[�^�X
    cv_move_status_03              CONSTANT VARCHAR2(2)   := '03';        -- ������
    cv_move_status_04              CONSTANT VARCHAR2(2)   := '04';        -- �o�ɕ񍐗L
    cv_move_status_05              CONSTANT VARCHAR2(2)   := '05';        -- ���ɕ񍐗L
    cv_move_status_06              CONSTANT VARCHAR2(2)   := '06';        -- ���o�ɕ񍐗L
    --
    -- �o�׎x���敪
    cv_shipping_shikyu_class_01    CONSTANT VARCHAR2(1)   := '1';         -- �o�׈˗�
    -- �����^�C�v
    cv_document_type_10            CONSTANT VARCHAR2(2)   := '10';        -- �o�׈˗�
    cv_document_type_20            CONSTANT VARCHAR2(2)   := '20';        -- �ړ�
    -- ���R�[�h�^�C�v
    cv_record_type_01              CONSTANT VARCHAR2(2)   := '10';         -- �w��
    cv_record_type_02              CONSTANT VARCHAR2(2)   := '20';         -- �o�Ɏ���
    cv_record_type_03              CONSTANT VARCHAR2(2)   := '30';         -- ���Ɏ���
    --
    cv_zero                        CONSTANT VARCHAR2(1)   := '0';         -- �[���l(VARCHAR2)
    cv_yes                         CONSTANT VARCHAR2(1)   := 'Y';         -- Y (YES_NO�敪)
    cv_no                          CONSTANT VARCHAR2(1)   := 'N';         -- N (YES_NO�敪)
    --
    ln_result_success              CONSTANT NUMBER        := 0;           -- 0 (����)
    ln_result_error                CONSTANT NUMBER        := 1;           -- 1 (�ُ�)
    --
    cv_mindate                     CONSTANT DATE
                                        := fnd_date.string_to_date('1900/01/01', gv_yyyymmdd);
                                                                          -- �ŏ����t
--
--
    -- *** ���[�J���ϐ� ***
    -- �G���[�ϐ�
    lv_err_cd             VARCHAR2(30);
    --
    ld_max_manufact_date           ic_lots_mst.attribute1%TYPE;           -- �ő吻���N����
    lv_parent_item_no              xxcmn_item_mst2_v.item_no%TYPE;        -- �e�i�ڃR�[�h
    --
    ld_max_ship_manufact_date      DATE;                                  -- �o�׎w�������N����
    ld_max_ship_arrival_date       xxwsh_order_headers_all.arrival_date%type;
                                                                          -- �ő咅�ד�(�o��)
    ld_max_rship_manufact_date     DATE;                                  -- �o�׎��ѐ����N����
    --
    ld_max_move_manufact_date      DATE;                                  -- �ړ��w�������N����
    ld_max_move_arrival_date       xxinv_mov_req_instr_headers.actual_arrival_date%type;
                                                                          -- �ő咅�ד�(�ړ�)
    ld_max_rmove_manufact_date     DATE;                                  -- �ړ����ѐ����N����
    --
    ld_max_onhand_manufact_date    DATE;                                  -- �莝�����N����
    --
    ld_check_manufact_date         DATE;                                  -- �`�F�b�N���t
    --
    ln_result                      NUMBER;                                -- ����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --
    /**********************************
     *  �p�����[�^�`�F�b�N(D-1)       *
     **********************************/
    -- �K�{���̓p�����[�^���`�F�b�N���܂�
    -- ���b�g�t�]�������
    IF   ( iv_lot_biz_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_ship_move_class_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    --
    -- �i�ڃR�[�h
    ELSIF( iv_item_no       IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_item_code_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    --
    -- ���b�gNo
    ELSIF( iv_lot_no         IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_lot_no_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    --
    -- �z����ID/���ɐ�ID
    ELSIF( iv_move_to_id    IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_move_to_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    END IF;
    --
    --
    -- ���̓p�����[�^�u���b�g�t�]������ʁv�̒l�`�F�b�N
    -- �l��1�A2�A5�A6�ł��邩�`�F�b�N
    IF ( iv_lot_biz_class NOT IN ( cv_ship_plan,
                                   cv_ship_result,
                                   cv_move_plan,
                                   cv_move_result )) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_lot_err
                                           );
      lv_err_cd := cv_xxwsh_in_pram_lot_err;
      RAISE global_api_expt;
    ELSE
    -- �l��1�A5�̏ꍇ�A�u�����v���Z�b�g����Ă��邩�`�F�b�N
      IF  ( ( iv_lot_biz_class IN ( cv_ship_plan, cv_move_plan ))
        AND ( iv_arrival_date  IS NULL )) THEN
        --
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_pram_arr_err
                                             );
        lv_err_cd := cv_xxwsh_in_pram_arr_err;
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    /**********************************
     *  �����N�����擾(D-2)           *
     **********************************/
    -- OPM���b�g�}�X�^���瓖�Y���b�g�̐����N�������擾
    BEGIN
      SELECT fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd )   -- �ő吻���N����
      INTO   ld_max_manufact_date
      FROM   ic_lots_mst              ilm,                             -- OPM���b�g�}�X�^
             xxcmn_item_mst2_v        ximv                             -- OPM�i�ڏ��VIEW2
      WHERE  ximv.item_no             = iv_item_no                     -- �i�ڃR�[�h
        AND  ximv.start_date_active  <= trunc( id_standard_date )
        AND  ximv.end_date_active    >= trunc( id_standard_date )
        AND  ilm.item_id              = ximv.item_id
        AND  ilm.lot_no               = iv_lot_no;                     -- ���b�gNo
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �擾�G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_no_lot_err,
                                              cv_tkn_lot_no,
                                              iv_lot_no);
        lv_err_cd := cv_xxwsh_in_no_lot_err;
      RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    --
    --
    /**********************************
     *  �e�i�ڎ擾(D-3)               *
     **********************************/
    -- OPM�i�ڃ}�X�^����e�i�ڃR�[�h���擾
    BEGIN
      SELECT ximv2.item_no                                             -- �i�ڃR�[�h(�e�i��)
      INTO   lv_parent_item_no
      FROM   xxcmn_item_mst2_v         ximv1,                          -- OPM�i�ڏ��VIEW2(�q)
             xxcmn_item_mst2_v         ximv2                           -- OPM�i�ڏ��VIEW2(�e)
      WHERE  ximv1.item_no             =  iv_item_no                   -- �i�ڃR�[�h
        AND  ximv1.start_date_active  <=  trunc( id_standard_date )
        AND  ximv1.end_date_active    >=  trunc( id_standard_date )
        AND  ximv2.item_id             =  ximv1.parent_item_id         -- �e�i��ID
        AND  ximv2.start_date_active  <=  trunc( id_standard_date )
        AND  ximv2.end_date_active    >=  trunc( id_standard_date );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �f�[�^�Ȃ��͏��O
        NULL;
      --
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    --
    /**********************************
    *  ���b�g�t�]������ʂ̔���       *
    **********************************/
    IF ( iv_lot_biz_class IN ( cv_ship_plan , cv_ship_result) ) THEN
    --
      /**********************************
       *  �������擾(�o��)(D-4)       *
       **********************************/
       -- 1. �o�׎w�����̎擾
      IF ( iv_lot_biz_class = cv_ship_plan ) THEN
        BEGIN
          SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ))
                                                                            -- �o�׎w�������N����
          INTO    ld_max_ship_manufact_date
          FROM    xxwsh_order_headers_all        xoha,                      -- �󒍃w�b�_�A�h�I��
                  xxwsh_order_lines_all          xola,                      -- �󒍖��׃A�h�I��
                  xxinv_mov_lot_details          xmld,                      -- �ړ����b�g�ڍ�
                  xxwsh_oe_transaction_types2_v  xottv,                     -- �󒍃^�C�v
                  ic_lots_mst                    ilm                        -- OPM���b�g�}�X�^
          WHERE   xoha.deliver_to_id             =  iv_move_to_id                -- �o�א�ID
            AND   NVL(xoha.latest_external_flag, cv_no)
                                                 =  cv_yes                       -- �ŐV�t���O
            AND   xoha.schedule_arrival_date    <=  iv_arrival_date              -- ����
            AND   xoha.req_status                =  cv_request_status_03         -- ���ߍς�
            AND   xottv.transaction_type_id      =  xoha.order_type_id           -- �󒍃^�C�vID
            AND   xottv.shipping_shikyu_class    =  cv_shipping_shikyu_class_01  -- �o�׈˗�
            AND   xottv.start_date_active       <=  trunc( id_standard_date )
            AND   ( (xottv.end_date_active      >=  trunc( id_standard_date ))
                  OR(xottv.end_date_active      IS  NULL ))
            AND   xola.order_header_id           =  xoha.order_header_id         -- �󒍃w�b�_ID
            AND   xola.shipping_item_code       IN  ( iv_item_no, lv_parent_item_no )
                                                                                 -- �i�ڃR�[�h
            AND   NVL( xola.delete_flag,  cv_no )
                                                <>  cv_yes                       -- �폜�t���O'Y'�ȊO
            AND   xmld.mov_line_id               =  xola.order_line_id           -- �󒍖���ID
            AND   xmld.document_type_code        =  cv_document_type_10          -- �����^�C�v
            AND   xmld.record_type_code          =  cv_record_type_01            -- ���R�[�h�^�C�v
            AND   ilm.lot_id                     =  xmld.lot_id                  -- OPM���b�gID
            AND   ilm.item_id                    =  xmld.item_id                 -- OPM�i��ID
            ;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
      --
      --
      -- 2-1. ���̓p�����[�^�ɍ��v����ő�̒��ד����擾
      BEGIN
        SELECT  MAX( xoha.arrival_date )                                    -- �ő咅�ד�
        INTO    ld_max_ship_arrival_date
        FROM    xxwsh_order_headers_all        xoha,                        -- �󒍃w�b�_�A�h�I��
                xxwsh_order_lines_all          xola,                        -- �󒍖��׃A�h�I��
                xxwsh_oe_transaction_types2_v  xottv                        -- �󒍃^�C�v
        WHERE   NVL ( xoha.result_deliver_to_id, xoha.deliver_to_id )
                                                 =  iv_move_to_id               -- �o�א�ID(����)
          AND   NVL(xoha.latest_external_flag, cv_no)
                                                 =  cv_yes                      -- �ŐV�t���O=Y
          AND   xoha.req_status                  =  cv_request_status_04        -- �o�׎��ьv���
          AND   xottv.transaction_type_id        =  xoha.order_type_id          -- �󒍃^�C�vID
          AND   xottv.shipping_shikyu_class      =  cv_shipping_shikyu_class_01 -- �o�׎x���敪
          AND   xottv.start_date_active         <=  trunc( id_standard_date )
          AND   (( xottv.end_date_active        >=  trunc( id_standard_date ))
                OR(xottv.end_date_active        IS  NULL ))
          AND   xola.order_header_id             =  xoha.order_header_id        -- �󒍃w�b�_ID
          AND   xola.shipping_item_code         IN  ( iv_item_no, lv_parent_item_no )  -- �o�וi��
          AND   NVL( xola.delete_flag, cv_no )  <>  cv_yes                      -- �폜�t���O'Y'�ȊO
          AND   xola.shipped_quantity            >  0                           -- �o�׎��ѐ���0�ȏ�
          ;
        EXCEPTION
          --
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
      END;
      --
      --
      -- 2-2. ��L�Ŏ擾�����ő咅�ד��ɕR�Â��̃��b�g�̍ő吻�������擾
      IF ( ld_max_ship_arrival_date IS NOT NULL ) THEN
        BEGIN
          SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ) )
          INTO    ld_max_rship_manufact_date
          FROM    xxwsh_order_headers_all        xoha,                      -- �󒍃w�b�_�A�h�I��
                  xxwsh_order_lines_all          xola,                      -- �󒍖��׃A�h�I��
                  xxinv_mov_lot_details          xmld,                      -- �ړ����b�g�ڍ�
                  xxwsh_oe_transaction_types2_v  xottv,                     -- �󒍃^�C�v
                  ic_lots_mst                    ilm                        -- OPM���b�g�}�X�^
          WHERE   NVL ( xoha.result_deliver_to_id, xoha.deliver_to_id )
                                                   =  iv_move_to_id               -- �o�א�ID(����)
            AND   trunc( xoha.schedule_arrival_date )
                                                   =  trunc( ld_max_ship_arrival_date ) -- �ő咅�ד�
            AND   NVL(xoha.latest_external_flag, cv_no)
                                                   =  cv_yes                      -- �ŐV�t���O=Y
            AND   xoha.req_status                  =  cv_request_status_04        -- �o�׎��ьv���
            AND   xottv.transaction_type_id        =  xoha.order_type_id          -- �󒍃^�C�vID
            AND   xottv.shipping_shikyu_class      =  cv_shipping_shikyu_class_01 -- �o�׈˗�
            AND   xottv.start_date_active         <=  trunc( id_standard_date )
            AND   (( xottv.end_date_active        >=  trunc( id_standard_date ))
                  OR(xottv.end_date_active        IS  NULL ))
            AND   xola.order_header_id             =  xoha.order_header_id        -- �󒍃w�b�_ID
            AND   xola.shipping_item_code         IN  ( iv_item_no, lv_parent_item_no )  -- �i�ڃR�[�h
            AND   NVL( xola.delete_flag, cv_no )  <>  cv_yes                      -- �폜�t���O'Y'�ȊO
            AND   xmld.mov_line_id                 =  xola.order_line_id          -- �󒍖���ID
            AND   xmld.document_type_code          =  cv_document_type_10         -- �����^�C�v
            AND   xmld.record_type_code            =  cv_record_type_02           -- ���R�[�h�^�C�v
            AND   ilm.lot_id                       =  xmld.lot_id                 -- OPM���b�gID
            AND   ilm.item_id                      =  xmld.item_id                -- OPM�i��ID
            ;
          EXCEPTION
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
        END;
      END IF;
      --
    --
    ELSE
      /**********************************
       *  �������擾(�ړ��E�݌�)(D-5) *
       **********************************/
      --
      -- 3.�ړ��w�����̎擾
      IF ( iv_lot_biz_class = cv_move_plan ) THEN
        --
        BEGIN
          SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ) )
                                                                -- �ړ��w�������N����
          INTO    ld_max_move_manufact_date
          FROM    xxinv_mov_req_instr_headers    xmrih,         -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
                  xxinv_mov_req_instr_lines      xmril,         -- �ړ��˗�/�w�����ׁi�A�h�I���j
                  xxinv_mov_lot_details          xmld,          -- �ړ����b�g�ڍ�
                  ic_lots_mst                    ilm            -- OPM���b�g�}�X�^
          WHERE   xmrih.ship_to_locat_id    =  iv_move_to_id                   -- ���ɐ�ID
            AND   xmrih.comp_actual_flg     =  cv_no                           -- ���ьv��σt���O
            AND   xmrih.status             IN( cv_move_status_03,
                                               cv_move_status_04 )             -- �X�e�[�^�X
            AND   xmrih.schedule_arrival_date
                                           <=  iv_arrival_date                 -- ����
            AND   xmril.mov_hdr_id          =  xmrih.mov_hdr_id                -- �ړ��w�b�_ID
            AND   xmril.item_code          IN( iv_item_no,
                                               lv_parent_item_no )             -- �i�ڃR�[�h
            AND   xmril.delete_flg          =  cv_no                           -- ����t���O
            AND   xmld.mov_line_id          =  xmril.mov_line_id               -- �ړ�����ID
            AND   xmld.document_type_code   =  cv_document_type_20             -- �����^�C�v
            AND   ((( xmrih.status  = cv_move_status_03 )                      -- ���R�[�h�^�C�v
                    AND ( xmld.record_type_code = cv_record_type_01 ))             -- �w��
                  OR(( xmrih.status = cv_move_status_04 )
                    AND ( xmld.record_type_code = cv_record_type_02 )))            -- �o�Ɏ���
            AND   xmld.actual_quantity      >  0                               -- ���ѐ���
            AND   ilm.lot_id                =  xmld.lot_id                     -- OPM���b�gID
            AND   ilm.item_id               =  xmld.item_id                    -- OPM�i��ID
            ;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      END IF;
      --
      --
      -- 4. �莝���ʏ��̎擾
      BEGIN
        SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ) )
        INTO    ld_max_onhand_manufact_date
        FROM    ic_loct_inv              ili,                      -- OPM�莝����
                ic_lots_mst              ilm,                      -- OPM���b�g�}�X�^
                xxcmn_item_mst2_v        ximv,                     -- OPM�i�ڏ��VIEW2
                xxcmn_item_locations2_v  xilv                      -- OPM�ۊǏꏊ���VIEW2
        WHERE   ximv.item_no  IN( iv_item_no, lv_parent_item_no )  -- �i�ڃR�[�h
          AND   xilv.inventory_location_id = iv_move_to_id         -- ���ɐ�ID
          AND   ili.item_id                =  ximv.item_id         -- OPM�i��ID
          AND   ili.location               =  xilv.segment1        -- �ۊǑq�ɃR�[�h
          AND   ilm.lot_id                 =  ili.lot_id           -- ���b�gID
          AND   ilm.item_id                =  ili.item_id          -- OPM�i��ID
          ;
      EXCEPTION
        WHEN  OTHERS THEN
          RAISE global_api_others_expt;
      END;
      --
      --
      -- 5. �ړ����я��̎擾
      BEGIN
        SELECT  MAX( fnd_date.string_to_date( ilm.attribute1, gv_yyyymmdd ) )
        INTO    ld_max_rmove_manufact_date
        FROM    xxinv_mov_req_instr_headers    xmrih,         -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
                xxinv_mov_req_instr_lines      xmril,         -- �ړ��˗�/�w�����ׁi�A�h�I���j
                xxinv_mov_lot_details          xmld,          -- �ړ����b�g�ڍ�
                ic_lots_mst                    ilm            -- OPM���b�g�}�X�^
        WHERE   xmrih.ship_to_locat_id    =  iv_move_to_id
          AND   xmrih.comp_actual_flg     =  cv_no                            -- ���ьv��σt���O
          AND   xmrih.status             IN( cv_move_status_05,
                                             cv_move_status_06 )              -- �X�e�[�^�X
          AND   xmril.mov_hdr_id          =  xmrih.mov_hdr_id                 -- �ړ��w�b�_ID
          AND   xmril.item_code          IN( iv_item_no, lv_parent_item_no )  -- �i�ڃR�[�h
          AND   xmril.delete_flg          =  cv_no                            -- ����t���O
          AND   xmld.mov_line_id          =  xmril.mov_line_id                -- �ړ�����ID
          AND   xmld.document_type_code   =  cv_document_type_20              -- �����^�C�v
          AND   xmld.record_type_code     =  cv_record_type_03                -- ���R�[�h�^�C�v
          AND   xmld.actual_quantity      >  0                                -- ���ѐ���
          AND   ilm.lot_id                =  xmld.lot_id                      -- OPM���b�gID
          AND   ilm.item_id               =  xmld.item_id                     -- OPM�i��ID
          ;
      EXCEPTION
        WHEN  NO_DATA_FOUND THEN
          -- �f�[�^�Ȃ��͏��O
          NULL;
          --
        WHEN  OTHERS THEN
          RAISE global_api_others_expt;
      END;
      --
    END IF;
    --
    /**********************************
     *  ���b�g�t�]���菈��(D-6)       *
     **********************************/
    -- ���b�g�t�]�Ώۂ̓��t���Z�o
    CASE iv_lot_biz_class
      -- ���b�g�t�]������ʂ��u1�v�̏ꍇ
      WHEN ( cv_ship_plan  ) THEN
        -- �u�o�׎w�������N�����v�u�o�׎��ѐ����N�����v�̂����ő�
        ld_check_manufact_date
                 := GREATEST( NVL(ld_max_ship_manufact_date,  cv_mindate),
                              NVL(ld_max_rship_manufact_date, cv_mindate) );
        --
        --
      -- ���b�g�t�]������ʂ��u2�v�̏ꍇ
      WHEN ( cv_ship_result ) THEN
        ld_check_manufact_date := ld_max_rship_manufact_date;
        --
        --
      -- ���b�g�t�]������ʂ��u5�v�̏ꍇ
      WHEN ( cv_move_plan   ) THEN
        -- �u�ړ��w�������N�����v�u�ړ����ѐ����N�����v�u�莝�����N�����v�̂����ő�
        ld_check_manufact_date
                 := GREATEST( NVL(ld_max_move_manufact_date,   cv_mindate),
                              NVL(ld_max_rmove_manufact_date,  cv_mindate),
                              NVL(ld_max_onhand_manufact_date, cv_mindate) );
        --
        --
      -- ���b�g�t�]������ʂ��u6�v�̏ꍇ
      WHEN ( cv_move_result ) THEN
        -- �ړ����ѐ����N�����v�u�莝�����N�����v�̂����ő�
        ld_check_manufact_date
                 := GREATEST( NVL(ld_max_rmove_manufact_date  ,cv_mindate),
                              NVL(ld_max_onhand_manufact_date ,cv_mindate) );
    END CASE;
    --
    -- �u�`�F�b�N���t�v�� �u�ő吻���N�����v�Ȃ�΁A���b�g�t�]
    IF ( ( ld_check_manufact_date <= ld_max_manufact_date )
      OR ( ld_check_manufact_date IS NULL                ) ) THEN
      on_result         :=  ln_result_success;                     -- ��������
      on_reversal_date  :=  NULL;                                  -- �t�]���t
    ELSE
      on_result         :=  ln_result_error;                       -- ��������
      on_reversal_date  :=  ld_check_manufact_date;                -- �t�]���t
    END IF;
      --
    /**********************************
     *  OUT�p�����[�^�Z�b�g(D-7)      *
     **********************************/
    --
    ov_retcode                  := gv_status_normal;   -- ���^�[���R�[�h
    ov_errmsg_code              := NULL;               -- �G���[���b�Z�[�W�R�[�h
    ov_errmsg                   := NULL;               -- �G���[���b�Z�[�W
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg      := lv_errmsg;
      ov_errmsg_code := lv_err_cd;
      ov_retcode     := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_lot_reversal;
--
  /**********************************************************************************
   * Procedure Name   : check_fresh_condition
   * Description      : �N�x�����`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_fresh_condition(
    iv_move_to_id                 IN  NUMBER,                         -- 1.�z����ID
    iv_lot_id                     IN  ic_lots_mst.lot_id%TYPE,        -- 2.���b�gId
    iv_arrival_date               IN  DATE,                           -- 3.���ח\���
    id_standard_date              IN  DATE  DEFAULT SYSDATE,          -- 4.���(�K�p�����)
    ov_retcode                    OUT NOCOPY VARCHAR2,                -- 5.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                -- 6.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                -- 7.�G���[���b�Z�[�W
    on_result                     OUT NOCOPY NUMBER,                  -- 8.��������
    od_standard_date              OUT NOCOPY DATE                     -- 9.����t
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_fresh_condition'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�WID
    cv_xxwsh_in_pram_set_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-12701'; -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
    cv_xxwsh_lot_info_err          CONSTANT VARCHAR2(100) := 'APP-XXWSH-12702'; -- ���b�g���Ȃ��G���[���b�Z�[�W
    cv_xxwsh_in_pram_base_val_err  CONSTANT VARCHAR2(100) := 'APP-XXWSH-12703'; -- ��l�[���G���[���b�Z�[�W
    cv_xxwsh_not_fresh_condition   CONSTANT VARCHAR2(100) := 'APP-XXWSH-12704'; -- �N�x�����擾�G���[���b�Z�[�W
    cv_xxwsh_fresh_condition_err   CONSTANT VARCHAR2(100) := 'APP-XXWSH-12705'; -- �N�x�����s���G���[���b�Z�[�W
    cv_xxwsh_not_best_before_date  CONSTANT VARCHAR2(100) := 'APP-XXWSH-12706'; -- �ܖ������Ȃ��G���[���b�Z�[�W
    cv_xxwsh_not_manufact_date     CONSTANT VARCHAR2(100) := 'APP-XXWSH-12707'; -- �����N�����Ȃ��G���[���b�Z�[�W
    cv_xxwsh_date_style_err        CONSTANT VARCHAR2(100) := 'APP-XXWSH-12708'; -- ���t�����G���[���b�Z�[�W
    -- �g�[�N��
    cv_tkn_in_parm                 CONSTANT VARCHAR2(30)  := 'in_param';
    cv_tkn_deliver_to_id           CONSTANT VARCHAR2(30)  := 'deliver_to_id';
    cv_tkn_lot_no                  CONSTANT VARCHAR2(30)  := 'lot_no';
    cv_tkn_lot_id                  CONSTANT VARCHAR2(30)  := 'lot_id';
    cv_flesh_code                  CONSTANT VARCHAR2(30)  := 'fresh_code';
    cv_style_name                  CONSTANT VARCHAR2(30)  := 'style_name';
    -- �g�[�N���Z�b�g�l
    cv_move_to_id_char             CONSTANT VARCHAR2(30)  := '�z����ID';
    cv_lot_no_char                 CONSTANT VARCHAR2(30)  := '���b�gNo';
    cv_lot_id_char                 CONSTANT VARCHAR2(30)  := '���b�gId';
    cv_arrival_date_char           CONSTANT VARCHAR2(30)  := '���ח\���';
    cv_freshness_class0_char       CONSTANT VARCHAR2(30)  := '���';
    cv_freshness_class1_char       CONSTANT VARCHAR2(30)  := '�ܖ������';
    cv_freshness_class2_char       CONSTANT VARCHAR2(30)  := '�������';
    cv_manufact_date_char          CONSTANT VARCHAR2(30)  := '�����N����';
    cv_limit_exp_date_char         CONSTANT VARCHAR2(30)  := '�ܖ�����';
    --
    -- �N�C�b�N�R�[�h�^�C�v�u�N�x�����v
    cv_lookup_fressness_condition  CONSTANT VARCHAR2(30)  := 'XXCMN_FRESHNESS_CONDITION';
    -- �N�x�����敪
    lv_freshness_class0            CONSTANT VARCHAR2(1)   :=  '0';   -- ���
    lv_freshness_class1            CONSTANT VARCHAR2(1)   :=  '1';   -- �ܖ������
    lv_freshness_class2            CONSTANT VARCHAR2(1)   :=  '2';   -- �������
    --
    -- �������ʒ萔
    ln_result_success              CONSTANT NUMBER        := 0;      -- 0 (����)
    ln_result_error                CONSTANT NUMBER        := 1;      -- 1 (�ُ�)
--
    -- *** ���[�J���ϐ� ***
    -- �G���[�ϐ�
    lv_err_cd                      VARCHAR2(30);
    -- �N�x����
    lv_freshness_class             VARCHAR2(2);                      -- �N�x�����敪
    ln_freshness_base_value        NUMBER;                           -- �N�x������l
    ln_freshness_adjust_value      NUMBER;                           -- �N�x���������l
    -- �ܖ�����
    ld_manufact_date               DATE;                             -- �����N����
    ld_limit_expiration_date       DATE;                             -- �ܖ�����
    ln_expiration_days             NUMBER;                           -- �ܖ�����
    -- �ܖ�����(�ꎞ�i�[�p)
    lv_manufact_date_str           VARCHAR2(150);                    -- �����N����
    lv_limit_exp_date_str          VARCHAR2(150);                    -- �ܖ�����
    --
    ln_base_days                   NUMBER;                           -- �����(��)
    ld_freshness_base_date         DATE;                             -- �N�x�������
    lv_lot_no                      ic_lots_mst.lot_no%TYPE;          -- ���b�gNo
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    expiration_days_zero_expt      EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --
    /********************************************
     *  �p�����[�^�`�F�b�N(E-1)                 *
     ********************************************/
    -- �K�{���̓p�����[�^���`�F�b�N���܂�
    -- �z����ID
    IF   ( iv_move_to_id IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_move_to_id_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    -- ���b�gId
    ELSIF( iv_lot_id         IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_lot_id_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    -- ���ח\���
    ELSIF( iv_arrival_date   IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_pram_set_err,
                                            cv_tkn_in_parm,
                                            cv_arrival_date_char);
      lv_err_cd := cv_xxwsh_in_pram_set_err;
      RAISE global_api_expt;
    END IF;
    --
    --
    /********************************************
     *  �N�x�����擾(E-2)                       *
     ********************************************/
    -- �N�x��������ёN�x�����t�����̎擾
    BEGIN
      SELECT xlv.attribute1,
             TO_NUMBER( xlv.attribute2 ),
             TO_NUMBER( xlv.attribute3 )
      INTO   lv_freshness_class,
             ln_freshness_base_value,
             ln_freshness_adjust_value
      FROM   xxcmn_cust_acct_sites2_v  xcasv,              -- �ڋq�T�C�g���VIEW2
             xxcmn_lookup_values2_v    xlv                 -- �N�C�b�N�R�[�h���VIEW2
      WHERE  xcasv.party_site_id       =  iv_move_to_id                 -- �z����ID(�p�[�e�B�T�C�gID)
        AND  xcasv.start_date_active  <=  trunc( id_standard_date )
        AND  xcasv.end_date_active    >=  trunc( id_standard_date )
        AND  xlv.lookup_type           =  cv_lookup_fressness_condition
        AND  xlv.lookup_code           =  xcasv.freshness_condition
        AND  (( xlv.start_date_active  <=  trunc( id_standard_date ))
          OR  ( xlv.start_date_active  IS NULL  ))
        AND  (( xlv.end_date_active    >=  trunc( id_standard_date ))
          OR  ( xlv.end_date_active    IS NULL  ));
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_not_fresh_condition,
                                              cv_tkn_deliver_to_id,
                                              iv_move_to_id);
        lv_err_cd := cv_xxwsh_not_fresh_condition;
        RAISE global_api_expt;
      WHEN OTHERS        THEN
        RAISE global_api_expt;
    END;
    -- �N�x�����敪���K��l�ȊO�܂���NULL�̏ꍇ
    IF ( lv_freshness_class NOT IN( lv_freshness_class0,
                                    lv_freshness_class1,
                                    lv_freshness_class2  ) OR
         lv_freshness_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_fresh_condition_err,
                                            cv_tkn_deliver_to_id,
                                            iv_move_to_id);
      lv_err_cd := cv_xxwsh_fresh_condition_err;
      RAISE global_api_expt;
    END IF;
    --
    -- �ܖ����������l��0�܂���NULL
    IF ( lv_freshness_class = lv_freshness_class1 ) THEN
      IF (( ln_freshness_base_value  = 0    )
        OR( ln_freshness_base_value IS NULL )) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_pram_base_val_err);
        lv_err_cd := cv_xxwsh_in_pram_base_val_err;
        RAISE global_api_others_expt;
      END IF;
    END IF;
    --
    /********************************************
     *  �����N�����A�ܖ������擾 (E-3)          *
     ********************************************/
    -- �u���b�gNo�v�ɕR�Â��i�ڂ̏ܖ����Ԃ��擾
    BEGIN
      SELECT ilm.lot_no,                                           -- ���b�gNo
             ilm.attribute1,                                       -- �����N����
             ilm.attribute3,                                       -- �ܖ�����
             ximv.expiration_day                                   -- �ܖ�����
      INTO   lv_lot_no,
             lv_manufact_date_str,
             lv_limit_exp_date_str,
             ln_expiration_days
      FROM   ic_lots_mst       ilm,                                -- OPM���b�g�}�X�^
             xxcmn_item_mst2_v ximv                                -- OPM�i�ڏ��VIEW2
      WHERE  ilm.lot_id               =  iv_lot_id                 -- ���b�gId
        AND  ximv.item_id             =  ilm.item_id               -- �i��ID
        AND  ximv.start_date_active  <=  trunc( id_standard_date )
        AND  ximv.end_date_active    >=  trunc( id_standard_date );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_lot_info_err,
                                              cv_tkn_lot_id,
                                              iv_lot_id);
        lv_err_cd := cv_xxwsh_lot_info_err;
        RAISE global_api_expt;
      WHEN OTHERS        THEN
        RAISE global_api_others_expt;
    END;
    --
    -- �����^������t�^��
    ld_manufact_date
             := fnd_date.string_to_date( lv_manufact_date_str,  gv_yyyymmdd ); -- �����N����
    ld_limit_expiration_date
             := fnd_date.string_to_date( lv_limit_exp_date_str, gv_yyyymmdd ); -- �ܖ�����
    -- �����G���[
    IF   (( ld_manufact_date         IS NULL     )
      AND ( lv_manufact_date_str     IS NOT NULL )) THEN
      --
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_date_style_err,
                                            cv_style_name,
                                            cv_manufact_date_char,
                                            cv_tkn_lot_no,
                                            lv_lot_no);
      lv_err_cd := cv_xxwsh_date_style_err;
      RAISE global_api_expt;
      --
    ELSIF(( ld_limit_expiration_date IS NULL     )
      AND ( lv_limit_exp_date_str    IS NOT NULL )) THEN
      --
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_date_style_err,
                                            cv_style_name,
                                            cv_limit_exp_date_char,
                                            cv_tkn_lot_no,
                                            lv_lot_no);
      lv_err_cd := cv_xxwsh_date_style_err;
      RAISE global_api_expt;
      --
    END IF;
    --
    -- �ܖ����ԁ��[���̏ꍇ
    IF ( ln_expiration_days = 0 ) THEN
      RAISE expiration_days_zero_expt;
    END IF;
    --
    -- NULL�`�F�b�N
    --�u�N�x�����敪�v���u1(�ܖ������)�v
    IF ( lv_freshness_class = lv_freshness_class1 ) THEN
      --
      -- �u�ܖ������v��NULL
      IF ( lv_limit_exp_date_str  IS NULL ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_not_best_before_date,
                                              cv_flesh_code,
                                              cv_freshness_class1_char,
                                              cv_tkn_lot_no,
                                              lv_lot_no);
        lv_err_cd := cv_xxwsh_not_best_before_date;
        RAISE global_api_expt;
      --
      -- �u�������v��NULL
      ELSIF ( lv_manufact_date_str IS NULL ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_not_manufact_date,
                                              cv_flesh_code,
                                              cv_freshness_class1_char,
                                              cv_tkn_lot_no,
                                              lv_lot_no);
        lv_err_cd := cv_xxwsh_not_manufact_date;
        RAISE global_api_expt;
      --
      END IF;
    --
    --�u�N�x�����敪�v���u2(�������)�v
    ELSIF ( lv_freshness_class = lv_freshness_class2 ) THEN
      -- �u�������v��NULL
      IF (lv_manufact_date_str IS NULL ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_not_manufact_date,
                                              cv_flesh_code,
                                              cv_freshness_class2_char,
                                              cv_tkn_lot_no,
                                              lv_lot_no);
        lv_err_cd := cv_xxwsh_not_fresh_condition;
        RAISE global_api_expt;
      END IF;
    --
    --�u�N�x�����敪�v���u0(���)�v
    ELSE
      -- �u�ܖ������v��NULL
      IF ( lv_limit_exp_date_str  IS NULL ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_not_best_before_date,
                                              cv_flesh_code,
                                              cv_freshness_class0_char,
                                              cv_tkn_lot_no,
                                              lv_lot_no);
        lv_err_cd := cv_xxwsh_not_best_before_date;
        RAISE global_api_expt;
      END IF;
      --
    END IF;
    --
    --
    /********************************************
     *  �N�x��������̎Z�o                    *
     ********************************************/
    -- �N�x�����敪�ɂ�菈����U�蕪���܂�
    --
    CASE lv_freshness_class
      /********************************************
       *  �N�x��������̎Z�o(�ܖ������)(E-4) *
       ********************************************/
      WHEN lv_freshness_class1 THEN
        ln_base_days
            := TRUNC( ( ld_limit_expiration_date - ld_manufact_date ) / ln_freshness_base_value );
        ld_freshness_base_date
            := ld_manufact_date + ln_base_days + NVL( ln_freshness_adjust_value, 0);
      --
      /********************************************
       *  �N�x��������̎Z�o(�������)(E-5)   *
       ********************************************/
      WHEN lv_freshness_class2 THEN
        ld_freshness_base_date
            := ld_manufact_date
             + NVL( ln_freshness_base_value  , 0 )
             + NVL( ln_freshness_adjust_value, 0 );
      --
      /********************************************
       *  �N�x��������̎Z�o(���)(E-6)         *
       ********************************************/
      ELSE
        ld_freshness_base_date
            := ld_limit_expiration_date
             + NVL( ln_freshness_base_value  , 0 )
             + NVL( ln_freshness_adjust_value, 0 );
      --
    END CASE;
    --
    /********************************************
     *  OUT�p�����[�^�Z�b�g(E-7)                *
     ********************************************/
    --  �u�N�x��������v�����̓p�����[�^�u���ח\����v�F�N�x�����G���[
    IF ( ld_freshness_base_date >= iv_arrival_date ) THEN
      on_result           :=  ln_result_success;                    -- ��������
      od_standard_date    :=  NULL;                                 -- ����t
    ELSE
      on_result           :=  ln_result_error;                      -- ��������
      od_standard_date    :=  ld_freshness_base_date;               -- ����t
    END IF;
    --
     ov_retcode      := gv_status_normal;   -- ���^�[���R�[�h
     ov_errmsg_code  := NULL;               -- �G���[���b�Z�[�W�R�[�h
     ov_errmsg       := NULL;               -- �G���[���b�Z�[�W
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    --
    WHEN expiration_days_zero_expt THEN
     on_result          :=  ln_result_success;  -- ��������
     od_standard_date   :=  NULL;               -- ����t
     ov_retcode         :=  gv_status_normal;   -- ���^�[���R�[�h
     ov_errmsg_code     :=  NULL;               -- �G���[���b�Z�[�W�R�[�h
     ov_errmsg          :=  NULL;               -- �G���[���b�Z�[�W
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg      := lv_errmsg;
      ov_errmsg_code := lv_err_cd;
      ov_retcode     := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_fresh_condition;
--
  /**********************************************************************************
   * Procedure Name   : calc_lead_time
   * Description      : ���[�h�^�C���Z�o
   ***********************************************************************************/
  PROCEDURE calc_lead_time(
    iv_code_class1                IN  xxcmn_ship_methods.code_class1%TYPE,                 -- 1.�R�[�h�敪FROM
    iv_entering_despatching_code1 IN  xxcmn_ship_methods.entering_despatching_code1%TYPE,  -- 2.���o�ɏꏊ�R�[�hFROM
    iv_code_class2                IN  xxcmn_ship_methods.code_class2%TYPE,                 -- 3.�R�[�h�敪TO
    iv_entering_despatching_code2 IN  xxcmn_ship_methods.entering_despatching_code2%TYPE,  -- 4.���o�ɏꏊ�R�[�hTO
    iv_prod_class                 IN  xxcmn_item_categories_v.segment1%TYPE,               -- 5.���i�敪
    in_transaction_type_id        IN  xxwsh_oe_transaction_types_v.transaction_type_id%type, -- 6.�o�Ɍ`��ID
    id_standard_date              IN  DATE  DEFAULT SYSDATE,                               -- 7.���(�K�p�����)
    ov_retcode                    OUT NOCOPY VARCHAR2,                                     -- 8.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                                     -- 9.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                                     -- 10.�G���[���b�Z�[�W
    on_lead_time                  OUT NOCOPY NUMBER,                                       -- 11.���Y����LT�^����ύXLT
    on_delivery_lt                OUT NOCOPY NUMBER                                        -- 12.�z��LT
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_lead_time'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�WID
    cv_xxwsh_in_prod_class_err     CONSTANT VARCHAR2(100) := 'APP-XXWSH-12751';  -- ���̓p�����[�^�u���i�敪�v�s��
    cv_xxwsh_in_param_set_err      CONSTANT VARCHAR2(100) := 'APP-XXWSH-12752';  -- ���̓p�����[�^�s��
    cv_xxwsh_no_data_found_err     CONSTANT VARCHAR2(100) := 'APP-XXWSH-12753';  -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
    cv_xxwsh_get_prof_err          CONSTANT VARCHAR2(100) := 'APP-XXWSH-12754';  -- �v���t�@�C���擾�G���[���b�Z�[�W
    -- �g�[�N��
    cv_tkn_prof_name               CONSTANT VARCHAR2(100) := 'PROF_NAME';
    cv_tkn_in_parm                 CONSTANT VARCHAR2(100) := 'IN_PARAM';
    cv_tkn_code_kbn_from           CONSTANT VARCHAR2(100) := 'CODE_KBN_FROM';
    cv_tkn_nsbash_from             CONSTANT VARCHAR2(100) := 'NSBASH_FROM';
    cv_tkn_code_kbn_to             CONSTANT VARCHAR2(100) := 'CODE_KBN_TO';
    cv_tkn_nsbash_to               CONSTANT VARCHAR2(100) := 'NSBASH_TO';
    cv_tkn_item_class              CONSTANT VARCHAR2(100) := 'ITEM_CLASS';
    -- �g�[�N���Z�b�g�l
    cv_code_class1_char            CONSTANT VARCHAR2(100) := '�R�[�h�敪From';
    cv_entering_despatch_cd1_char  CONSTANT VARCHAR2(100) := '���o�ɏꏊFrom';
    cv_code_class2_char            CONSTANT VARCHAR2(100) := '�R�[�h�敪To';
    cv_entering_despatch_cd2_char  CONSTANT VARCHAR2(100) := '���o�ɏꏊTo';
    cv_prod_class_char             CONSTANT VARCHAR2(100) := '���i�敪';
    cv_qty_char                    CONSTANT VARCHAR2(100) := '����';
--
    -- ���i�敪
    cv_prod_class_leaf             CONSTANT VARCHAR2(1)   := '1';  -- ���[�t
    cv_prod_class_drink            CONSTANT VARCHAR2(1)   := '2';  -- �h�����N
--
    -- �ڋq�敪
    cv_cust_class_base             CONSTANT VARCHAR2(1)   := '1';  -- ���_
    cv_cust_class_deliver          CONSTANT VARCHAR2(1)   := '9';  -- �z����
--
    -- �v���t�@�C��
    cv_prof_tran_type_plan         CONSTANT VARCHAR2(30)  := 'XXWSH_TRAN_TYPE_PLAN'; -- XXWSH:�o�Ɍ`��_����v��
--
    -- *** ���[�J���ϐ� ***
    -- �G���[�ϐ�
    lv_err_cd                      VARCHAR2(30);
    --�v���t�@�C���l�擾
    lv_tran_type_plan               fnd_profile_option_values.profile_option_value%TYPE;
    --
    ln_delivery_lead_time           xxcmn_delivery_lt2_v.delivery_lead_time%TYPE;
    ln_drink_lead_time_day          xxcmn_delivery_lt2_v.drink_lead_time_day%TYPE;
    ln_leaf_lead_time_day           xxcmn_delivery_lt2_v.leaf_lead_time_day%TYPE;
    ln_receipt_chg_lead_time_day    xxcmn_delivery_lt2_v.receipt_change_lead_time_day%TYPE;
    --
    ln_tran_cnt                    NUMBER;
    ln_no_data_flag                VARCHAR2(1) DEFAULT '0';
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    /*************************************
     *  �v���t�@�C���擾(F-1)            *
     *************************************/
    --
    -- XXWSH:�o�Ɍ`��_����v��
    lv_tran_type_plan    :=  fnd_profile.value( cv_prof_tran_type_plan );
    --
    -- �G���[����
    -- �uXXWSH:�o�Ɍ`��_����v��v�擾���s
    IF ( lv_tran_type_plan    IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_get_prof_err,
                                            cv_tkn_prof_name,
                                            cv_prof_tran_type_plan);
      lv_err_cd := cv_xxwsh_get_prof_err;
      RAISE global_api_expt;
    END IF;
    --
    /*************************************
     *  ���̓p�����[�^�`�F�b�N(F-2)      *
     *************************************/
    -- �R�[�h�敪From
    IF ( iv_code_class1  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_code_class1_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- ���o�ɏꏊFrom
    ELSIF ( iv_entering_despatching_code1  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_entering_despatch_cd1_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- �R�[�h�敪To
    ELSIF ( iv_code_class2  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_code_class2_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- ���o�ɏꏊTo
    ELSIF ( iv_entering_despatching_code2  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_entering_despatch_cd2_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    -- ���i�敪
    ELSIF ( iv_prod_class  IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_param_set_err,
                                            cv_tkn_in_parm,
                                            cv_prod_class_char);
      lv_err_cd := cv_xxwsh_in_param_set_err;
      RAISE global_api_expt;
    --
    -- �u���i�敪�v�ɁA�P�i���[�t�j�A�Q�i�h�����N�j�ȊO���Z�b�g����Ă��Ȃ���
    ELSIF ( iv_prod_class NOT IN ( cv_prod_class_leaf ,cv_prod_class_drink ) ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                            cv_xxwsh_in_prod_class_err);
      lv_err_cd := cv_xxwsh_in_prod_class_err;
      RAISE global_api_expt;
    --
    END IF;
    --
    /*************************************
     *  �֘A���ڎ擾����(F-3)            *
     *************************************/
     -- ���̓p�����[�^�u�o�Ɍ`��ID�v����󒍃^�C�v���u����ύX�v���ۂ����`�F�b�N���܂��B
     BEGIN
       SELECT  COUNT(*)
       INTO    ln_tran_cnt
       FROM    xxwsh_oe_transaction_types2_v xottv
       WHERE   xottv.transaction_type_id   =  in_transaction_type_id
         AND   xottv.transaction_type_name =  lv_tran_type_plan
         AND   rownum = 1;
     EXCEPTION
       WHEN OTHERS THEN
         RAISE global_api_others_expt;
     END;
     --
    /*************************************
     *  �z��L/T�A�h�I����񒊏o(F-4)     *
     *************************************/
     BEGIN
       SELECT  xdlv.delivery_lead_time,            -- �z�����[�h�^�C��
               xdlv.drink_lead_time_day,           -- �h�����N���Y����LT
               xdlv.leaf_lead_time_day,            -- ���[�t���Y����LT
               xdlv.receipt_change_lead_time_day   -- ����ύXLT
       INTO    ln_delivery_lead_time,
               ln_drink_lead_time_day,
               ln_leaf_lead_time_day,
               ln_receipt_chg_lead_time_day
       FROM    xxcmn_delivery_lt2_v xdlv
       WHERE   xdlv.code_class1                 =  iv_code_class1                 -- �R�[�h�敪From
         AND   xdlv.entering_despatching_code1  =  iv_entering_despatching_code1  -- ���o�ɏꏊFrom
         AND   xdlv.code_class2                 =  iv_code_class2                 -- �R�[�h�敪To
         AND   xdlv.entering_despatching_code2  =  iv_entering_despatching_code2  -- ���o�ɏꏊTo
         AND   xdlv.lt_start_date_active       <=  trunc( id_standard_date )
         AND   xdlv.lt_end_date_active         >=  trunc( id_standard_date )
       GROUP BY
         xdlv.delivery_lead_time,
         xdlv.drink_lead_time_day,
         xdlv.leaf_lead_time_day,
         xdlv.receipt_change_lead_time_day;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         --�R�[�h�敪To���u9�v�̏ꍇ
         IF ( iv_code_class2 = cv_cust_class_deliver ) THEN
           ln_no_data_flag := '1';
         ELSE
           lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                                 cv_xxwsh_no_data_found_err,
                                                 cv_tkn_code_kbn_from,
                                                 iv_code_class1,
                                                 cv_tkn_nsbash_from,
                                                 iv_entering_despatching_code1,
                                                 cv_tkn_code_kbn_to,
                                                 iv_code_class2,
                                                 cv_tkn_nsbash_to,
                                                 iv_entering_despatching_code2,
                                                 cv_tkn_item_class,
                                                 iv_prod_class );
           lv_err_cd := cv_xxwsh_no_data_found_err;
           RAISE global_api_expt;
         END IF;
       WHEN OTHERS THEN
         RAISE global_api_others_expt;
     END;
--
     IF ( ln_no_data_flag = '1' ) THEN
       BEGIN
         SELECT  xdlv.delivery_lead_time,            -- �z�����[�h�^�C��
                 xdlv.drink_lead_time_day,           -- �h�����N���Y����LT
                 xdlv.leaf_lead_time_day,            -- ���[�t���Y����LT
                 xdlv.receipt_change_lead_time_day   -- ����ύXLT
         INTO    ln_delivery_lead_time,
                 ln_drink_lead_time_day,
                 ln_leaf_lead_time_day,
                 ln_receipt_chg_lead_time_day
         FROM    xxcmn_delivery_lt2_v     xdlv,
                 xxcmn_cust_acct_sites2_v xcasv
         WHERE   xcasv.ship_to_no                 =  iv_entering_despatching_code2
           AND   xdlv.code_class1                 =  iv_code_class1
           AND   xdlv.entering_despatching_code1  =  iv_entering_despatching_code1
           AND   xdlv.code_class2                 =  cv_cust_class_base
           AND   xdlv.entering_despatching_code2  =  xcasv.base_code
           AND   xdlv.lt_start_date_active       <=  trunc( id_standard_date )
           AND   xdlv.lt_end_date_active         >=  trunc( id_standard_date )
       GROUP BY
         xdlv.delivery_lead_time,
         xdlv.drink_lead_time_day,
         xdlv.leaf_lead_time_day,
         xdlv.receipt_change_lead_time_day;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
           lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                                 cv_xxwsh_no_data_found_err,
                                                 cv_tkn_code_kbn_from,
                                                 iv_code_class1,
                                                 cv_tkn_nsbash_from,
                                                 iv_entering_despatching_code1,
                                                 cv_tkn_code_kbn_to,
                                                 iv_code_class2,
                                                 cv_tkn_nsbash_to,
                                                 iv_entering_despatching_code2,
                                                 cv_tkn_item_class,
                                                 iv_prod_class );
           lv_err_cd := cv_xxwsh_no_data_found_err;
           RAISE global_api_expt;
         WHEN OTHERS THEN
           RAISE global_api_others_expt;
       END;
     END IF;
--
    /*************************************
     *  OUT�p�����[�^�Z�b�g(F-5)         *
     *************************************/
     -- �X�e�[�^�X��
     ov_retcode      := gv_status_normal;   -- ���^�[���R�[�h
     ov_errmsg_code  := NULL;               -- �G���[���b�Z�[�W�R�[�h
     ov_errmsg       := NULL;               -- �G���[���b�Z�[�W
     --
     on_delivery_lt  := ln_delivery_lead_time; -- �z�����[�h�^�C��
     --
     IF ( ln_tran_cnt = 0 ) THEN
       IF ( iv_prod_class = cv_prod_class_leaf ) THEN
         on_lead_time  := ln_leaf_lead_time_day;
       ELSE
         on_lead_time  := ln_drink_lead_time_day;
       END IF;
     ELSE
       on_lead_time    := ln_receipt_chg_lead_time_day;
     END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg      := lv_errmsg;
      ov_errmsg_code := lv_err_cd;
      ov_retcode     := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END calc_lead_time;
--
  /**********************************************************************************
   * Procedure Name   : check_shipping_judgment
   * Description      : �o�׉ۃ`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_shipping_judgment(
    iv_check_class                IN  VARCHAR2,                                 -- 1.�`�F�b�N���@�敪
    iv_base_cd                    IN  VARCHAR2,                                 -- 2.���_�R�[�h
    in_item_id                    IN  xxcmn_item_mst_v.inventory_item_id%TYPE,  -- 3.�i��ID
    in_amount                     IN  NUMBER,                                   -- 4.����
    id_date                       IN  DATE,                                     -- 5.�Ώۓ�
    in_deliver_from_id            IN  NUMBER,                                   -- 6.�o�׌�ID
    iv_request_no                 IN  VARCHAR2,                                 -- 7.�˗�No
    ov_retcode                    OUT NOCOPY VARCHAR2,                          -- 8.���^�[���R�[�h
    ov_errmsg_code                OUT NOCOPY VARCHAR2,                          -- 9.�G���[���b�Z�[�W�R�[�h
    ov_errmsg                     OUT NOCOPY VARCHAR2,                          -- 10.�G���[���b�Z�[�W
    on_result                     OUT NOCOPY NUMBER                             -- 11.��������
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_shipping_judgment'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ���b�Z�[�WID
    cv_xxwsh_in_param_set_err      CONSTANT VARCHAR2(100) := 'APP-XXWSH-12801';  -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
    cv_xxwsh_in_check_class_err    CONSTANT VARCHAR2(100) := 'APP-XXWSH-12802';  -- �`�F�b�N���@�敪�l�s���G���[
    cv_xxwsh_no_data_found_err     CONSTANT VARCHAR2(100) := 'APP-XXWSH-12803';  -- �Ώۃt�H�[�L���X�g�f�[�^�Ȃ��G���[���b�Z�[�W
    -- �g�[�N��
    cv_tkn_in_parm                 CONSTANT VARCHAR2(100) := 'IN_PARAM';
    cv_tkn_item_id                 CONSTANT VARCHAR2(100) := 'ITEM_ID';
    cv_tkn_sc_ship_date            CONSTANT VARCHAR2(100) := 'SC_SHIP_DATE';
    -- �g�[�N���Z�b�g�l
    cv_check_class_char            CONSTANT VARCHAR2(100) := '�`�F�b�N���@�敪';
    cv_base_cd_char                CONSTANT VARCHAR2(100) := '���_�R�[�h';
    cv_item_id_char                CONSTANT VARCHAR2(100) := '�i��ID';
    cv_amount_char                 CONSTANT VARCHAR2(100) := '����';
    cv_date_char                   CONSTANT VARCHAR2(100) := '�Ώۓ�';
    cv_deliver_from_id_char        CONSTANT VARCHAR2(100) := '�o�׌�ID';
    --
    -- �`�F�b�N���@�敪
    cv_check_class_1               CONSTANT VARCHAR2(1)   := '1';   -- ����v��
    cv_check_class_2               CONSTANT VARCHAR2(1)   := '2';   -- �o�א�����(���i��)
    cv_check_class_3               CONSTANT VARCHAR2(1)   := '3';   -- �o�א�����(������)
    cv_check_class_4               CONSTANT VARCHAR2(1)   := '4';   -- �v�揤�i����v��
    --
    -- �t�H�[�L���X�g����
    cv_forecast_class_01           CONSTANT VARCHAR2(2)   := '01';   -- ����v��
    cv_forecast_class_02           CONSTANT VARCHAR2(2)   := '02';   -- �v�揤�i
    cv_forecast_class_03           CONSTANT VARCHAR2(2)   := '03';   -- �o�א�����A
    cv_forecast_class_04           CONSTANT VARCHAR2(2)   := '04';   -- �o�א�����B
    --
    -- �o�׈˗��X�e�[�^�X
    cv_request_status_01           CONSTANT VARCHAR2(2)   := '01';        -- ���͒�
    cv_request_status_02           CONSTANT VARCHAR2(2)   := '02';        -- ���_�m��
    cv_request_status_03           CONSTANT VARCHAR2(2)   := '03';        -- ���ߍς�
    cv_request_status_04           CONSTANT VARCHAR2(2)   := '04';        -- �o�׎��ьv���
    cv_request_status_99           CONSTANT VARCHAR2(2)   := '99';        -- ���
    --
    -- �o�׎x���敪
    cv_shipping_shikyu_class_01    CONSTANT VARCHAR2(1)   := '1';         -- �o�׈˗�
    --
    cv_yes                         CONSTANT VARCHAR2(1)   := 'Y';         -- Y (YES_NO�敪)
    cv_no                          CONSTANT VARCHAR2(1)   := 'N';         -- N (YES_NO�敪)
    --
    cv_order                       CONSTANT VARCHAR2(5)   := 'ORDER';         -- ORDER
    --
    --
    cv_format_yyyymm               CONSTANT VARCHAR2(6)   := 'YYYYMM';        -- �N������
    --cd_max_date                    CONSTANT DATE          := to_date('9999/12/31');  -- �ő�N��
    --
    cn_status_success              CONSTANT NUMBER        := 0;
    cn_status_error                CONSTANT NUMBER        := 1;
    cn_status_ship_stop            CONSTANT NUMBER        := 2;
    --
--
    -- *** ���[�J���ϐ� ***
    -- �G���[�ϐ�
    lv_err_cd                      VARCHAR2(30);
    ln_sum_plan_qty                NUMBER;             -- �v�捇�v����
    ln_sum_ship_qty                NUMBER;             -- �o�׍��v����
    ln_min_start_date              DATE;               -- �ő�J�n��
    ln_max_end_date                DATE;               -- �ő�I����
    --
    ln_forecast_cnt                NUMBER DEFAULT 0;   -- �擾�t�H�[�L���X�g����
    ln_item_cnt                    NUMBER DEFAULT 0;   -- OPM�i�ڃ}�X�^����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ******************************************************
    -- *  ���̓p�����[�^�`�F�b�N(G-1)                       *
    -- ******************************************************
    --
    -- �`�F�b�N���@�敪
    IF ( iv_check_class IS NULL )
      THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_param_set_err,
                                              cv_tkn_in_parm,
                                              cv_check_class_char);
        lv_err_cd := cv_xxwsh_in_param_set_err;
        RAISE global_api_expt;
    --
    -- �i��ID
    ELSIF ( in_item_id IS NULL )
      THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_param_set_err,
                                              cv_tkn_in_parm,
                                              cv_item_id_char);
        lv_err_cd := cv_xxwsh_in_param_set_err;
        RAISE global_api_expt;
    --
    -- ����
    ELSIF ( in_amount IS NULL )
      THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_param_set_err,
                                              cv_tkn_in_parm,
                                              cv_amount_char);
        lv_err_cd := cv_xxwsh_in_param_set_err;
        RAISE global_api_expt;
    --
    -- �Ώۓ�
    ELSIF ( id_date IS NULL )
      THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_param_set_err,
                                              cv_tkn_in_parm,
                                              cv_date_char);
        lv_err_cd := cv_xxwsh_in_param_set_err;
        RAISE global_api_expt;
    --
    --
    -- �u�`�F�b�N���@�敪�v��1,2,3,4�ȊO
    ELSIF ( iv_check_class NOT IN ( cv_check_class_1,
                                 cv_check_class_2,
                                 cv_check_class_3,
                                 cv_check_class_4 ))
      THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_check_class_err);
        lv_err_cd := cv_xxwsh_in_check_class_err;
        RAISE global_api_expt;
    --
    -- ���̓p�����[�^�u�`�F�b�N���@�敪�v���u3�v�ȊO�̂Ƃ����̓p�����[�^�u���_�R�[�h�v�����ݒ�
    ELSIF (( iv_check_class <> cv_check_class_3 ) AND ( iv_base_cd IS NULL ))
      THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_param_set_err,
                                              cv_tkn_in_parm,
                                              cv_base_cd_char);
        lv_err_cd := cv_xxwsh_in_param_set_err;
        RAISE global_api_expt;
    --
    -- ���̓p�����[�^�u�`�F�b�N���@�敪�v���u2�v�ȊO�̂Ƃ����̓p�����[�^�u�o�׌�ID�v�����ݒ�
    ELSIF (( iv_check_class <> cv_check_class_2 ) AND ( in_deliver_from_id IS NULL ))
      THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                              cv_xxwsh_in_param_set_err,
                                              cv_tkn_in_parm,
                                              cv_deliver_from_id_char);
        lv_err_cd := cv_xxwsh_in_param_set_err;
        RAISE global_api_expt;
    END IF;
--
    -- ******************************************************
    -- *  �`�F�b�N���@�U�蕪��                              *
    -- ******************************************************
    CASE
      -- ******************************************************
      -- *  �`�F�b�N�P�[�X�@ ����v��`�F�b�N(G-2)            *
      -- ******************************************************
      WHEN ( iv_check_class = cv_check_class_1 ) THEN
        --
        -- �t�H�[�L���X�g���o(����v��̎w�茎�̌���)
        BEGIN
          SELECT SUM( mfdt.original_forecast_quantity ),
                 COUNT(*)
          INTO   ln_sum_plan_qty,                                   -- �v�捇�v����
                 ln_forecast_cnt                                    -- �擾����
          FROM   mrp_forecast_designators  mfds,                    -- �t�H�[�L���X�g��
                 mrp_forecast_dates        mfdt,                    -- �t�H�[�L���X�g���t
                 xxcmn_item_locations2_v   xilv
          WHERE  xilv.inventory_location_id = in_deliver_from_id    -- �o�׌�ID
            AND  mfds.attribute1            = cv_forecast_class_01  -- �t�H�[�L���X�g����(����v��)
            AND  mfds.attribute2            = xilv.segment1         -- �ۊǑq�ɃR�[�h
            AND  mfds.attribute3            = iv_base_cd            -- ���_�R�[�h
            AND  mfdt.forecast_designator   = mfds.forecast_designator
            AND  mfdt.organization_id       = mfds.organization_id
            AND  mfdt.inventory_item_id     = in_item_id
            AND  to_char( mfdt.forecast_date , cv_format_yyyymm )
                                            = to_char( id_date , cv_format_yyyymm );
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          --
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
        --
-- 2008/07/08_1.10_UPDATA_Start
--        IF ( ln_forecast_cnt = 0 ) THEN
--          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
--                                                cv_xxwsh_no_data_found_err,
--                                                cv_tkn_item_id,
--                                                in_item_id,
--                                                cv_tkn_sc_ship_date,
--                                                TO_CHAR(id_date, 'YYYY/MM/DD'));
--          lv_err_cd := cv_xxwsh_no_data_found_err;
--          RAISE global_api_expt;
--        END IF;
--        --
-- 2008/07/08_1.10_UPDATA_End
        -- �o�׈˗��̒��o
        BEGIN
-- 2008/08/22 H.Itou Mod Start PT 2-2_15 �w�E20
--          SELECT
--            NVL(SUM( CASE
--                   -- �X�e�[�^�X���w��(01,02,03)�̏ꍇ
--                   WHEN ( xoha.req_status IN ( cv_request_status_01,
--                                               cv_request_status_02,
--                                               cv_request_status_03  ))
--                     THEN
--                       (  xola.quantity )                  -- ����.���ʁ{����
--                   -- �X�e�[�^�X������(04)�̏ꍇ
--                   WHEN ( xoha.req_status  =   cv_request_status_04 )
--                     THEN
--                       (  xola.shipped_quantity  )          -- ����.�o�׎��ѐ��ʁ{����
--                 END ),0)  + in_amount
--          INTO   ln_sum_ship_qty
--          FROM   xxwsh_order_headers_all       xoha,                   -- �󒍃w�b�_�A�h�I��
--                 xxwsh_order_lines_all         xola,                   -- �󒍖��׃A�h�I��
--                 xxwsh_oe_transaction_types2_v xottv                   -- �󒍃^�C�v���View
--          WHERE  xoha.deliver_from_id            = in_deliver_from_id     -- �o�׌�ID
--            AND  xoha.head_sales_branch          = iv_base_cd             -- �Ǌ����_
--            AND  xoha.latest_external_flag       = cv_yes                 -- �ŐV�t���O
--            AND  xoha.req_status                <> cv_request_status_99   -- �X�e�[�^�X(����ȊO)
--            AND  xottv.transaction_type_id       = xoha.order_type_id     -- �󒍃^�C�vID
--            AND  xottv.order_category_code       = cv_order               -- �󒍃J�e�S��
--            AND  xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01
--                                                                          -- �o�׎x���敪
--                 -- �w���̏ꍇ�u���ח\����v�ƁA���т̏ꍇ�u���ד��v�Ɣ�r
--            AND  ( ( ( xoha.req_status    IN ( cv_request_status_01,
--                                               cv_request_status_02,
--                                               cv_request_status_03  ))
--                    AND
--                     ( to_char(xoha.schedule_arrival_date, cv_format_yyyymm )
--                                                 = to_char( id_date , cv_format_yyyymm )))
--                 OR (( xoha.req_status     =   cv_request_status_04  )
--                    AND
--                     ( to_char(xoha.arrival_date, cv_format_yyyymm )
--                                                 = to_char( id_date , cv_format_yyyymm ))))
--            AND  xola.order_header_id            = xoha.order_header_id   -- �󒍃w�b�_ID
--            AND  xola.shipping_inventory_item_id = in_item_id             -- �i��ID
--            AND  ((iv_request_no IS NULL) OR (xoha.request_no <> iv_request_no))  -- �˗�No
--            AND  NVL( xola.delete_flag, cv_no ) <> cv_yes;                -- �폜�t���O('Y'�ȊO)
--
          SELECT NVL(SUM(subsql.quantity),0)  + in_amount
          INTO   ln_sum_ship_qty
          FROM  (-- �X�e�[�^�X�����͒��`���ς̏ꍇ
                 SELECT xola.quantity                 quantity                            -- ����.����
                 FROM   xxwsh_order_headers_all       xoha,                               -- �󒍃w�b�_�A�h�I��
                        xxwsh_order_lines_all         xola,                               -- �󒍖��׃A�h�I��
                        xxwsh_oe_transaction_types2_v xottv                               -- �󒍃^�C�v���View
                 WHERE  xoha.deliver_from_id            = in_deliver_from_id              -- �o�׌�ID
                 AND    xoha.head_sales_branch          = iv_base_cd                      -- �Ǌ����_
                 AND    xoha.latest_external_flag       = cv_yes                          -- �ŐV�t���O
                 AND    xoha.req_status                <> cv_request_status_99            -- �X�e�[�^�X(����ȊO)
                 AND    xottv.transaction_type_id       = xoha.order_type_id              -- �󒍃^�C�vID
                 AND    xottv.order_category_code       = cv_order                        -- �󒍃J�e�S��
                 AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- �o�׎x���敪
                 AND    xoha.req_status              IN ( cv_request_status_01,           -- �X�e�[�^�X01:���͒�
                                                          cv_request_status_02,           -- �X�e�[�^�X02:���_�m��
                                                          cv_request_status_03  )         -- �X�e�[�^�X03:���ߍς�
                 AND    TO_CHAR(xoha.schedule_arrival_date, cv_format_yyyymm )            -- ���ח\���
                                                        = TO_CHAR( id_date , cv_format_yyyymm )
                 AND    xola.order_header_id            = xoha.order_header_id            -- �󒍃w�b�_ID
                 AND    xola.shipping_inventory_item_id = in_item_id                      -- �i��ID
                 AND  ((iv_request_no                  IS NULL)                           -- �˗�No
                   OR  (xoha.request_no                <> iv_request_no))
                 AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- �폜�t���O('Y'�ȊO)
                 -------------------------
                 UNION ALL
                 -------------------------
                 -- �X�e�[�^�X���o�׎��ъm��ς̏ꍇ
                 SELECT xola.shipped_quantity         quantity                            -- ����.�o�׎��ѐ���
                 FROM   xxwsh_order_headers_all       xoha,                               -- �󒍃w�b�_�A�h�I��
                        xxwsh_order_lines_all         xola,                               -- �󒍖��׃A�h�I��
                        xxwsh_oe_transaction_types2_v xottv                               -- �󒍃^�C�v���View
                 WHERE  xoha.deliver_from_id            = in_deliver_from_id              -- �o�׌�ID
                 AND    xoha.head_sales_branch          = iv_base_cd                      -- �Ǌ����_
                 AND    xoha.latest_external_flag       = cv_yes                          -- �ŐV�t���O
                 AND    xoha.req_status                <> cv_request_status_99            -- �X�e�[�^�X(����ȊO)
                 AND    xottv.transaction_type_id       = xoha.order_type_id              -- �󒍃^�C�vID
                 AND    xottv.order_category_code       = cv_order                        -- �󒍃J�e�S��
                 AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- �o�׎x���敪
                 AND    xoha.req_status                 = cv_request_status_04            -- �X�e�[�^�X04:�o�׎��ъm���
                 AND    TO_CHAR(xoha.arrival_date, cv_format_yyyymm )                     -- ���ד�
                                                        = TO_CHAR( id_date , cv_format_yyyymm )
                 AND    xola.order_header_id            = xoha.order_header_id            -- �󒍃w�b�_ID
                 AND    xola.shipping_inventory_item_id = in_item_id                      -- �i��ID
                 AND  ((iv_request_no                  IS NULL)                           -- �˗�No
                   OR  (xoha.request_no                <> iv_request_no))
                 AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- �폜�t���O('Y'�ȊO)
                ) subsql
          ;
-- 2008/08/22 H.Itou Mod End
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          --
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
      -- ******************************************************
      -- *  �`�F�b�N�P�[�X�A �o�א�����(���i��)�`�F�b�N(G-3)  *
      -- ******************************************************
      WHEN ( iv_check_class = cv_check_class_2 ) THEN
        -- �t�H�[�L���X�g���o(����v��̎w�茎�̌���)
        BEGIN
          SELECT SUM( mfdt.original_forecast_quantity ),
                 MIN( mfdt.forecast_date ),
                 MAX( mfdt.rate_end_date )
          INTO   ln_sum_plan_qty,                                   -- �v�捇�v����
                 ln_min_start_date,                                 -- �ŏ��̊J�n��
                 ln_max_end_date                                    -- �ő�̏I����
          FROM   mrp_forecast_designators  mfds,                    -- �t�H�[�L���X�g��
                 mrp_forecast_dates        mfdt                     -- �t�H�[�L���X�g���t
          WHERE  mfds.attribute1            = cv_forecast_class_03  -- �t�H�[�L���X�g����(�o�א�����A)
            AND  mfds.attribute3            = iv_base_cd            -- ���_�R�[�h
            AND  mfdt.forecast_designator   = mfds.forecast_designator   -- �t�H�[�L���X�g��
            AND  mfdt.organization_id       = mfds.organization_id       -- �g�D�h�c
            AND  mfdt.inventory_item_id     = in_item_id                 -- �i�ڂh�c
            AND  mfdt.forecast_date        <= trunc( id_date )           -- �J�n��<=�Ώۓ�
--            AND  ((   mfdt.rate_end_date   IS NULL )
--                  OR  mfdt.rate_end_date >= trunc( id_date ));           -- �I����>=�Ώۓ�
            AND  mfdt.rate_end_date        >= trunc( id_date );          -- �I����>=�Ώۓ�
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          --
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
        --
        --
        -- �o�׈˗��̒��o
        BEGIN
-- 2008/08/22 H.Itou Mod Start PT 2-2_15 �w�E20
--          SELECT
--            NVL(SUM( CASE
--                   WHEN ( xoha.req_status IN ( cv_request_status_01,
--                                               cv_request_status_02,
--                                               cv_request_status_03  ))
--                     THEN
--                       (  xola.quantity )
--                   WHEN ( xoha.req_status  =   cv_request_status_04 )
--                     THEN
--                       (  xola.shipped_quantity )
--                 END ), 0) + in_amount
--          INTO   ln_sum_ship_qty
--          FROM   xxwsh_order_headers_all       xoha,
--                 xxwsh_order_lines_all         xola,
--                 xxwsh_oe_transaction_types2_v xottv
--          WHERE  xoha.head_sales_branch          = iv_base_cd                      -- ���_�R�[�h
--            AND  xoha.latest_external_flag       = cv_yes                          -- �ŐV�t���O
--            AND  xoha.req_status                <> cv_request_status_99            -- �X�e�[�^�X����ȊO
--            AND  xottv.transaction_type_id       = xoha.order_type_id              -- �󒍃^�C�vID
--            AND  xottv.order_category_code       = cv_order                        -- �󒍃J�e�S��
--            AND  xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- �o�׎x���敪
--                 -- �w���̏ꍇ�u���ח\����v�ƁA���т̏ꍇ�u���ד��v�Ɣ�r
--            AND  ( ( ( xoha.req_status IN ( cv_request_status_01,
--                                            cv_request_status_02,
--                                            cv_request_status_03  ))
--                    AND
--                     (( xoha.schedule_arrival_date   >= trunc( ln_min_start_date ) )
--                     AND
--                      ( xoha.schedule_arrival_date   <= trunc( ln_max_end_date   ) ))
--                 )
--                 OR
--                 (( xoha.req_status = cv_request_status_04  )
--                   AND
--                   ((   xoha.arrival_date            >= trunc( ln_min_start_date ) )
--                   AND
--                    (   xoha.arrival_date            <= trunc( ln_max_end_date   ) ))
--                 ) )
--            AND  xola.order_header_id            = xoha.order_header_id            -- �󒍃w�b�_ID
--            AND  xola.shipping_inventory_item_id = in_item_id                      -- �i��ID
--            AND  ((iv_request_no IS NULL) OR (xoha.request_no <> iv_request_no))   -- �˗�No
--            AND  NVL( xola.delete_flag, cv_no ) <> cv_yes;                         -- �폜�t���O
--
          SELECT NVL(SUM(subsql.quantity),0)  + in_amount
          INTO   ln_sum_ship_qty
          FROM  (-- �X�e�[�^�X�����͒��`���ς̏ꍇ
                 SELECT xola.quantity                 quantity                            -- ����.����
                 FROM   xxwsh_order_headers_all       xoha                                -- �󒍃w�b�_�A�h�I��
                       ,xxwsh_order_lines_all         xola                                -- �󒍖��׃A�h�I��
                       ,xxwsh_oe_transaction_types2_v xottv                               -- �󒍃^�C�v���VIEW
                 WHERE  xoha.head_sales_branch          = iv_base_cd                      -- ���_�R�[�h
                 AND    xoha.latest_external_flag       = cv_yes                          -- �ŐV�t���O
                 AND    xoha.req_status                <> cv_request_status_99            -- �X�e�[�^�X����ȊO
                 AND    xottv.transaction_type_id       = xoha.order_type_id              -- �󒍃^�C�vID
                 AND    xottv.order_category_code       = cv_order                        -- �󒍃J�e�S��
                 AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- �o�׎x���敪
                 AND    xoha.req_status              IN ( cv_request_status_01,           -- �X�e�[�^�X01:���͒�
                                                          cv_request_status_02,           -- �X�e�[�^�X02:���_�m��
                                                          cv_request_status_03  )         -- �X�e�[�^�X03:���ߍς�
                 AND    xoha.schedule_arrival_date     >= TRUNC( ln_min_start_date )      -- ���ח\���
                 AND    xoha.schedule_arrival_date     <= TRUNC( ln_max_end_date   )      -- ���ח\���
                 AND    xola.order_header_id            = xoha.order_header_id            -- �󒍃w�b�_ID
                 AND    xola.shipping_inventory_item_id = in_item_id                      -- �i��ID
                 AND  ((iv_request_no                  IS NULL)                           -- �˗�No
                   OR  (xoha.request_no                <> iv_request_no))
                 AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- �폜�t���O
                 -------------------------
                 UNION ALL
                 -------------------------
                 -- �X�e�[�^�X���o�׎��ъm��ς̏ꍇ
                 SELECT xola.shipped_quantity         quantity                            -- ����.�o�׎��ѐ���
                 FROM   xxwsh_order_headers_all       xoha                                -- �󒍃w�b�_�A�h�I��
                       ,xxwsh_order_lines_all         xola                                -- �󒍖��׃A�h�I��
                       ,xxwsh_oe_transaction_types2_v xottv                               -- �󒍃^�C�v���VIEW
                 WHERE  xoha.head_sales_branch          = iv_base_cd                      -- ���_�R�[�h
                 AND    xoha.latest_external_flag       = cv_yes                          -- �ŐV�t���O
                 AND    xoha.req_status                <> cv_request_status_99            -- �X�e�[�^�X����ȊO
                 AND    xottv.transaction_type_id       = xoha.order_type_id              -- �󒍃^�C�vID
                 AND    xottv.order_category_code       = cv_order                        -- �󒍃J�e�S��
                 AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- �o�׎x���敪
                 AND    xoha.req_status                 = cv_request_status_04            -- �X�e�[�^�X04:�o�׎��ьv���
                 AND    xoha.arrival_date              >= TRUNC( ln_min_start_date )      -- ���ד�
                 AND    xoha.arrival_date              <= TRUNC( ln_max_end_date   )      -- ���ד�
                 AND    xola.order_header_id            = xoha.order_header_id            -- �󒍃w�b�_ID
                 AND    xola.shipping_inventory_item_id = in_item_id                      -- �i��ID
                 AND  ((iv_request_no                 IS NULL)                            -- �˗�No
                   OR  (xoha.request_no               <> iv_request_no))
                 AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- �폜�t���O
                ) subsql
          ;
-- 2008/08/22 H.Itou Mod End
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          --
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
        --
      -- ******************************************************
      -- *  �`�F�b�N�P�[�X�B �o�א�����(������)�`�F�b�N(G-4)  *
      -- ******************************************************
      WHEN ( iv_check_class = cv_check_class_3 ) THEN
        --(1) �o�ג�~���`�F�b�N
        BEGIN
          -- 2008/07/30 �����ύX�v��#182 UPD START
          --SELECT  COUNT(*)
          --INTO    ln_item_cnt
          --FROM    xxcmn_item_mst2_v  ximv   -- OPM�i�ڏ��View2
          --WHERE   ximv.inventory_item_id   =  in_item_id
          --  AND   ximv.obsolete_date      <=  trunc( id_date )
          --  AND   ximv.start_date_active  <=  trunc( id_date )
          --  AND   ximv.end_date_active    >=  trunc( id_date );
          SELECT  COUNT(*)
          INTO    ln_item_cnt
          FROM    xxcmn_item_mst2_v  ximv   -- OPM�i�ڏ��View2
          WHERE   ximv.inventory_item_id   =  in_item_id
            AND   ximv.shipping_end_date  <=  trunc( id_date )
            AND   ximv.start_date_active  <=  trunc( id_date )
            AND   ximv.end_date_active    >=  trunc( id_date );
          -- 2008/07/30 �����ύX�v��#182 UPD END
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
        --
        -- 1���ȏ�ŏo�ג�~���G���[
        IF ( ln_item_cnt = 0 ) THEN
         -- �t�H�[�L���X�g���o(����v��̎w�茎�̌���)
          BEGIN
            SELECT SUM( mfdt.original_forecast_quantity ),
                   MIN( mfdt.forecast_date ),
                   MAX( mfdt.rate_end_date )
            INTO   ln_sum_plan_qty,                                   -- �v�捇�v����
                   ln_min_start_date,                                 -- �ŏ��̊J�n��
                   ln_max_end_date                                    -- �ő�̏I����
            FROM   mrp_forecast_designators  mfds,                    -- �t�H�[�L���X�g��
                   mrp_forecast_dates        mfdt,                    -- �t�H�[�L���X�g���t
                   xxcmn_item_locations2_v   xilv
            WHERE  xilv.inventory_location_id = in_deliver_from_id    -- �o�׌�ID
              AND  mfds.attribute1            = cv_forecast_class_04  -- �t�H�[�L���X�g����(�o�א�����B)
              AND  mfds.attribute2            = xilv.segment1         -- �ۊǑq�ɃR�[�h
              AND  mfdt.forecast_designator   = mfds.forecast_designator   -- �t�H�[�L���X�g��
              AND  mfdt.organization_id       = mfds.organization_id       -- �g�D�h�c
              AND  mfdt.inventory_item_id     = in_item_id                 -- �i�ڂh�c
              AND  mfdt.forecast_date        <= trunc( id_date )           -- �J�n��<=�Ώۓ�
--              AND  ((   mfdt.rate_end_date   IS NULL )
--                    OR  mfdt.rate_end_date   >= trunc( id_date ));
              AND  mfdt.rate_end_date        >= trunc( id_date );          -- �I����>=�Ώۓ�
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
            --
            WHEN OTHERS THEN
              RAISE global_api_expt;
          END;
          --
          --
          -- �o�׈˗��̒��o
          BEGIN
-- 2008/08/22 H.Itou Mod Start PT 2-2_15 �w�E20
--            SELECT
--              NVL(SUM( CASE
--                     WHEN ( xoha.req_status IN ( cv_request_status_01,
--                                                 cv_request_status_02,
--                                                 cv_request_status_03  ))
--                       THEN
--                         (  xola.quantity         )
--                     WHEN ( xoha.req_status  =   cv_request_status_04 )
--                       THEN
--                         (  xola.shipped_quantity )
--                   END ),0)    + in_amount
--                   ,count(*)
--            INTO   ln_sum_ship_qty,ln_forecast_cnt
--            FROM   xxwsh_order_headers_all       xoha,
--                   xxwsh_order_lines_all         xola,
--                   xxwsh_oe_transaction_types2_v xottv
--            WHERE  xoha.deliver_from_id           = in_deliver_from_id            -- �o�׌�
--              AND  xoha.latest_external_flag      = cv_yes                        -- �ŐV�t���O
--              AND  xoha.req_status               <> cv_request_status_99          -- �X�e�[�^�X����ȊO
--              AND  xottv.transaction_type_id      = xoha.order_type_id            -- �󒍃^�C�vID
--              AND  xottv.order_category_code      = cv_order                      -- �󒍃J�e�S��
--              AND  xottv.shipping_shikyu_class    = cv_shipping_shikyu_class_01   -- �o�׎x���敪
--                   -- �w���̏ꍇ�u�o�ח\����v�ƁA���т̏ꍇ�u�o�ד��v�Ɣ�r
--              AND  ( ( ( xoha.req_status IN ( cv_request_status_01,
--                                              cv_request_status_02,
--                                              cv_request_status_03  ))
--                      AND
--                       (( xoha.schedule_ship_date   >= trunc( ln_min_start_date ) )
--                       AND
--                        ( xoha.schedule_ship_date   <= trunc( ln_max_end_date   ) ))
--                   )
--                   OR
--                   (( xoha.req_status = cv_request_status_04  )
--                     AND
--                     ((   xoha.shipped_date         >= trunc( ln_min_start_date ) )
--                     AND
--                      (   xoha.shipped_date         <= trunc( ln_max_end_date ) ))
--                   ) )
--              AND  xola.order_header_id            = xoha.order_header_id            -- �󒍃w�b�_ID
--              AND  xola.shipping_inventory_item_id = in_item_id                      -- �i��ID
--              AND  ((iv_request_no IS NULL) OR (xoha.request_no <> iv_request_no))   -- �˗�No
--              AND  NVL( xola.delete_flag, cv_no ) <> cv_yes;                         -- �폜�t���O
--
            SELECT NVL(SUM(subsql.quantity),0)  + in_amount
                  ,COUNT(*)                                                                 -- �t�H�[�L���X�g��
            INTO   ln_sum_ship_qty,ln_forecast_cnt
            FROM  (-- �X�e�[�^�X�����͒��`���ς̏ꍇ
                   SELECT xola.quantity                 quantity                            -- ����.����
                   FROM   xxwsh_order_headers_all       xoha                                -- �󒍃w�b�_�A�h�I��
                         ,xxwsh_order_lines_all         xola                                -- �󒍖��׃A�h�I��
                         ,xxwsh_oe_transaction_types2_v xottv                               -- �󒍃^�C�v���VIEW
                   WHERE  xoha.deliver_from_id            = in_deliver_from_id              -- �o�׌�
                   AND    xoha.latest_external_flag       = cv_yes                          -- �ŐV�t���O
                   AND    xoha.req_status                <> cv_request_status_99            -- �X�e�[�^�X����ȊO
                   AND    xottv.transaction_type_id       = xoha.order_type_id              -- �󒍃^�C�vID
                   AND    xottv.order_category_code       = cv_order                        -- �󒍃J�e�S��
                   AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- �o�׎x���敪
                   AND    xoha.req_status              IN ( cv_request_status_01,           -- �X�e�[�^�X01:���͒�
                                                            cv_request_status_02,           -- �X�e�[�^�X02:���_�m��
                                                            cv_request_status_03  )         -- �X�e�[�^�X03:���ߍς�
                   AND    xoha.schedule_ship_date        >= TRUNC( ln_min_start_date )      -- �o�ח\���
                   AND    xoha.schedule_ship_date        <= TRUNC( ln_max_end_date   )      -- �o�ח\���
                   AND    xola.order_header_id            = xoha.order_header_id            -- �󒍃w�b�_ID
                   AND    xola.shipping_inventory_item_id = in_item_id                      -- �i��ID
                   AND  ((iv_request_no                  IS NULL)                           -- �˗�No
                     OR  (xoha.request_no                <> iv_request_no))
                   AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- �폜�t���O
                   -------------------------
                   UNION ALL
                   -------------------------
                   -- �X�e�[�^�X���o�׎��ъm��ς̏ꍇ
                   SELECT xola.shipped_quantity         quantity                            -- ����.�o�׎��ѐ���
                   FROM   xxwsh_order_headers_all       xoha                                -- �󒍃w�b�_�A�h�I��
                         ,xxwsh_order_lines_all         xola                                -- �󒍖��׃A�h�I��
                         ,xxwsh_oe_transaction_types2_v xottv                               -- �󒍃^�C�v���VIEW
                   WHERE  xoha.deliver_from_id            = in_deliver_from_id              -- �o�׌�
                   AND    xoha.latest_external_flag       = cv_yes                          -- �ŐV�t���O
                   AND    xoha.req_status                <> cv_request_status_99            -- �X�e�[�^�X����ȊO
                   AND    xottv.transaction_type_id       = xoha.order_type_id              -- �󒍃^�C�vID
                   AND    xottv.order_category_code       = cv_order                        -- �󒍃J�e�S��
                   AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- �o�׎x���敪
                   AND    xoha.req_status                 = cv_request_status_04            -- �X�e�[�^�X04:�o�׎��ьv���
                   AND    xoha.shipped_date              >= TRUNC( ln_min_start_date )      -- �o�ד�
                   AND    xoha.shipped_date              <= TRUNC( ln_max_end_date   )      -- �o�ד�
                   AND    xola.order_header_id            = xoha.order_header_id            -- �󒍃w�b�_ID
                   AND    xola.shipping_inventory_item_id = in_item_id                      -- �i��ID
                   AND  ((iv_request_no                  IS NULL)                           -- �˗�No
                     OR  (xoha.request_no                <> iv_request_no))
                   AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- �폜�t���O
                  ) subsql
            ;
-- 2008/08/22 H.Itou Mod End
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
            --
            WHEN OTHERS THEN
              RAISE global_api_expt;
          END;
        END IF;
       --
      -- ******************************************************
      -- *  �`�F�b�N�P�[�X�C �v�揤�i����v��`�F�b�N(G-5)    *
      -- ******************************************************
      WHEN ( iv_check_class = cv_check_class_4 ) THEN
        -- �t�H�[�L���X�g���o(����v��̎w�茎�̌���)
        BEGIN
          SELECT SUM( mfdt.original_forecast_quantity ),
                 MIN( mfdt.forecast_date ),
                 MAX( mfdt.rate_end_date ),
                 COUNT(*)
          INTO   ln_sum_plan_qty,                                   -- �v�捇�v����
                 ln_min_start_date,                                 -- �ŏ��̊J�n��
                 ln_max_end_date,                                   -- �ő�̏I����
                 ln_forecast_cnt                                    -- �擾����
          FROM   mrp_forecast_designators  mfds,                    -- �t�H�[�L���X�g��
                 mrp_forecast_dates        mfdt,                    -- �t�H�[�L���X�g���t
                 xxcmn_item_locations2_v   xilv
           WHERE  xilv.inventory_location_id  = in_deliver_from_id    -- �o�׌�ID
             AND  mfds.attribute1             = cv_forecast_class_02  -- �t�H�[�L���X�g����(�v�揤�i)
             AND  mfds.attribute2             = xilv.segment1         -- �ۊǑq�ɃR�[�h
             AND  mfds.attribute3             = iv_base_cd            -- ���_�R�[�h
             AND  mfdt.forecast_designator    = mfds.forecast_designator   -- �t�H�[�L���X�g��
             AND  mfdt.organization_id        = mfds.organization_id       -- �g�D�h�c
             AND  mfdt.inventory_item_id      = in_item_id                 -- �i�ڂh�c
             AND  mfdt.forecast_date         <= trunc( id_date )           -- �J�n��<=�Ώۓ�
--             AND  ((   mfdt.rate_end_date    IS NULL )
--                   OR  mfdt.rate_end_date  >= trunc( id_date ));           -- �I����>=�Ώۓ�
             AND  mfdt.rate_end_date         >= trunc( id_date );          -- �I����>=�Ώۓ�
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          --
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
        --
        IF ( ln_forecast_cnt = 0 ) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_cnst_xxwsh,
                                                cv_xxwsh_no_data_found_err,
                                                cv_tkn_item_id,
                                                in_item_id,
                                                cv_tkn_sc_ship_date,
                                                TO_CHAR(id_date,'YYYY/MM/DD'));
          lv_err_cd := cv_xxwsh_no_data_found_err;
          RAISE global_api_expt;
        END IF;
        --
        --
        -- �o�׈˗��̒��o
        BEGIN
-- 2008/08/22 H.Itou Mod Start PT 2-2_15 �w�E20
--          SELECT
--            NVL(SUM( CASE
--                   WHEN ( xoha.req_status IN ( cv_request_status_01,
--                                               cv_request_status_02,
--                                               cv_request_status_03  ))
--                     THEN
--                       (  xola.quantity          )
--                   WHEN ( xoha.req_status  =   cv_request_status_04 )
--                     THEN
--                       (  xola.shipped_quantity  )
--                 END ),0)  + in_amount
--          INTO   ln_sum_ship_qty
--          FROM   xxwsh_order_headers_all       xoha,
--                 xxwsh_order_lines_all         xola,
--                 xxwsh_oe_transaction_types2_v xottv
--          WHERE  xoha.deliver_from_id           = in_deliver_from_id          -- �o�׌�
--            AND  xoha.head_sales_branch         = iv_base_cd                  -- ���_�R�[�h
--            AND  xoha.latest_external_flag      = cv_yes                      -- �ŐV�t���O
--            AND  xoha.req_status               <> cv_request_status_99        -- �X�e�[�^�X����ȊO
--            AND  xottv.transaction_type_id      = xoha.order_type_id          -- �󒍃^�C�vID
--            AND  xottv.order_category_code      = cv_order                    -- �󒍃J�e�S��
--            AND  xottv.shipping_shikyu_class    = cv_shipping_shikyu_class_01 -- �o�׎x���敪
--                 -- �w���̏ꍇ�u�o�ח\����v�ƁA���т̏ꍇ�u�o�ד��v�Ɣ�r
--            AND  ( ( ( xoha.req_status IN ( cv_request_status_01,
--                                            cv_request_status_02,
--                                            cv_request_status_03  ))
--                   AND
--                    (( xoha.schedule_ship_date  >= trunc( ln_min_start_date ) )
--                   AND
--                     ( xoha.schedule_ship_date  <= trunc( ln_max_end_date ) ))
--                 )
--                 OR
--                 ( ( xoha.req_status = cv_request_status_04  )
--                   AND
--                   ((  xoha.shipped_date        >= trunc( ln_min_start_date ) )
--                   AND
--                    (  xoha.shipped_date        <= trunc( ln_max_end_date ) ))
--                 ) )
--            AND  xola.order_header_id            = xoha.order_header_id            -- �󒍃w�b�_ID
--            AND  xola.shipping_inventory_item_id = in_item_id                      -- �i��ID
--            AND  ((iv_request_no IS NULL) OR (xoha.request_no <> iv_request_no))   -- �˗�No
--            AND  NVL( xola.delete_flag, cv_no ) <> cv_yes;                         -- �폜�t���O
--
          SELECT NVL(SUM(subsql.quantity),0)  + in_amount
          INTO   ln_sum_ship_qty
          FROM  (-- �X�e�[�^�X�����͒��`���ς̏ꍇ
                 SELECT xola.quantity                 quantity                            -- ����.����
                 FROM   xxwsh_order_headers_all       xoha                                -- �󒍃w�b�_�A�h�I��
                       ,xxwsh_order_lines_all         xola                                -- �󒍖��׃A�h�I��
                       ,xxwsh_oe_transaction_types2_v xottv                               -- �󒍃^�C�v���VIEW
                 WHERE  xoha.deliver_from_id            = in_deliver_from_id              -- �o�׌�
                 AND    xoha.head_sales_branch          = iv_base_cd                      -- ���_�R�[�h
                 AND    xoha.latest_external_flag       = cv_yes                          -- �ŐV�t���O
                 AND    xoha.req_status                <> cv_request_status_99            -- �X�e�[�^�X����ȊO
                 AND    xottv.transaction_type_id       = xoha.order_type_id              -- �󒍃^�C�vID
                 AND    xottv.order_category_code       = cv_order                        -- �󒍃J�e�S��
                 AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- �o�׎x���敪
                 AND    xoha.req_status              IN ( cv_request_status_01,            -- �X�e�[�^�X01:���͒�
                                                          cv_request_status_02,            -- �X�e�[�^�X02:���_�m��
                                                          cv_request_status_03  )          -- �X�e�[�^�X03:���ߍς�
                 AND    xoha.schedule_ship_date        >= TRUNC( ln_min_start_date )
                 AND    xoha.schedule_ship_date        <= TRUNC( ln_max_end_date   )
                 AND    xola.order_header_id            = xoha.order_header_id            -- �󒍃w�b�_ID
                 AND    xola.shipping_inventory_item_id = in_item_id                      -- �i��ID
                 AND  ((iv_request_no                  IS NULL)                           -- �˗�No
                   OR  (xoha.request_no                <> iv_request_no))
                 AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- �폜�t���O
                 -------------------------
                 UNION ALL
                 -------------------------
                 -- �X�e�[�^�X���o�׎��ъm��ς̏ꍇ
                 SELECT xola.shipped_quantity         quantity                            -- ����.�o�׎��ѐ���
                 FROM   xxwsh_order_headers_all       xoha                                -- �󒍃w�b�_�A�h�I��
                       ,xxwsh_order_lines_all         xola                                -- �󒍖��׃A�h�I��
                       ,xxwsh_oe_transaction_types2_v xottv                               -- �󒍃^�C�v���VIEW
                 WHERE  xoha.deliver_from_id            = in_deliver_from_id              -- �o�׌�
                 AND    xoha.head_sales_branch          = iv_base_cd                      -- ���_�R�[�h
                 AND    xoha.latest_external_flag       = cv_yes                          -- �ŐV�t���O
                 AND    xoha.req_status                <> cv_request_status_99            -- �X�e�[�^�X����ȊO
                 AND    xottv.transaction_type_id       = xoha.order_type_id              -- �󒍃^�C�vID
                 AND    xottv.order_category_code       = cv_order                        -- �󒍃J�e�S��
                 AND    xottv.shipping_shikyu_class     = cv_shipping_shikyu_class_01     -- �o�׎x���敪
                 AND    xoha.req_status                 = cv_request_status_04            -- �X�e�[�^�X04:�o�׎��ьv���
                 AND    xoha.shipped_date              >= TRUNC( ln_min_start_date )      -- �o�ד�
                 AND    xoha.shipped_date              <= TRUNC( ln_max_end_date   )      -- �o�ד�
                 AND    xola.order_header_id            = xoha.order_header_id            -- �󒍃w�b�_ID
                 AND    xola.shipping_inventory_item_id = in_item_id                      -- �i��ID
                 AND  ((iv_request_no                  IS NULL)                           -- �˗�No
                   OR  (xoha.request_no                <> iv_request_no))
                 AND    NVL( xola.delete_flag, cv_no ) <> cv_yes                          -- �폜�t���O
                 ) subsql
          ;
-- 2008/08/22 H.Itou Mod End
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          --
          WHEN OTHERS THEN
            RAISE global_api_expt;
        END;
        --
        --
    END CASE;
--
    -- ******************************************************
    -- *  OUT�p�����[�^�Z�b�g(G-6)                          *
    -- ******************************************************
    -- �X�e�[�^�X��
    ov_retcode      := gv_status_normal;   -- ���^�[���R�[�h
    ov_errmsg_code  := NULL;               -- �G���[���b�Z�[�W�R�[�h
    ov_errmsg       := NULL;               -- �G���[���b�Z�[�W
    --
    -- �v�捇�v���ʁ��o�׍��v���ʂł���΁A�u�������ʁv�Ɂu���ʃI�[�o�[�G���[�v
    IF ( ln_item_cnt = 0 ) THEN
      IF ((ln_sum_plan_qty IS NULL) OR ( ln_sum_plan_qty >= ln_sum_ship_qty )) THEN
        -- ����
        on_result      := cn_status_success;
      ELSE
        -- ���ʃI�[�o�[�G���[
        on_result      := cn_status_error;
      END IF;
    ELSE
      -- �o�ג�~�G���[
        on_result      := cn_status_ship_stop;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg      := lv_errmsg;
      ov_errmsg_code := lv_err_cd;
      ov_retcode     := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg      := SQLERRM;
      ov_errmsg_code := SQLCODE;
      ov_retcode     := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_shipping_judgment;
--
END xxwsh_common910_pkg;
/
