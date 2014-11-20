CREATE OR REPLACE PACKAGE BODY APPS.XXCSO019A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A10C(body)
 * Description      : �K�┄��v��Ǘ��\�i�������s�̒��[�j�p�ɃT�}���e�[�u�����쐬���܂��B
 * MD.050           :  MD050_CSO_019_A10_�K�┄��v��Ǘ��W�v�o�b�`
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  check_parm             �p�����[�^�`�F�b�N (A-2)
 *  delete_data            �����Ώۃf�[�^�폜 (A-3)
 *  get_day_acct_data      ���ʌڋq�ʃf�[�^�擾 (A-4)
 *  insert_day_acct_dt     �K�┄��v��Ǘ��\�T�}���e�[�u���ɓo�^ (A-5)
 *  insert_day_emp_dt      ���ʉc�ƈ��ʎ擾�o�^ (A-6)
 *  insert_day_group_dt    ���ʉc�ƃO���[�v�ʎ擾�o�^ (A-7)
 *  insert_day_base_dt     ���ʋ��_�^�ەʎ擾�o�^ (A-8)
 *  insert_day_area_dt     ���ʒn��c�ƕ��^���ʎ擾�o�^ (A-9)
 *  insert_mon_acct_dt     ���ʌڋq�ʎ擾�o�^ (A-10)
 *  insert_mon_emp_dt      ���ʉc�ƈ��ʎ擾�o�^ (A-11)
 *  insert_mon_group_dt    ���ʉc�ƃO���[�v�ʎ擾�o�^ (A-12)
 *  insert_mon_base_dt     ���ʋ��_�^�ەʎ擾�o�^ (A-13)
 *  insert_mon_area_dt     ���ʒn��c�ƕ��^���ʎ擾�o�^ (A-14)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������ (A-15)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-13    1.0   Tomoko.Mori      �V�K�쐬
 *  2009-03-12    1.1   Kazuyo.Hosoi     �y��Q�Ή�047�E048�E057�z
 *                                       �ڋq�敪�A�X�e�[�^�X���o�����ύX�E�V�K�ڋq�l���̔���
 *                                       ���o�����ύX
 *  2009-03-19    1.1   Tomoko.Mori      �y��Q�Ή�073�z
 *                                       ���ʌڋq�ʔ���v����i���ʔ���v��j�擾�̒��o�����s�
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897�Ή�
 *  2009-05-01    1.3   Daisuke.Abe      �y����v��o�͑Ή��zT1_0689,T1_0692,T1_0694,T1_0695
 *  2009-05-01    1.3   Daisuke.Abe      �y����v��o�͑Ή��zT1_0734,T1_0739,T1_0744,T1_0745
 *  2009-05-01    1.3   Daisuke.Abe      �y����v��o�͑Ή��zT1_0751
 *  2009-05-19    1.4   H.Ogawa          ��Q�ԍ��FT1_1024,T1_1037,T1_1038
 *  2009-05-25    1.4   T.Mori           �Ɩ��������t�A��v���ԊJ�n����NULL�ł���ꍇ�A
 *                                       �G���[���b�Z�[�W���o�͂��ꂸ�A�G���[�I�����Ȃ�
 *  2009-08-28    1.5   Daisuke.Abe      �y0001194�z�p�t�H�[�}���X�Ή�
 *  2009-11-06    1.6   Kazuo.Satomura   �yE_T4_00135(I_E_636)�z
 *  2009-12-28    1.7   Kazuyo.Hosoi     �yE_�{�ғ�_00686�z�Ή�
 *  2010-05-14    1.8   SCS �g������     �yE_�{�ғ�_02763�z�Ή�
 *  2012-02-17    1.9   SCSK����Ďj     �yE_�{�ғ�_08750�z�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO019A10C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00430';  -- ��v���ԊJ�n���t�擾�G���[
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00072';  -- �K�┄��v��Ǘ��T�}���폜�G���[���b�Z�[�W
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- ���ʌڋq�ʃf�[�^���o�G���[���b�Z�[�W
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00431';  -- �K�┄��v��Ǘ��T�}���o�^�G���[���b�Z�[�W
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- �G���[�I�����b�Z�[�W
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := '';  -- �X�L�b�v�������b�Z�[�W
  /* 2009.11.06 K.Satomura E_T4_00135�Ή� START*/
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00580';  -- �ڋqCD�^����S�����_CD�G���[
  /* 2009.11.06 K.Satomura E_T4_00135�Ή� END */
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00382';  -- ���̓p�����[�^�K�{�G���[���b�Z�[�W
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00250';  -- �p�����[�^�����敪
  cv_tkn_number_15    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00252';  -- �p�����[�^�Ó����`�F�b�N�G���[���b�Z�[�W
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
  -- �g�[�N���R�[�h
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_errmessage       CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_status           CONSTANT VARCHAR2(20) := 'STATUS';
  cv_tkn_processing_name  CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_count            CONSTANT VARCHAR2(20) := 'COUNT';
  /* 2009.11.06 K.Satomura E_T4_00135�Ή� START*/
  cv_tkn_sum_org_code     CONSTANT VARCHAR2(20) := 'SUM_ORG_CODE';
  cv_tkn_group_base_code  CONSTANT VARCHAR2(20) := 'GROUP_BASE_CODE';
  cv_tkn_sales_date       CONSTANT VARCHAR2(20) := 'SALES_DATE';
  cv_tkn_sqlerrm          CONSTANT VARCHAR2(20) := 'SQLERRM';
  /* 2009.11.06 K.Satomura E_T4_00135�Ή� END */
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_entry            CONSTANT VARCHAR2(20) := 'ENTRY';
  -- ���b�Z�[�W�p�Œ蕶����
  cv_tkn_msg_proc_div     CONSTANT VARCHAR2(200) := '�����敪';
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  cv_true                 CONSTANT VARCHAR2(10) := 'TRUE';
  cv_null                 CONSTANT VARCHAR2(10) := 'NULL';
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< �Ɩ��������擾���� >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< ��v���ԊJ�n���擾���� >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'ld_ar_gl_period_from = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< �N�����X�g�擾���� >>';
  cv_debug_msg5_1         CONSTANT VARCHAR2(200) := 'gv_ym_lst_1 = ';
  cv_debug_msg5_2         CONSTANT VARCHAR2(200) := 'gv_ym_lst_2 = ';
  cv_debug_msg5_3         CONSTANT VARCHAR2(200) := 'gv_ym_lst_3 = ';
  cv_debug_msg5_4         CONSTANT VARCHAR2(200) := 'gv_ym_lst_4 = ';
  cv_debug_msg5_5         CONSTANT VARCHAR2(200) := 'gv_ym_lst_5 = ';
  cv_debug_msg5_6         CONSTANT VARCHAR2(200) := 'gv_ym_lst_6 = ';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := '<< �폜�A���o�A�o�͌��� >>';
  cv_debug_msg6_1         CONSTANT VARCHAR2(200) := 'gn_delete_cnt = ';
  cv_debug_msg6_2         CONSTANT VARCHAR2(200) := 'gn_extrct_cnt = ';
  cv_debug_msg6_3         CONSTANT VARCHAR2(200) := 'gn_output_cnt = ';
  cv_debug_msg6_4         CONSTANT VARCHAR2(200) := 'gn_warn_cnt = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := '<< ���ʏ����Ώۃf�[�^���폜���܂��� >>';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := '<< ���ʏ����Ώۃf�[�^���폜���܂��� >>';
  cv_debug_msg_d_acct     CONSTANT VARCHAR2(200) := '<< ���ʌڋq�ʎ擾�o�^ >>';
  cv_debug_msg_d_emp      CONSTANT VARCHAR2(200) := '<< ���ʉc�ƈ��ʎ擾�o�^ >>';
  cv_debug_msg_d_grp      CONSTANT VARCHAR2(200) := '<< ���ʉc�ƃO���[�v�ʎ擾�o�^ >>';
  cv_debug_msg_d_base     CONSTANT VARCHAR2(200) := '<< ���ʋ��_�^�ەʎ擾�o�^ >>';
  cv_debug_msg_d_area     CONSTANT VARCHAR2(200) := '<< ���ʒn��c�ƕ��^���ʎ擾�o�^ >>';
  cv_debug_msg_m_acct     CONSTANT VARCHAR2(200) := '<< ���ʌڋq�ʎ擾�o�^ >>';
  cv_debug_msg_m_emp      CONSTANT VARCHAR2(200) := '<< ���ʉc�ƈ��ʎ擾�o�^ >>';
  cv_debug_msg_m_grp      CONSTANT VARCHAR2(200) := '<< ���ʉc�ƃO���[�v�ʎ擾�o�^ >>';
  cv_debug_msg_m_base     CONSTANT VARCHAR2(200) := '<< ���ʋ��_�^�ەʎ擾�o�^ >>';
  cv_debug_msg_m_area     CONSTANT VARCHAR2(200) := '<< ���ʒn��c�ƕ��^���ʎ擾�o�^ >>';
  cv_debug_msg_rollback   CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>' ;
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< �J�[�\�����I�[�v�����܂��� >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< �J�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< ��O�������ŃJ�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'insert_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others��O';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6       CONSTANT VARCHAR2(200) := 'global_process_expt';
  -- �e�[�u���E�r���[��
  cv_xxcso_sum_visit_sale_rep  CONSTANT VARCHAR2(200) := '�K�┄��v��Ǘ��\�T�}���e�[�u��';
  cv_day_acct_data             CONSTANT VARCHAR2(200) := '���ʌڋq�ʃf�[�^';
  cv_day_acct                  CONSTANT VARCHAR2(200) := '�i���ʌڋq�ʁj';
  cv_day_emp                   CONSTANT VARCHAR2(200) := '�i���ʉc�ƈ��ʁj';
  cv_day_group                 CONSTANT VARCHAR2(200) := '�i���ʉc�ƃO���[�v�ʁj';
  cv_day_base                  CONSTANT VARCHAR2(200) := '�i���ʋ��_�ʁj';
  cv_day_area                  CONSTANT VARCHAR2(200) := '�i���ʒn��c�ƕ��ʁj';
  cv_mon_acct                  CONSTANT VARCHAR2(200) := '�i���ʌڋq�ʁj';
  cv_mon_emp                   CONSTANT VARCHAR2(200) := '�i���ʉc�ƈ��ʁj';
  cv_mon_group                 CONSTANT VARCHAR2(200) := '�i���ʉc�ƃO���[�v�ʁj';
  cv_mon_base                  CONSTANT VARCHAR2(200) := '�i���ʋ��_�ʁj';
  cv_mon_area                  CONSTANT VARCHAR2(200) := '�i���ʒn��c�ƕ��ʁj';
  -- �����敪
  cv_month_date_div_mon        CONSTANT VARCHAR2(1) := '1';       -- �u1�v����
  cv_month_date_div_day        CONSTANT VARCHAR2(1) := '2';       -- �u2�v����
  -- �ڋq�敪
  cv_customer_class_code_10    CONSTANT VARCHAR2(2) := '10';       -- �u10�v�ڋq
  cv_customer_class_code_12    CONSTANT VARCHAR2(2) := '12';       -- �u12�v��l�ڋq
  cv_customer_class_code_15    CONSTANT VARCHAR2(2) := '15';       -- �u15�v����
  cv_customer_class_code_16    CONSTANT VARCHAR2(2) := '16';       -- �u16�v�≮������
  cv_customer_class_code_17    CONSTANT VARCHAR2(2) := '17';       -- �u17�v�v��
  cv_customer_class_code_13    CONSTANT VARCHAR2(2) := '13';       -- �u13�v�@�l�ڋq
  cv_customer_class_code_14    CONSTANT VARCHAR2(2) := '14';       -- �u14�v���|���Ǘ��ڋq
  -- �ڋq�X�e�[�^�X
  cv_customer_status_10        CONSTANT VARCHAR2(2) := '10';       -- �u10�vMC���
  cv_customer_status_20        CONSTANT VARCHAR2(2) := '20';       -- �u20�vMC
  cv_customer_status_25        CONSTANT VARCHAR2(2) := '25';       -- �u25�vSP���ύ�
  cv_customer_status_30        CONSTANT VARCHAR2(2) := '30';       -- �u30�v���F��
  cv_customer_status_40        CONSTANT VARCHAR2(2) := '40';       -- �u40�v�ڋq
  cv_customer_status_50        CONSTANT VARCHAR2(2) := '50';       -- �u50�v�x�~
  cv_customer_status_80        CONSTANT VARCHAR2(2) := '80';       -- �u80�v�X����
  cv_customer_status_90        CONSTANT VARCHAR2(2) := '90';       -- �u90�v���~����
  cv_customer_status_99        CONSTANT VARCHAR2(2) := '99';       -- �u99�v�ΏۊO
  -- �K��Ώۋ敪
  cv_vist_target_div_1         CONSTANT VARCHAR2(1) := '1';        -- �u1�v
  -- ��ʁ^���̋@�^MC
  cv_emp_div_gen               CONSTANT VARCHAR2(1) := '1';        -- �u1�v���
  cv_emp_div_jihan             CONSTANT VARCHAR2(1) := '2';        -- �u2�v���̋@
  cv_emp_div_mc                CONSTANT VARCHAR2(1) := '3';        -- �u3�vMC
  -- �[�i�`�ԋ敪
  cv_delivery_pattern_cls_5    CONSTANT VARCHAR2(1) := '5';        -- �u5�v�����_�q�ɔ���
  -- �L���K��敪
  cv_eff_visit_flag_1          CONSTANT VARCHAR2(1) := '1';        -- �u1�v�L��
  -- �W�v�g�D���
  cv_sum_org_type_accnt        CONSTANT VARCHAR2(1) := '1';        -- �u1�v�ڋq�R�[�h
  cv_sum_org_type_emp          CONSTANT VARCHAR2(1) := '2';        -- �u2�v�]�ƈ��ԍ�
  cv_sum_org_type_group        CONSTANT VARCHAR2(1) := '3';        -- �u3�v�c�ƃO���[�v
  cv_sum_org_type_dept         CONSTANT VARCHAR2(1) := '4';        -- �u4�v����R�[�h
  cv_sum_org_type_area         CONSTANT VARCHAR2(1) := '5';        -- �u5�v�n��c�ƕ��R�[�h
  -- �V�K�|�C���g�敪
  cv_new_point_div_1           CONSTANT VARCHAR2(1) := '1';        -- �u1�v�V�K
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  -- �����敪
  cv_process_div_ins           CONSTANT VARCHAR2(1) := '1';        -- �u1�v�쐬
  cv_process_div_del           CONSTANT VARCHAR2(1) := '9';        -- �u9�v�폜
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_delete_cnt        NUMBER;              -- �폜����
  gn_extrct_cnt        NUMBER;              -- ���o����
  gn_output_cnt        NUMBER;              -- �o�͌���
  -- �Ɩ�������
  gd_process_date      DATE;
  -- AR��v���ԊJ�n��
  gd_ar_gl_period_from DATE;
  -- �N�����X�g
  gv_ym_lst_1          VARCHAR2(8);
  gv_ym_lst_2          VARCHAR2(8);
  gv_ym_lst_3          VARCHAR2(8);
  gv_ym_lst_4          VARCHAR2(8);
  gv_ym_lst_5          VARCHAR2(8);
  gv_ym_lst_6          VARCHAR2(8);
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  -- �p�����[�^�i�[�p
  gv_prm_process_div   VARCHAR2(1);         -- �����敪
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
  -- ===============================
  -- ���[�U�[��`�J�[�\���^
  -- ===============================
  -- ���ʌڋq�ʃf�[�^�擾�p�J�[�\��
  CURSOR g_get_day_acct_data_cur
  IS
/* 20090519_Ogawa_T1_1024 START*/
/* 20090519_Ogawa_T1_1037 START*/
/* 20090519_Ogawa_T1_1038 START*/
--  SELECT
--    union_res.sum_org_code                sum_org_code         -- �ڋq�R�[�h
--    union_res.group_base_code             group_base_code      -- �O���[�v���_�R�[�h
--   ,union_res.gvm_type                    gvm_type             -- ��ʁ^���̋@�^�l�b
--   ,MAX(union_res.cust_new_num      )     cust_new_num         -- �ڋq�����i�V�K�j
--   ,MAX(union_res.cust_vd_new_num   )     cust_vd_new_num      -- �ڋq�����iVD�F�V�K�j
--   ,MAX(union_res.cust_other_new_num)     cust_other_new_num   -- �ڋq�����iVD�ȊO�F�V�K�j
--   ,union_res.sales_date                  sales_date           -- �̔��N�����^�̔��N��
--   ,MAX(union_res.tgt_amt              )  tgt_amt              -- ����v��
--   ,MAX(union_res.tgt_vd_amt           )  tgt_vd_amt           -- ����v��iVD�j
--   ,MAX(union_res.tgt_other_amt        )  tgt_other_amt        -- ����v��iVD�ȊO�j
--   ,MAX(union_res.tgt_vis_num          )  tgt_vis_num          -- �K��v��
--   ,MAX(union_res.tgt_vis_vd_num       )  tgt_vis_vd_num       -- �K��v��iVD�j
--   ,MAX(union_res.tgt_vis_other_num    )  tgt_vis_other_num    -- �K��v��iVD�ȊO�j
--   ,MAX(union_res.rslt_amt             )  rslt_amt             -- �������
--   ,MAX(union_res.rslt_new_amt         )  rslt_new_amt         -- ������сi�V�K�j
--   ,MAX(union_res.rslt_vd_new_amt      )  rslt_vd_new_amt      -- ������сiVD�F�V�K�j
--   ,MAX(union_res.rslt_vd_amt          )  rslt_vd_amt          -- ������сiVD�j
--   ,MAX(union_res.rslt_other_new_amt   )  rslt_other_new_amt   -- ������сiVD�ȊO�F�V�K�j
--   ,MAX(union_res.rslt_other_amt       )  rslt_other_amt       -- ������сiVD�ȊO�j
--   ,MAX(union_res.rslt_center_amt      )  rslt_center_amt      -- �������_�Q�������
--   ,MAX(union_res.rslt_center_vd_amt   )  rslt_center_vd_amt   -- �������_�Q������сiVD�j
--   ,MAX(union_res.rslt_center_other_amt)  rslt_center_other_amt-- �������_�Q������сiVD�ȊO�j
--   ,MAX(union_res.vis_num              )  vis_num              -- �K�����
--   ,MAX(union_res.vis_new_num          )  vis_new_num          -- �K����сi�V�K�j
--   ,MAX(union_res.vis_vd_new_num       )  vis_vd_new_num       -- �K����сiVD�F�V�K�j
--   ,MAX(union_res.vis_vd_num           )  vis_vd_num           -- �K����сiVD�j
--   ,MAX(union_res.vis_other_new_num    )  vis_other_new_num    -- �K����сiVD�ȊO�F�V�K�j
--   ,MAX(union_res.vis_other_num        )  vis_other_num        -- �K����сiVD�ȊO�j
--   ,MAX(union_res.vis_mc_num           )  vis_mc_num           -- �K����сiMC�j
--   ,MAX(union_res.vis_sales_num        )  vis_sales_num        -- �L������
--   ,MAX(union_res.vis_a_num            )  vis_a_num            -- �K��`����
--   ,MAX(union_res.vis_b_num            )  vis_b_num            -- �K��a����
--   ,MAX(union_res.vis_c_num            )  vis_c_num            -- �K��b����
--   ,MAX(union_res.vis_d_num            )  vis_d_num            -- �K��c����
--   ,MAX(union_res.vis_e_num            )  vis_e_num            -- �K��d����
--   ,MAX(union_res.vis_f_num            )  vis_f_num            -- �K��e����
--   ,MAX(union_res.vis_g_num            )  vis_g_num            -- �K��f����
--   ,MAX(union_res.vis_h_num            )  vis_h_num            -- �K��g����
--   ,MAX(union_res.vis_i_num            )  vis_i_num            -- �K���@����
--   ,MAX(union_res.vis_j_num            )  vis_j_num            -- �K��i����
--   ,MAX(union_res.vis_k_num            )  vis_k_num            -- �K��j����
--   ,MAX(union_res.vis_l_num            )  vis_l_num            -- �K��k����
--   ,MAX(union_res.vis_m_num            )  vis_m_num            -- �K��l����
--   ,MAX(union_res.vis_n_num            )  vis_n_num            -- �K��m����
--   ,MAX(union_res.vis_o_num            )  vis_o_num            -- �K��n����
--   ,MAX(union_res.vis_p_num            )  vis_p_num            -- �K��o����
--   ,MAX(union_res.vis_q_num            )  vis_q_num            -- �K��p����
--   ,MAX(union_res.vis_r_num            )  vis_r_num            -- �K��q����
--   ,MAX(union_res.vis_s_num            )  vis_s_num            -- �K��r����
--   ,MAX(union_res.vis_t_num            )  vis_t_num            -- �K��s����
--   ,MAX(union_res.vis_u_num            )  vis_u_num            -- �K��t����
--   ,MAX(union_res.vis_v_num            )  vis_v_num            -- �K��u����
--   ,MAX(union_res.vis_w_num            )  vis_w_num            -- �K��v����
--   ,MAX(union_res.vis_x_num            )  vis_x_num            -- �K��w����
--   ,MAX(union_res.vis_y_num            )  vis_y_num            -- �K��x����
--   ,MAX(union_res.vis_z_num            )  vis_z_num            -- �K��y����
--  FROM
--    (
--     SELECT
--       inn_v.sum_org_code               sum_org_code         -- �ڋq�R�[�h
--      ,inn_v.gvm_type                   gvm_type             -- ��ʁ^���̋@�^�l�b
--      ,inn_v.cust_new_num               cust_new_num         -- �ڋq�����i�V�K�j
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            AND  (inn_v.cust_new_num = 1)
--            THEN  1
--       END                              cust_vd_new_num      -- �ڋq�����iVD�F�V�K�j
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            AND  (inn_v.cust_new_num = 1)
--            THEN  1
--       END                              cust_other_new_num   -- �ڋq�����iVD�ȊO�F�V�K�j
--      ,inn_v.sales_date                 sales_date           -- �̔��N�����^�̔��N��
--      ,inn_v.tgt_amt                    tgt_amt              -- ����v��
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            THEN  inn_v.tgt_amt
--       END                              tgt_vd_amt           -- ����v��iVD�j
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            THEN  inn_v.tgt_amt
--       END                              tgt_other_amt        -- ����v��iVD�ȊO�j
--      ,inn_v.tgt_vis_num                              tgt_vis_num          -- �K��v��
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            THEN  inn_v.tgt_vis_num
--       END                              tgt_vis_vd_num       -- �K��v��iVD�j
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            THEN  inn_v.tgt_vis_num
--       END                              tgt_vis_other_num    -- �K��v��iVD�ȊO�j
--      ,inn_v.rslt_amt                   rslt_amt             -- �������
--      ,inn_v.rslt_new_amt               rslt_new_amt         -- ������сi�V�K�j
--      ,inn_v.rslt_vd_new_amt            rslt_vd_new_amt      -- ������сiVD�F�V�K�j
--      ,inn_v.rslt_vd_amt                rslt_vd_amt          -- ������сiVD�j
--      ,inn_v.rslt_other_new_amt         rslt_other_new_amt   -- ������сiVD�ȊO�F�V�K�j
--      ,inn_v.rslt_other_amt             rslt_other_amt       -- ������сiVD�ȊO�j
--      ,inn_v.rslt_center_amt            rslt_center_amt      -- �������_�Q�������
--      ,inn_v.rslt_center_vd_amt         rslt_center_vd_amt   -- �������_�Q������сiVD�j
--      ,inn_v.rslt_center_other_amt      rslt_center_other_amt-- �������_�Q������сiVD�ȊO�j
--      ,inn_v.vis_num                    vis_num              -- �K�����
--      ,inn_v.vis_new_num                vis_new_num          -- �K����сi�V�K�j
--      ,inn_v.vis_vd_new_num             vis_vd_new_num       -- �K����сiVD�F�V�K�j
--      ,inn_v.vis_vd_num                 vis_vd_num           -- �K����сiVD�j
--      ,inn_v.vis_other_new_num          vis_other_new_num    -- �K����сiVD�ȊO�F�V�K�j
--      ,inn_v.vis_other_num              vis_other_num        -- �K����сiVD�ȊO�j
--      ,inn_v.vis_mc_num                 vis_mc_num           -- �K����сiMC�j
--      ,inn_v.vis_sales_num              vis_sales_num        -- �L������
--      ,inn_v.vis_a_num                  vis_a_num            -- �K��`����
--      ,inn_v.vis_b_num                  vis_b_num            -- �K��a����
--      ,inn_v.vis_c_num                  vis_c_num            -- �K��b����
--      ,inn_v.vis_d_num                  vis_d_num            -- �K��c����
--      ,inn_v.vis_e_num                  vis_e_num            -- �K��d����
--      ,inn_v.vis_f_num                  vis_f_num            -- �K��e����
--      ,inn_v.vis_g_num                  vis_g_num            -- �K��f����
--      ,inn_v.vis_h_num                  vis_h_num            -- �K��g����
--      ,inn_v.vis_i_num                  vis_i_num            -- �K���@����
--      ,inn_v.vis_j_num                  vis_j_num            -- �K��i����
--      ,inn_v.vis_k_num                  vis_k_num            -- �K��j����
--      ,inn_v.vis_l_num                  vis_l_num            -- �K��k����
--      ,inn_v.vis_m_num                  vis_m_num            -- �K��l����
--      ,inn_v.vis_n_num                  vis_n_num            -- �K��m����
--      ,inn_v.vis_o_num                  vis_o_num            -- �K��n����
--      ,inn_v.vis_p_num                  vis_p_num            -- �K��o����
--      ,inn_v.vis_q_num                  vis_q_num            -- �K��p����
--      ,inn_v.vis_r_num                  vis_r_num            -- �K��q����
--      ,inn_v.vis_s_num                  vis_s_num            -- �K��r����
--      ,inn_v.vis_t_num                  vis_t_num            -- �K��s����
--      ,inn_v.vis_u_num                  vis_u_num            -- �K��t����
--      ,inn_v.vis_v_num                  vis_v_num            -- �K��u����
--      ,inn_v.vis_w_num                  vis_w_num            -- �K��v����
--      ,inn_v.vis_x_num                  vis_x_num            -- �K��w����
--      ,inn_v.vis_y_num                  vis_y_num            -- �K��x����
--      ,inn_v.vis_z_num                  vis_z_num            -- �K��y����
--     FROM
--       (
--        SELECT
--          xcav.account_number              sum_org_code         -- �ڋq�R�[�h
--         ,CASE WHEN (
--                     xcav.customer_status IN ('20', '25', '30')
--                    )
--               THEN  cv_emp_div_mc
--               WHEN (
--                     xxcso_route_common_pkg.iscustomervendor(xcav.business_low_type)
--                       = cv_true
--                    )
--               THEN  cv_emp_div_jihan
--               ELSE  cv_emp_div_gen
--          END                              gvm_type             -- ��ʁ^���̋@�^�l�b
--         ,CASE WHEN (
--                     TO_CHAR(xcav.cnvs_date, 'YYYYMMDD') = xasp.plan_date
--                    )
--                AND (
--                     xcav.new_point_div = cv_new_point_div_1
--                    )
--                AND (
--                     xcav.cnvs_business_person = xcrv2.employee_number
--                    )
--               THEN  1
--          END                              cust_new_num         -- �ڋq�����i�V�K�j
--         ,xasp.plan_date                   sales_date           -- �̔��N�����^�̔��N��
--         ,xasp.sales_plan_day_amt          tgt_amt              -- ����v��
--         ,CASE WHEN (
--                     xcav.vist_target_div = cv_vist_target_div_1
--                    )
--                AND (xasp.sales_plan_day_amt > 0
--                    )
--               THEN  1
--               ELSE  NULL
--          END                              tgt_vis_num          -- �K��v��
--         ,NULL                             rslt_amt             -- �������
--         ,NULL                             rslt_new_amt         -- ������сi�V�K�j
--         ,NULL                             rslt_vd_new_amt      -- ������сiVD�F�V�K�j
--         ,NULL                             rslt_vd_amt          -- ������сiVD�j
--         ,NULL                             rslt_other_new_amt   -- ������сiVD�ȊO�F�V�K�j
--         ,NULL                             rslt_other_amt       -- ������сiVD�ȊO�j
--         ,NULL                             rslt_center_amt      -- �������_�Q�������
--         ,NULL                             rslt_center_vd_amt   -- �������_�Q������сiVD�j
--         ,NULL                             rslt_center_other_amt-- �������_�Q������сiVD�ȊO�j
--         ,NULL                             vis_num              -- �K�����
--         ,NULL                             vis_new_num          -- �K����сi�V�K�j
--         ,NULL                             vis_vd_new_num       -- �K����сiVD�F�V�K�j
--         ,NULL                             vis_vd_num           -- �K����сiVD�j
--         ,NULL                             vis_other_new_num    -- �K����сiVD�ȊO�F�V�K�j
--         ,NULL                             vis_other_num        -- �K����сiVD�ȊO�j
--         ,NULL                             vis_mc_num           -- �K����сiMC�j
--         ,NULL                             vis_sales_num        -- �L������
--         ,NULL                             vis_a_num            -- �K��`����
--         ,NULL                             vis_b_num            -- �K��a����
--         ,NULL                             vis_c_num            -- �K��b����
--         ,NULL                             vis_d_num            -- �K��c����
--         ,NULL                             vis_e_num            -- �K��d����
--         ,NULL                             vis_f_num            -- �K��e����
--         ,NULL                             vis_g_num            -- �K��f����
--         ,NULL                             vis_h_num            -- �K��g����
--         ,NULL                             vis_i_num            -- �K���@����
--         ,NULL                             vis_j_num            -- �K��i����
--         ,NULL                             vis_k_num            -- �K��j����
--         ,NULL                             vis_l_num            -- �K��k����
--         ,NULL                             vis_m_num            -- �K��l����
--         ,NULL                             vis_n_num            -- �K��m����
--         ,NULL                             vis_o_num            -- �K��n����
--         ,NULL                             vis_p_num            -- �K��o����
--         ,NULL                             vis_q_num            -- �K��p����
--         ,NULL                             vis_r_num            -- �K��q����
--         ,NULL                             vis_s_num            -- �K��r����
--         ,NULL                             vis_t_num            -- �K��s����
--         ,NULL                             vis_u_num            -- �K��t����
--         ,NULL                             vis_v_num            -- �K��u����
--         ,NULL                             vis_w_num            -- �K��v����
--         ,NULL                             vis_x_num            -- �K��w����
--         ,NULL                             vis_y_num            -- �K��x����
--         ,NULL                             vis_z_num            -- �K��y����
--        FROM
--          xxcso_cust_accounts_v xcav  -- �ڋq�}�X�^�r���[
--         ,xxcso_account_sales_plans xasp  -- �ڋq�ʔ���v��e�[�u��
--         ,xxcso_cust_resources_v2 xcrv2  -- �ڋq�S���c�ƈ��i�ŐV�j�r���[
--        WHERE  xcav.account_number = xasp.account_number  -- �ڋq�R�[�h
--          AND  xasp.plan_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
--                                  AND TO_CHAR(LAST_DAY(gd_process_date)     , 'YYYYMMDD') -- �N����
--          AND  xasp.month_date_div = cv_month_date_div_day  -- �����敪
--          AND  ((
--                      (
--                       xcav.customer_class_code IS NULL -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_10
--                                                ,cv_customer_status_20
--                                               )  -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_10 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_25
--                                                ,cv_customer_status_30
--                                                ,cv_customer_status_40
--                                                ,cv_customer_status_50
--                                               )  -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_12 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_30
--                                                ,cv_customer_status_40
--                                               )  -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_15 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_16 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_17 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                      )
--               ))
--          AND  xcav.account_number = xcrv2.account_number(+)
--       ) inn_v
--     -- �ڋq�ʔ���v��e�[�u���i���ʁj
--     UNION ALL
--     SELECT
--       inn_v.sum_org_code               sum_org_code         -- �ڋq�R�[�h
--      ,inn_v.gvm_type                   gvm_type             -- ��ʁ^���̋@�^�l�b
--      ,inn_v.cust_new_num               cust_new_num         -- �ڋq�����i�V�K�j
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            AND  (inn_v.cust_new_num = 1)
--            THEN  1
--       END                              cust_vd_new_num      -- �ڋq�����iVD�F�V�K�j
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            AND  (inn_v.cust_new_num = 1)
--            THEN  1
--       END                              cust_other_new_num   -- �ڋq�����iVD�ȊO�F�V�K�j
--      ,inn_v.sales_date                 sales_date           -- �̔��N�����^�̔��N��
--      ,inn_v.tgt_amt                    tgt_amt              -- ����v��
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            THEN  inn_v.tgt_amt
--       END                              tgt_vd_amt           -- ����v��iVD�j
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            THEN  inn_v.tgt_amt
--       END                              tgt_other_amt        -- ����v��iVD�ȊO�j
--      ,inn_v.tgt_vis_num                              tgt_vis_num          -- �K��v��
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            THEN  inn_v.tgt_vis_num
--       END                              tgt_vis_vd_num       -- �K��v��iVD�j
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            THEN  inn_v.tgt_vis_num
--       END                              tgt_vis_other_num    -- �K��v��iVD�ȊO�j
--      ,inn_v.rslt_amt                   rslt_amt             -- �������
--      ,inn_v.rslt_new_amt               rslt_new_amt         -- ������сi�V�K�j
--      ,inn_v.rslt_vd_new_amt            rslt_vd_new_amt      -- ������сiVD�F�V�K�j
--      ,inn_v.rslt_vd_amt                rslt_vd_amt          -- ������сiVD�j
--      ,inn_v.rslt_other_new_amt         rslt_other_new_amt   -- ������сiVD�ȊO�F�V�K�j
--      ,inn_v.rslt_other_amt             rslt_other_amt       -- ������сiVD�ȊO�j
--      ,inn_v.rslt_center_amt            rslt_center_amt      -- �������_�Q�������
--      ,inn_v.rslt_center_vd_amt         rslt_center_vd_amt   -- �������_�Q������сiVD�j
--      ,inn_v.rslt_center_other_amt      rslt_center_other_amt-- �������_�Q������сiVD�ȊO�j
--      ,inn_v.vis_num                    vis_num              -- �K�����
--      ,inn_v.vis_new_num                vis_new_num          -- �K����сi�V�K�j
--      ,inn_v.vis_vd_new_num             vis_vd_new_num       -- �K����сiVD�F�V�K�j
--      ,inn_v.vis_vd_num                 vis_vd_num           -- �K����сiVD�j
--      ,inn_v.vis_other_new_num          vis_other_new_num    -- �K����сiVD�ȊO�F�V�K�j
--      ,inn_v.vis_other_num              vis_other_num        -- �K����сiVD�ȊO�j
--      ,inn_v.vis_mc_num                 vis_mc_num           -- �K����сiMC�j
--      ,inn_v.vis_sales_num              vis_sales_num        -- �L������
--      ,inn_v.vis_a_num                  vis_a_num            -- �K��`����
--      ,inn_v.vis_b_num                  vis_b_num            -- �K��a����
--      ,inn_v.vis_c_num                  vis_c_num            -- �K��b����
--      ,inn_v.vis_d_num                  vis_d_num            -- �K��c����
--      ,inn_v.vis_e_num                  vis_e_num            -- �K��d����
--      ,inn_v.vis_f_num                  vis_f_num            -- �K��e����
--      ,inn_v.vis_g_num                  vis_g_num            -- �K��f����
--      ,inn_v.vis_h_num                  vis_h_num            -- �K��g����
--      ,inn_v.vis_i_num                  vis_i_num            -- �K���@����
--      ,inn_v.vis_j_num                  vis_j_num            -- �K��i����
--      ,inn_v.vis_k_num                  vis_k_num            -- �K��j����
--      ,inn_v.vis_l_num                  vis_l_num            -- �K��k����
--      ,inn_v.vis_m_num                  vis_m_num            -- �K��l����
--      ,inn_v.vis_n_num                  vis_n_num            -- �K��m����
--      ,inn_v.vis_o_num                  vis_o_num            -- �K��n����
--      ,inn_v.vis_p_num                  vis_p_num            -- �K��o����
--      ,inn_v.vis_q_num                  vis_q_num            -- �K��p����
--      ,inn_v.vis_r_num                  vis_r_num            -- �K��q����
--      ,inn_v.vis_s_num                  vis_s_num            -- �K��r����
--      ,inn_v.vis_t_num                  vis_t_num            -- �K��s����
--      ,inn_v.vis_u_num                  vis_u_num            -- �K��t����
--      ,inn_v.vis_v_num                  vis_v_num            -- �K��u����
--      ,inn_v.vis_w_num                  vis_w_num            -- �K��v����
--      ,inn_v.vis_x_num                  vis_x_num            -- �K��w����
--      ,inn_v.vis_y_num                  vis_y_num            -- �K��x����
--      ,inn_v.vis_z_num                  vis_z_num            -- �K��y����
--     FROM
--       (
--        SELECT
--          xcav.account_number              sum_org_code         -- �ڋq�R�[�h
--         ,CASE WHEN (
--                     xcav.customer_status IN ('20', '25', '30')
--                    )
--               THEN  cv_emp_div_mc
--               WHEN (
--                     xxcso_route_common_pkg.iscustomervendor(xcav.business_low_type)
--                       = cv_true
--                    )
--               THEN  cv_emp_div_jihan
--               ELSE  cv_emp_div_gen
--          END                              gvm_type             -- ��ʁ^���̋@�^�l�b
--         ,CASE WHEN (
--                     TO_CHAR(xcav.cnvs_date, 'YYYYMM') = xasp.year_month
--                    )
--                AND (
--                     xcav.new_point_div = cv_new_point_div_1
--                    )
--                AND (
--                     xcav.cnvs_business_person = xcrv2.employee_number
--                    )
--               THEN  1
--          END                              cust_new_num         -- �ڋq�����i�V�K�j
--         ,xasp.year_month || '01'          sales_date           -- �̔��N�����^�̔��N��
--         ,xasp.sales_plan_month_amt        tgt_amt              -- ����v��
--         ,CASE WHEN (
--                     xcav.vist_target_div = cv_vist_target_div_1
--                    )
--                AND (xasp.sales_plan_month_amt > 0
--                    )
--               THEN  1
--               ELSE  NULL
--          END                              tgt_vis_num          -- �K��v��
--         ,NULL                             rslt_amt             -- �������
--         ,NULL                             rslt_new_amt         -- ������сi�V�K�j
--         ,NULL                             rslt_vd_new_amt      -- ������сiVD�F�V�K�j
--         ,NULL                             rslt_vd_amt          -- ������сiVD�j
--         ,NULL                             rslt_other_new_amt   -- ������сiVD�ȊO�F�V�K�j
--         ,NULL                             rslt_other_amt       -- ������сiVD�ȊO�j
--         ,NULL                             rslt_center_amt      -- �������_�Q�������
--         ,NULL                             rslt_center_vd_amt   -- �������_�Q������сiVD�j
--         ,NULL                             rslt_center_other_amt-- �������_�Q������сiVD�ȊO�j
--         ,NULL                             vis_num              -- �K�����
--         ,NULL                             vis_new_num          -- �K����сi�V�K�j
--         ,NULL                             vis_vd_new_num       -- �K����сiVD�F�V�K�j
--         ,NULL                             vis_vd_num           -- �K����сiVD�j
--         ,NULL                             vis_other_new_num    -- �K����сiVD�ȊO�F�V�K�j
--         ,NULL                             vis_other_num        -- �K����сiVD�ȊO�j
--         ,NULL                             vis_mc_num           -- �K����сiMC�j
--         ,NULL                             vis_sales_num        -- �L������
--         ,NULL                             vis_a_num            -- �K��`����
--         ,NULL                             vis_b_num            -- �K��a����
--         ,NULL                             vis_c_num            -- �K��b����
--         ,NULL                             vis_d_num            -- �K��c����
--         ,NULL                             vis_e_num            -- �K��d����
--         ,NULL                             vis_f_num            -- �K��e����
--         ,NULL                             vis_g_num            -- �K��f����
--         ,NULL                             vis_h_num            -- �K��g����
--         ,NULL                             vis_i_num            -- �K���@����
--         ,NULL                             vis_j_num            -- �K��i����
--         ,NULL                             vis_k_num            -- �K��j����
--         ,NULL                             vis_l_num            -- �K��k����
--         ,NULL                             vis_m_num            -- �K��l����
--         ,NULL                             vis_n_num            -- �K��m����
--         ,NULL                             vis_o_num            -- �K��n����
--         ,NULL                             vis_p_num            -- �K��o����
--         ,NULL                             vis_q_num            -- �K��p����
--         ,NULL                             vis_r_num            -- �K��q����
--         ,NULL                             vis_s_num            -- �K��r����
--         ,NULL                             vis_t_num            -- �K��s����
--         ,NULL                             vis_u_num            -- �K��t����
--         ,NULL                             vis_v_num            -- �K��u����
--         ,NULL                             vis_w_num            -- �K��v����
--         ,NULL                             vis_x_num            -- �K��w����
--         ,NULL                             vis_y_num            -- �K��x����
--         ,NULL                             vis_z_num            -- �K��y����
--        FROM
--          xxcso_cust_accounts_v xcav  -- �ڋq�}�X�^�r���[
--         ,xxcso_account_sales_plans xasp  -- �ڋq�ʔ���v��e�[�u��
--         ,xxcso_cust_resources_v2 xcrv2  -- �ڋq�S���c�ƈ��i�ŐV�j�r���[
--        WHERE  xcav.account_number = xasp.account_number  -- �ڋq�R�[�h
--          AND  xasp.year_month BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMM')
--                                   AND TO_CHAR(gd_process_date, 'YYYYMM')  -- �N��
--          AND  xasp.month_date_div = cv_month_date_div_mon  -- �����敪
--          AND  EXISTS
--               (
--                SELECT  xasp_m.account_number account_number
--                FROM  xxcso_account_sales_plans xasp_m  -- �ڋq�ʔ���v��e�[�u���i���ʁj
--                WHERE  xasp_m.account_number = xasp.account_number  -- �ڋq�R�[�h
--                  AND  xasp_m.year_month = xasp.year_month  -- �N��
--                  AND  xasp.month_date_div = cv_month_date_div_day  -- �����敪
--               )
--          AND  ((
--                      (
--                       xcav.customer_class_code IS NULL -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_10
--                                                ,cv_customer_status_20
--                                               )  -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_10 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_25
--                                                ,cv_customer_status_30
--                                                ,cv_customer_status_40
--                                                ,cv_customer_status_50
--                                               )  -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_12 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_30
--                                                ,cv_customer_status_40
--                                               )  -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_15 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_16 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_17 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                      )
--               ))
--          AND  xcav.account_number = xcrv2.account_number(+)
--       ) inn_v
--     -- �ڋq�ʔ���v��e�[�u���i���ʁj
--     UNION ALL
--     SELECT
--       inn_v.sum_org_code               sum_org_code         -- �ڋq�R�[�h
--      ,inn_v.gvm_type                   gvm_type             -- ��ʁ^���̋@�^�l�b
--      ,MAX(
--           inn_v.cust_new_num
--          )                             cust_new_num         -- �ڋq�����i�V�K�j
--      ,MAX(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  1
--           END
--          )                             cust_vd_new_num      -- �ڋq�����iVD�F�V�K�j
--      ,MAX(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  1
--           END
--          )                             cust_other_new_num   -- �ڋq�����iVD�ȊO�F�V�K�j
--      ,inn_v.sales_date                 sales_date           -- �̔��N�����^�̔��N��
--      ,NULL                             tgt_amt              -- ����v��
--      ,NULL                             tgt_vd_amt           -- ����v��iVD�j
--      ,NULL                             tgt_other_amt        -- ����v��iVD�ȊO�j
--      ,NULL                             tgt_vis_num          -- �K��v��
--      ,NULL                             tgt_vis_vd_num       -- �K��v��iVD�j
--      ,NULL                             tgt_vis_other_num    -- �K��v��iVD�ȊO�j
--      ,SUM(inn_v.pure_amount)           rslt_amt             -- �������
--      ,SUM(
--           CASE WHEN (inn_v.cust_new_num = 1)
--                THEN  inn_v.pure_amount
--           END
--          )                             rslt_new_amt         -- ������сi�V�K�j
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  inn_v.pure_amount
--           END
--          )                             rslt_vd_new_amt      -- ������сiVD�F�V�K�j
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                THEN  inn_v.pure_amount
--           END
--          )                            rslt_vd_amt          -- ������сiVD�j
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  inn_v.pure_amount
--           END
--          )                             rslt_other_new_amt   -- ������сiVD�ȊO�F�V�K�j
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                THEN  inn_v.pure_amount
--           END
--          )                             rslt_other_amt       -- ������сiVD�ȊO�j
--      ,SUM(inn_v.pure_amount_2)         rslt_center_amt      -- �������_�Q�������
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                THEN inn_v.pure_amount_2
--                ELSE NULL
--                END
--          )                             rslt_center_vd_amt   -- �������_�Q������сiVD�j
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                THEN inn_v.pure_amount_2
--                ELSE NULL
--                END
--          )                             rslt_center_other_amt-- �������_�Q������сiVD�ȊO�j
--      ,NULL                             vis_num              -- �K�����
--      ,NULL                             vis_new_num          -- �K����сi�V�K�j
--      ,NULL                             vis_vd_new_num       -- �K����сiVD�F�V�K�j
--      ,NULL                             vis_vd_num           -- �K����сiVD�j
--      ,NULL                             vis_other_new_num    -- �K����сiVD�ȊO�F�V�K�j
--      ,NULL                             vis_other_num        -- �K����сiVD�ȊO�j
--      ,NULL                             vis_mc_num           -- �K����сiMC�j
--      ,NULL                             vis_sales_num        -- �L������
--      ,NULL                             vis_a_num            -- �K��`����
--      ,NULL                             vis_b_num            -- �K��a����
--      ,NULL                             vis_c_num            -- �K��b����
--      ,NULL                             vis_d_num            -- �K��c����
--      ,NULL                             vis_e_num            -- �K��d����
--      ,NULL                             vis_f_num            -- �K��e����
--      ,NULL                             vis_g_num            -- �K��f����
--      ,NULL                             vis_h_num            -- �K��g����
--      ,NULL                             vis_i_num            -- �K���@����
--      ,NULL                             vis_j_num            -- �K��i����
--      ,NULL                             vis_k_num            -- �K��j����
--      ,NULL                             vis_l_num            -- �K��k����
--      ,NULL                             vis_m_num            -- �K��l����
--      ,NULL                             vis_n_num            -- �K��m����
--      ,NULL                             vis_o_num            -- �K��n����
--      ,NULL                             vis_p_num            -- �K��o����
--      ,NULL                             vis_q_num            -- �K��p����
--      ,NULL                             vis_r_num            -- �K��q����
--      ,NULL                             vis_s_num            -- �K��r����
--      ,NULL                             vis_t_num            -- �K��s����
--      ,NULL                             vis_u_num            -- �K��t����
--      ,NULL                             vis_v_num            -- �K��u����
--      ,NULL                             vis_w_num            -- �K��v����
--      ,NULL                             vis_x_num            -- �K��w����
--      ,NULL                             vis_y_num            -- �K��x����
--      ,NULL                             vis_z_num            -- �K��y����
--     FROM
--       (
--        SELECT
--          xcav.account_number              sum_org_code         -- �ڋq�R�[�h
--         ,CASE WHEN (
--                     xcav.customer_status IN ('20', '25', '30')
--                    )
--               THEN  cv_emp_div_mc
--               WHEN (
--                     xxcso_route_common_pkg.iscustomervendor(xcav.business_low_type)
--                       = cv_true
--                    )
--               THEN  cv_emp_div_jihan
--               ELSE  cv_emp_div_gen
--          END                              gvm_type             -- ��ʁ^���̋@�^�l�b
--         ,CASE WHEN (
--                     TRUNC(xcav.cnvs_date) = TRUNC(xsv.delivery_date)
--                    )
--                AND (
--                     xcav.new_point_div = cv_new_point_div_1
--                    )
--                AND (
--                     xcav.cnvs_business_person = xcrv2.employee_number
--                    )
--               THEN  1
--          END                              cust_new_num         -- �ڋq�����i�V�K�j
--         ,TO_CHAR(xsv.delivery_date, 'YYYYMMDD')
--                                           sales_date           -- �̔��N�����^�̔��N��
--         ,xsv.pure_amount                  pure_amount          -- �{�̋��z
--         ,CASE WHEN xsv.delivery_pattern_class = cv_delivery_pattern_cls_5
--               THEN xsv.pure_amount
--               ELSE NULL
--          END                              pure_amount_2        -- �{�̋��z2
--        FROM
--          xxcso_cust_accounts_v xcav  -- �ڋq�}�X�^�r���[
--         ,xxcso_sales_v xsv  -- ������уr���[
--         ,xxcso_cust_resources_v2 xcrv2  -- �ڋq�S���c�ƈ��i�ŐV�j�r���[
--        WHERE  xcav.account_number = xsv.account_number  -- �ڋq�R�[�h
--          AND  xsv.delivery_date BETWEEN gd_ar_gl_period_from
--                                     AND gd_process_date  -- �[�i��
--          AND  ((
--                      (
--                       xcav.customer_class_code IS NULL -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_10
--                                                ,cv_customer_status_20
--                                               )  -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_10 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_25
--                                                ,cv_customer_status_30
--                                                ,cv_customer_status_40
--                                                ,cv_customer_status_50
--                                               )  -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_12 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_30
--                                                ,cv_customer_status_40
--                                               )  -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_15 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_16 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_17 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                      )
--               ))
--          AND  xcav.account_number = xcrv2.account_number(+)
--       ) inn_v
--     GROUP BY  inn_v.sum_org_code
--              ,inn_v.gvm_type
--              ,inn_v.sales_date
--     -- �������VIEW
--     UNION ALL
--     SELECT
--       inn_v.sum_org_code               sum_org_code         -- �ڋq�R�[�h
--      ,inn_v.gvm_type                   gvm_type             -- ��ʁ^���̋@�^�l�b
--      ,MAX(
--           inn_v.cust_new_num
--          )                             cust_new_num         -- �ڋq�����i�V�K�j
--      ,MAX(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  1
--           END
--          )                             cust_vd_new_num      -- �ڋq�����iVD�F�V�K�j
--      ,MAX(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  1
--           END
--          )                             cust_other_new_num   -- �ڋq�����iVD�ȊO�F�V�K�j
--      ,inn_v.sales_date                 sales_date           -- �̔��N�����^�̔��N��
--      ,NULL                             tgt_amt              -- ����v��
--      ,NULL                             tgt_vd_amt           -- ����v��iVD�j
--      ,NULL                             tgt_other_amt        -- ����v��iVD�ȊO�j
--      ,NULL                             tgt_vis_num          -- �K��v��
--      ,NULL                             tgt_vis_vd_num       -- �K��v��iVD�j
--      ,NULL                             tgt_vis_other_num    -- �K��v��iVD�ȊO�j
--      ,NULL                             rslt_amt             -- �������
--      ,NULL                             rslt_new_amt         -- ������сi�V�K�j
--      ,NULL                             rslt_vd_new_amt      -- ������сiVD�F�V�K�j
--      ,NULL                             rslt_vd_amt          -- ������сiVD�j
--      ,NULL                             rslt_other_new_amt   -- ������сiVD�ȊO�F�V�K�j
--      ,NULL                             rslt_other_amt       -- ������сiVD�ȊO�j
--      ,NULL                             rslt_center_amt      -- �������_�Q�������
--      ,NULL                             rslt_center_vd_amt   -- �������_�Q������сiVD�j
--      ,NULL                             rslt_center_other_amt-- �������_�Q������сiVD�ȊO�j
--      ,COUNT(inn_v.task_id)             vis_num              -- �K�����
--      ,COUNT
--            (
--             CASE WHEN (inn_v.cust_new_num = 1)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_new_num          -- �K����сi�V�K�j
--      ,COUNT
--            (
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                   AND (inn_v.cust_new_num = 1)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_vd_new_num       -- �K����сiVD�F�V�K�j
--      ,COUNT(
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_vd_num           -- �K����сiVD�j
--      ,COUNT(
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                   AND (inn_v.cust_new_num = 1)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_other_new_num    -- �K����сiVD�ȊO�F�V�K�j
--      ,COUNT
--            (
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_other_num        -- �K����сiVD�ȊO�j
--      ,COUNT
--            (
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_mc)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_mc_num           -- �K����сiMC�j
--      ,COUNT
--            (
--             CASE WHEN (
--                        inn_v.eff_visit_flag = cv_eff_visit_flag_1
--                       )
--                  THEN  inn_v.task_id
--                  ELSE  NULL
--             END
--            )                           vis_sales_num        -- �L������
--      ,SUM(inn_v.vis_a_num)             vis_a_num            -- �K��`����
--      ,SUM(inn_v.vis_b_num)             vis_b_num            -- �K��a����
--      ,SUM(inn_v.vis_c_num)             vis_c_num            -- �K��b����
--      ,SUM(inn_v.vis_d_num)             vis_d_num            -- �K��c����
--      ,SUM(inn_v.vis_e_num)             vis_e_num            -- �K��d����
--      ,SUM(inn_v.vis_f_num)             vis_f_num            -- �K��e����
--      ,SUM(inn_v.vis_g_num)             vis_g_num            -- �K��f����
--      ,SUM(inn_v.vis_h_num)             vis_h_num            -- �K��g����
--      ,SUM(inn_v.vis_i_num)             vis_i_num            -- �K���@����
--      ,SUM(inn_v.vis_j_num)             vis_j_num            -- �K��i����
--      ,SUM(inn_v.vis_k_num)             vis_k_num            -- �K��j����
--      ,SUM(inn_v.vis_l_num)             vis_l_num            -- �K��k����
--      ,SUM(inn_v.vis_m_num)             vis_m_num            -- �K��l����
--      ,SUM(inn_v.vis_n_num)             vis_n_num            -- �K��m����
--      ,SUM(inn_v.vis_o_num)             vis_o_num            -- �K��n����
--      ,SUM(inn_v.vis_p_num)             vis_p_num            -- �K��o����
--      ,SUM(inn_v.vis_q_num)             vis_q_num            -- �K��p����
--      ,SUM(inn_v.vis_r_num)             vis_r_num            -- �K��q����
--      ,SUM(inn_v.vis_s_num)             vis_s_num            -- �K��r����
--      ,SUM(inn_v.vis_t_num)             vis_t_num            -- �K��s����
--      ,SUM(inn_v.vis_u_num)             vis_u_num            -- �K��t����
--      ,SUM(inn_v.vis_v_num)             vis_v_num            -- �K��u����
--      ,SUM(inn_v.vis_w_num)             vis_w_num            -- �K��v����
--      ,SUM(inn_v.vis_x_num)             vis_x_num            -- �K��w����
--      ,SUM(inn_v.vis_y_num)             vis_y_num            -- �K��x����
--      ,SUM(inn_v.vis_z_num)             vis_z_num            -- �K��y����
--     FROM
--       (
--        SELECT
--          xcav.account_number              sum_org_code         -- �ڋq�R�[�h
--         ,CASE WHEN (
--                     xcav.customer_status IN ('20', '25', '30')
--                    )
--               THEN  cv_emp_div_mc
--               WHEN (
--                     xxcso_route_common_pkg.iscustomervendor(xcav.business_low_type)
--                       = cv_true
--                    )
--               THEN  cv_emp_div_jihan
--               ELSE  cv_emp_div_gen
--          END                              gvm_type             -- ��ʁ^���̋@�^�l�b
--         ,CASE WHEN (
--                     TRUNC(xcav.cnvs_date) = TRUNC(xvv.actual_end_date)
--                    )
--                AND (
--                     xcav.new_point_div = cv_new_point_div_1
--                    )
--                AND (
--                     xcav.cnvs_business_person = xcrv2.employee_number
--                    )
--               THEN  1
--          END                              cust_new_num         -- �ڋq�����i�V�K�j
--         ,TO_CHAR(xvv.actual_end_date, 'YYYYMMDD')
--                                           sales_date           -- �̔��N�����^�̔��N��
--         ,xvv.task_id                      task_id              -- �^�X�NID
--         ,xvv.eff_visit_flag               eff_visit_flag       -- �L���K��敪
--         ,xvv.visit_num_a                  vis_a_num            -- �K��`����
--         ,xvv.visit_num_b                  vis_b_num            -- �K��a����
--         ,xvv.visit_num_c                  vis_c_num            -- �K��b����
--         ,xvv.visit_num_d                  vis_d_num            -- �K��c����
--         ,xvv.visit_num_e                  vis_e_num            -- �K��d����
--         ,xvv.visit_num_f                  vis_f_num            -- �K��e����
--         ,xvv.visit_num_g                  vis_g_num            -- �K��f����
--         ,xvv.visit_num_h                  vis_h_num            -- �K��g����
--         ,xvv.visit_num_i                  vis_i_num            -- �K���@����
--         ,xvv.visit_num_j                  vis_j_num            -- �K��i����
--         ,xvv.visit_num_k                  vis_k_num            -- �K��j����
--         ,xvv.visit_num_l                  vis_l_num            -- �K��k����
--         ,xvv.visit_num_m                  vis_m_num            -- �K��l����
--         ,xvv.visit_num_n                  vis_n_num            -- �K��m����
--         ,xvv.visit_num_o                  vis_o_num            -- �K��n����
--         ,xvv.visit_num_p                  vis_p_num            -- �K��o����
--         ,xvv.visit_num_q                  vis_q_num            -- �K��p����
--         ,xvv.visit_num_r                  vis_r_num            -- �K��q����
--         ,xvv.visit_num_s                  vis_s_num            -- �K��r����
--         ,xvv.visit_num_t                  vis_t_num            -- �K��s����
--         ,xvv.visit_num_u                  vis_u_num            -- �K��t����
--         ,xvv.visit_num_v                  vis_v_num            -- �K��u����
--         ,xvv.visit_num_w                  vis_w_num            -- �K��v����
--         ,xvv.visit_num_x                  vis_x_num            -- �K��w����
--         ,xvv.visit_num_y                  vis_y_num            -- �K��x����
--         ,xvv.visit_num_z                  vis_z_num            -- �K��y����
--        FROM
--          xxcso_cust_accounts_v xcav  -- �ڋq�}�X�^�r���[
--         ,xxcso_visit_v xvv  -- �K����уr���[
--         ,xxcso_cust_resources_v2 xcrv2  -- �ڋq�S���c�ƈ��i�ŐV�j�r���[
--        WHERE  xcav.party_id = xvv.party_id  -- �p�[�e�BID
--          AND  TRUNC(xvv.actual_end_date) BETWEEN gd_ar_gl_period_from
--                                              AND gd_process_date  -- ���яI����
--          AND  ((
--                      (
--                       xcav.customer_class_code IS NULL -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_10
--                                                ,cv_customer_status_20
--                                               )  -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_10 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_25
--                                                ,cv_customer_status_30
--                                                ,cv_customer_status_40
--                                                ,cv_customer_status_50
--                                               )  -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_12 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_30
--                                                ,cv_customer_status_40
--                                               )  -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_15 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_16 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_17 -- �ڋq�敪
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                      )
--               ))
--          AND  xcav.account_number = xcrv2.account_number(+)
--       ) inn_v
--     GROUP BY  inn_v.sum_org_code
--              ,inn_v.gvm_type
--              ,inn_v.sales_date
--     ) union_res
--  GROUP BY
--    union_res.sum_org_code                         -- �ڋq�R�[�h
--   ,union_res.gvm_type                             -- ��ʁ^���̋@�^�l�b
--   ,union_res.sales_date                           -- �̔��N�����^�̔��N��
/* 20090828_abe_0001194 START*/
    SELECT  /*+ FIRST_ROWS */
            inn_v.sum_org_code                 sum_org_code
--    SELECT  inn_v.sum_org_code                 sum_org_code
/* 20090828_abe_0001194 END*/
           ,inn_v.group_base_code              group_base_code
           ,inn_v.sales_date                   sales_date
           ,NULL                               gvm_type
           ,NULL                               cust_new_num
           ,NULL                               cust_vd_new_num
           ,NULL                               cust_other_new_num
           ,SUM(inn_v.rslt_amt)                rslt_amt
           ,NULL                               rslt_new_amt
           ,NULL                               rslt_vd_new_amt
           ,NULL                               rslt_vd_amt
           ,NULL                               rslt_other_new_amt
           ,NULL                               rslt_other_amt
           ,SUM(inn_v.rslt_center_amt)         rslt_center_amt
           ,NULL                               rslt_center_vd_amt
           ,NULL                               rslt_center_other_amt
           ,MAX(inn_v.tgt_amt)                 tgt_amt
           ,NULL                               tgt_vd_amt
           ,NULL                               tgt_other_amt
           ,MAX(inn_v.vis_num)                 vis_num
           ,NULL                               vis_new_num
           ,NULL                               vis_vd_new_num
           ,NULL                               vis_vd_num
           ,NULL                               vis_other_new_num
           ,NULL                               vis_other_num
           ,NULL                               vis_mc_num
           ,MAX(inn_v.vis_sales_num)           vis_sales_num
           ,NULL                               tgt_vis_num
           ,NULL                               tgt_vis_vd_num
           ,NULL                               tgt_vis_other_num
           ,MAX(inn_v.vis_a_num)               vis_a_num
           ,MAX(inn_v.vis_b_num)               vis_b_num
           ,MAX(inn_v.vis_c_num)               vis_c_num
           ,MAX(inn_v.vis_d_num)               vis_d_num
           ,MAX(inn_v.vis_e_num)               vis_e_num
           ,MAX(inn_v.vis_f_num)               vis_f_num
           ,MAX(inn_v.vis_g_num)               vis_g_num
           ,MAX(inn_v.vis_h_num)               vis_h_num
           ,MAX(inn_v.vis_i_num)               vis_i_num
           ,MAX(inn_v.vis_j_num)               vis_j_num
           ,MAX(inn_v.vis_k_num)               vis_k_num
           ,MAX(inn_v.vis_l_num)               vis_l_num
           ,MAX(inn_v.vis_m_num)               vis_m_num
           ,MAX(inn_v.vis_n_num)               vis_n_num
           ,MAX(inn_v.vis_o_num)               vis_o_num
           ,MAX(inn_v.vis_p_num)               vis_p_num
           ,MAX(inn_v.vis_q_num)               vis_q_num
           ,MAX(inn_v.vis_r_num)               vis_r_num
           ,MAX(inn_v.vis_s_num)               vis_s_num
           ,MAX(inn_v.vis_t_num)               vis_t_num
           ,MAX(inn_v.vis_u_num)               vis_u_num
           ,MAX(inn_v.vis_v_num)               vis_v_num
           ,MAX(inn_v.vis_w_num)               vis_w_num
           ,MAX(inn_v.vis_x_num)               vis_x_num
           ,MAX(inn_v.vis_y_num)               vis_y_num
           ,MAX(inn_v.vis_z_num)               vis_z_num
    FROM    (
             --------------------------------
             -- �ڋq�ʔ���v��i���ʁj
             --------------------------------
             SELECT  xasp.base_code                       group_base_code
                    ,xasp.account_number                  sum_org_code
                    ,xasp.plan_date                       sales_date
                    ,xasp.sales_plan_day_amt              tgt_amt
                    ,NULL                                 rslt_amt
                    ,NULL                                 rslt_center_amt
                    ,NULL                                 vis_num
                    ,NULL                                 vis_sales_num
                    ,NULL                                 vis_a_num
                    ,NULL                                 vis_b_num
                    ,NULL                                 vis_c_num
                    ,NULL                                 vis_d_num
                    ,NULL                                 vis_e_num
                    ,NULL                                 vis_f_num
                    ,NULL                                 vis_g_num
                    ,NULL                                 vis_h_num
                    ,NULL                                 vis_i_num
                    ,NULL                                 vis_j_num
                    ,NULL                                 vis_k_num
                    ,NULL                                 vis_l_num
                    ,NULL                                 vis_m_num
                    ,NULL                                 vis_n_num
                    ,NULL                                 vis_o_num
                    ,NULL                                 vis_p_num
                    ,NULL                                 vis_q_num
                    ,NULL                                 vis_r_num
                    ,NULL                                 vis_s_num
                    ,NULL                                 vis_t_num
                    ,NULL                                 vis_u_num
                    ,NULL                                 vis_v_num
                    ,NULL                                 vis_w_num
                    ,NULL                                 vis_x_num
                    ,NULL                                 vis_y_num
                    ,NULL                                 vis_z_num
             FROM    xxcso_account_sales_plans  xasp
             WHERE   xasp.plan_date BETWEEN TO_CHAR(gd_ar_gl_period_from,'YYYYMMDD')
                                        AND TO_CHAR(LAST_DAY(gd_process_date),'YYYYMMDD') 
               AND   xasp.month_date_div = cv_month_date_div_day
               AND   xasp.sales_plan_day_amt IS NOT NULL
             --------------------------------
             -- �ڋq�ʔ���v��i���ʂ̂݁j
             --------------------------------
             UNION ALL
             SELECT  xasp.base_code                       group_base_code
                    ,xasp.account_number                  sum_org_code
                    ,xasp.year_month || '01'              sales_date
                    ,xasp.sales_plan_month_amt            tgt_amt
                    ,NULL                                 rslt_amt
                    ,NULL                                 rslt_center_amt
                    ,NULL                                 vis_num
                    ,NULL                                 vis_sales_num
                    ,NULL                                 vis_a_num
                    ,NULL                                 vis_b_num
                    ,NULL                                 vis_c_num
                    ,NULL                                 vis_d_num
                    ,NULL                                 vis_e_num
                    ,NULL                                 vis_f_num
                    ,NULL                                 vis_g_num
                    ,NULL                                 vis_h_num
                    ,NULL                                 vis_i_num
                    ,NULL                                 vis_j_num
                    ,NULL                                 vis_k_num
                    ,NULL                                 vis_l_num
                    ,NULL                                 vis_m_num
                    ,NULL                                 vis_n_num
                    ,NULL                                 vis_o_num
                    ,NULL                                 vis_p_num
                    ,NULL                                 vis_q_num
                    ,NULL                                 vis_r_num
                    ,NULL                                 vis_s_num
                    ,NULL                                 vis_t_num
                    ,NULL                                 vis_u_num
                    ,NULL                                 vis_v_num
                    ,NULL                                 vis_w_num
                    ,NULL                                 vis_x_num
                    ,NULL                                 vis_y_num
                    ,NULL                                 vis_z_num
             FROM    xxcso_account_sales_plans  xasp
             WHERE   xasp.year_month BETWEEN TO_CHAR(gd_ar_gl_period_from,'YYYYMM')
                                         AND TO_CHAR(gd_process_date,'YYYYMM')
               AND   xasp.month_date_div = cv_month_date_div_mon
               AND   NOT EXISTS (
                       -- ���ʌv�悪����ꍇ�͏o�͂��Ȃ�
                       SELECT  1
                       FROM    xxcso_account_sales_plans  xaspd
                       WHERE   xaspd.base_code      = xasp.base_code
                         AND   xaspd.account_number = xasp.account_number
                         AND   xaspd.month_date_div = cv_month_date_div_day
                         AND   xaspd.year_month     = xasp.year_month
                         AND   xaspd.sales_plan_day_amt IS NOT NULL
                     )
             --------------------------------
             -- �ڋq�ʔ�����яW�v
             --------------------------------
             UNION ALL
-- 2010/05/14 v1.8 T.Yoshimoto Mod Start E_�{�ғ�_02763
--             SELECT  xcav.sale_base_code                     group_base_code
             SELECT  (SELECT xcca.sale_base_code
                      FROM    xxcmm_cust_accounts xcca
                      WHERE   xcca.customer_code = xsv2.account_number
                      AND     rownum = 1
                      )          group_base_code
-- 2010/05/14 v1.8 T.Yoshimoto Mod End E_�{�ғ�_02763
                    ,xsv2.account_number                     sum_org_code
                    ,TO_CHAR(xsv2.delivery_date,'YYYYMMDD')  sales_date
                    ,NULL                                    tgt_amt
                    ,xsv2.pure_amount                        rslt_amt
                    ,(CASE
                        WHEN (xsv2.other_flag = 'Y') THEN
                          xsv2.pure_amount
                        ELSE
                          NULL
                      END
                     )                                       rslt_center_amt
                    ,NULL                                    vis_num
                    ,NULL                                    vis_sales_num
                    ,NULL                                    vis_a_num
                    ,NULL                                    vis_b_num
                    ,NULL                                    vis_c_num
                    ,NULL                                    vis_d_num
                    ,NULL                                    vis_e_num
                    ,NULL                                    vis_f_num
                    ,NULL                                    vis_g_num
                    ,NULL                                    vis_h_num
                    ,NULL                                    vis_i_num
                    ,NULL                                    vis_j_num
                    ,NULL                                    vis_k_num
                    ,NULL                                    vis_l_num
                    ,NULL                                    vis_m_num
                    ,NULL                                    vis_n_num
                    ,NULL                                    vis_o_num
                    ,NULL                                    vis_p_num
                    ,NULL                                    vis_q_num
                    ,NULL                                    vis_r_num
                    ,NULL                                    vis_s_num
                    ,NULL                                    vis_t_num
                    ,NULL                                    vis_u_num
                    ,NULL                                    vis_v_num
                    ,NULL                                    vis_w_num
                    ,NULL                                    vis_x_num
                    ,NULL                                    vis_y_num
                    ,NULL                                    vis_z_num
             FROM    (SELECT  xsv1.account_number
                             ,xsv1.delivery_date
                             ,xsv1.other_flag
                             ,(CASE
                                 WHEN (xsv1.pure_amount < 0)
                                  AND (xsv1.pure_amount > -500)
                                 THEN
                                   -1
                                 WHEN (xsv1.pure_amount = 0)
                                 THEN
                                   0
                                 WHEN (xsv1.pure_amount > 0)
                                  AND (xsv1.pure_amount < 500)
                                 THEN
                                   1
                                 ELSE
                                   ROUND(xsv1.pure_amount / 1000)
                               END
                              ) pure_amount
/* 20090828_abe_0001194 START*/
                      FROM    (
-- 2010/05/14 v1.8 T.Yoshimoto Del Start E_�{�ғ�_02763
--                      SELECT  /*+ USE_NL(xsv.seh xsv.sel) */
--                                       xsv.account_number     account_number
--                      FROM    (SELECT  xsv.account_number     account_number
/* 20090828_abe_0001194 END*/
--                                      ,xsv.delivery_date      delivery_date
--                                      ,'N'                    other_flag
--                                      ,SUM(xsv.pure_amount)   pure_amount
--                               FROM    xxcso_sales_v  xsv
--                               WHERE   xsv.delivery_date BETWEEN gd_ar_gl_period_from
--                                                             AND gd_process_date
--                                 AND   xsv.delivery_pattern_class <> cv_delivery_pattern_cls_5
--                               GROUP BY xsv.account_number, xsv.delivery_date
--                               UNION ALL
/* 20090828_abe_0001194 START*/
--                               SELECT  /*+ USE_NL(xsv.seh xsv.sel) */
--                                       xsv.account_number     account_number
--                               SELECT  xsv.account_number     account_number
/* 20090828_abe_0001194 END*/
--                                      ,xsv.delivery_date      delivery_date
--                                      ,'Y'                    other_flag
--                                      ,SUM(xsv.pure_amount)   pure_amount
--                               FROM    xxcso_sales_v  xsv
--                               WHERE   xsv.delivery_date BETWEEN gd_ar_gl_period_from
--                                                             AND gd_process_date
--                                 AND   xsv.delivery_pattern_class = cv_delivery_pattern_cls_5
--                               GROUP BY xsv.account_number, xsv.delivery_date
-- 2010/05/14 v1.8 T.Yoshimoto Del End E_�{�ғ�_02763
-- 2010/05/14 v1.8 T.Yoshimoto Add Start E_�{�ғ�_02763
                               SELECT  /*+ USE_NL(xsv.seh xsv.sel) */
                                   xsv.account_number     account_number
                                  ,xsv.delivery_date      delivery_date
                                  ,DECODE(xsv.delivery_pattern_class,cv_delivery_pattern_cls_5,'Y','N')  other_flag
                                  ,SUM(xsv.pure_amount)   pure_amount
                               FROM    xxcso_sales_v  xsv
                               WHERE   xsv.delivery_date BETWEEN gd_ar_gl_period_from
                                                             AND gd_process_date
                               GROUP BY xsv.account_number 
                                       ,xsv.delivery_date
                                       ,DECODE(xsv.delivery_pattern_class,cv_delivery_pattern_cls_5,'Y','N')
-- 2010/05/14 v1.8 T.Yoshimoto Add End E_�{�ғ�_02763
                              ) xsv1
                     )                       xsv2
-- 2010/05/14 v1.8 T.Yoshimoto Del Start E_�{�ғ�_02763
--                    ,xxcso_cust_accounts_v   xcav
--             WHERE   xcav.account_number = xsv2.account_number
-- 2010/05/14 v1.8 T.Yoshimoto Del End E_�{�ғ�_02763
             --------------------------------
             -- �ڋq�ʖK����яW�v
             --------------------------------
             UNION ALL
-- 2010/05/14 v1.8 T.Yoshimoto Mod Start E_�{�ғ�_02763
--             SELECT  xcav.sale_base_code                       group_base_code
--                    ,xcav.account_number                       sum_org_code
             SELECT  xvv1.sale_base_code                       group_base_code
                    ,xvv1.account_number                       sum_org_code
-- 2010/05/14 v1.8 T.Yoshimoto Mod End E_�{�ғ�_02763
                    ,TO_CHAR(xvv1.actual_end_date,'YYYYMMDD')  sales_date
                    ,NULL                                      tgt_amt
                    ,NULL                                      rslt_amt
                    ,NULL                                      rslt_center_amt
                    ,xvv1.vis_num                              vis_num
                    ,(CASE
                        WHEN (xvv1.vis_sales_num > 0) THEN
                          xvv1.vis_sales_num
                        ELSE
                          NULL
                      END
                     )                                         vis_sales_num
                    ,xvv1.visit_num_a                          vis_a_num
                    ,xvv1.visit_num_b                          vis_b_num
                    ,xvv1.visit_num_c                          vis_c_num
                    ,xvv1.visit_num_d                          vis_d_num
                    ,xvv1.visit_num_e                          vis_e_num
                    ,xvv1.visit_num_f                          vis_f_num
                    ,xvv1.visit_num_g                          vis_g_num
                    ,xvv1.visit_num_h                          vis_h_num
                    ,xvv1.visit_num_i                          vis_i_num
                    ,xvv1.visit_num_j                          vis_j_num
                    ,xvv1.visit_num_k                          vis_k_num
                    ,xvv1.visit_num_l                          vis_l_num
                    ,xvv1.visit_num_m                          vis_m_num
                    ,xvv1.visit_num_n                          vis_n_num
                    ,xvv1.visit_num_o                          vis_o_num
                    ,xvv1.visit_num_p                          vis_p_num
                    ,xvv1.visit_num_q                          vis_q_num
                    ,xvv1.visit_num_r                          vis_r_num
                    ,xvv1.visit_num_s                          vis_s_num
                    ,xvv1.visit_num_t                          vis_t_num
                    ,xvv1.visit_num_u                          vis_u_num
                    ,xvv1.visit_num_v                          vis_v_num
                    ,xvv1.visit_num_w                          vis_w_num
                    ,xvv1.visit_num_x                          vis_x_num
                    ,xvv1.visit_num_y                          vis_y_num
                    ,xvv1.visit_num_z                          vis_z_num
/* 20090828_abe_0001194 START*/
             FROM    (SELECT  /*+ index(xvv.jtb xxcso_jtf_tasks_b_n20) */
-- 2010/05/14 v1.8 T.Yoshimoto Mod Start E_�{�ғ�_02763
--                              xvv.party_id                                party_id
                              hca.account_number                          account_number
                             ,(SELECT xcca.sale_base_code
                               FROM  xxcmm_cust_accounts xcca
                               WHERE xcca.customer_code = hca.account_number
                               AND   rownum = 1
                              )                                           sale_base_code
-- 2010/05/14 v1.8 T.Yoshimoto Mod End E_�{�ғ�_02763
--             FROM    (SELECT  xvv.party_id                                party_id
/* 20090828_abe_0001194 END*/
                             ,TRUNC(xvv.actual_end_date)                  actual_end_date
                             ,COUNT(xvv.task_id)                          vis_num
                             ,SUM(
                                CASE
                                  WHEN (xvv.eff_visit_flag = cv_eff_visit_flag_1) THEN
                                    1
                                  ELSE
                                    0
                                END
                              )                                           vis_sales_num
                             ,SUM(xvv.visit_num_a)                        visit_num_a
                             ,SUM(xvv.visit_num_b)                        visit_num_b
                             ,SUM(xvv.visit_num_c)                        visit_num_c
                             ,SUM(xvv.visit_num_d)                        visit_num_d
                             ,SUM(xvv.visit_num_e)                        visit_num_e
                             ,SUM(xvv.visit_num_f)                        visit_num_f
                             ,SUM(xvv.visit_num_g)                        visit_num_g
                             ,SUM(xvv.visit_num_h)                        visit_num_h
                             ,SUM(xvv.visit_num_i)                        visit_num_i
                             ,SUM(xvv.visit_num_j)                        visit_num_j
                             ,SUM(xvv.visit_num_k)                        visit_num_k
                             ,SUM(xvv.visit_num_l)                        visit_num_l
                             ,SUM(xvv.visit_num_m)                        visit_num_m
                             ,SUM(xvv.visit_num_n)                        visit_num_n
                             ,SUM(xvv.visit_num_o)                        visit_num_o
                             ,SUM(xvv.visit_num_p)                        visit_num_p
                             ,SUM(xvv.visit_num_q)                        visit_num_q
                             ,SUM(xvv.visit_num_r)                        visit_num_r
                             ,SUM(xvv.visit_num_s)                        visit_num_s
                             ,SUM(xvv.visit_num_t)                        visit_num_t
                             ,SUM(xvv.visit_num_u)                        visit_num_u
                             ,SUM(xvv.visit_num_v)                        visit_num_v
                             ,SUM(xvv.visit_num_w)                        visit_num_w
                             ,SUM(xvv.visit_num_x)                        visit_num_x
                             ,SUM(xvv.visit_num_y)                        visit_num_y
                             ,SUM(xvv.visit_num_z)                        visit_num_z
                      FROM    xxcso_visit_v xvv
-- 2010/05/14 v1.8 T.Yoshimoto Add Start E_�{�ғ�_02763
                             ,hz_cust_accounts   hca
-- 2010/05/14 v1.8 T.Yoshimoto Add End E_�{�ғ�_02763
                      WHERE   TRUNC(xvv.actual_end_date) BETWEEN gd_ar_gl_period_from
                                                             AND gd_process_date
-- 2010/05/14 v1.8 T.Yoshimoto Add Start E_�{�ғ�_02763
                      AND     hca.party_id = xvv.party_id
-- 2010/05/14 v1.8 T.Yoshimoto Add End E_�{�ғ�_02763
-- 2010/05/14 v1.8 T.Yoshimoto Mod Start E_�{�ғ�_02763
--                      GROUP BY xvv.party_id, TRUNC(xvv.actual_end_date)
                      --����account_number����擾����sale_base_code�͒l�̓��j�[�N�̈�
                      --group by ��ɂ͊܂߂��ɏȗ��B
                      GROUP BY hca.account_number
                              , TRUNC(xvv.actual_end_date)
-- 2010/05/14 v1.8 T.Yoshimoto Add End E_�{�ғ�_02763
                     )                       xvv1
-- 2010/05/14 v1.8 T.Yoshimoto Del Start E_�{�ғ�_02763
--                    ,xxcso_cust_accounts_v   xcav
--             WHERE   xcav.party_id = xvv1.party_id
-- 2010/05/14 v1.8 T.Yoshimoto Del End E_�{�ғ�_02763
            ) inn_v
    GROUP BY  inn_v.sum_org_code
             ,inn_v.group_base_code
             ,inn_v.sales_date
/* 20090519_Ogawa_T1_1024 END*/
/* 20090519_Ogawa_T1_1037 END*/
/* 20090519_Ogawa_T1_1038 END*/
    ;
    -- �K�����VIEW
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
  -- ���ʌڋq�ʃf�[�^�擾�p���R�[�h��`
  g_get_day_acct_data_rec  g_get_day_acct_data_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';   -- �A�v���P�[�V�����Z�k��
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- *** DEBUG_LOG ***
    -- �擾����WHO�J���������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'WHO�J����'  || CHR(10) ||
 'created_by:' || TO_CHAR(cn_created_by            ) || CHR(10) ||
 'creation_date:' || TO_CHAR(cd_creation_date         ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
 'last_updated_by:' || TO_CHAR(cn_last_updated_by       ) || CHR(10) ||
 'last_update_date:' || TO_CHAR(cd_last_update_date      ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
 'last_update_login:' || TO_CHAR(cn_last_update_login     ) || CHR(10) ||
 'request_id:' || TO_CHAR(cn_request_id            ) || CHR(10) ||
 'program_application_id:' || TO_CHAR(cn_program_application_id) || CHR(10) ||
 'program_id:' || TO_CHAR(cn_program_id            ) || CHR(10) ||
 'program_update_date:' || TO_CHAR(cd_program_update_date   ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- ===========================
    -- �Ɩ��������擾���� 
    -- ===========================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- �擾�����Ɩ������������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(gd_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
/* 20090525_Mori START*/
    IF (gd_process_date IS NULL) THEN
--    IF (gd_process_date = NULL) THEN
/* 20090525_Mori END*/
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_01             --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
/* 20090525_Mori START*/
      RAISE global_api_expt;
--      RAISE global_api_others_expt;
/* 20090525_Mori END*/
    END IF;
    -- ===========================
    -- ��v���ԊJ�n���擾���� 
    -- ===========================
    gd_ar_gl_period_from := xxcso_util_common_pkg.get_ar_gl_period_from;
    -- *** DEBUG_LOG ***
    -- �擾������v���ԊJ�n�������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3  || CHR(10) ||
                 cv_debug_msg4  || TO_CHAR(gd_ar_gl_period_from,'yyyy/mm/dd hh24:mi:ss') ||
                 CHR(10) ||
                 ''
    );
/* 20090525_Mori START*/
    IF (gd_ar_gl_period_from IS NULL) THEN
--    IF (gd_ar_gl_period_from = NULL) THEN
/* 20090525_Mori END*/
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02             --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
/* 20090525_Mori START*/
      RAISE global_api_expt;
--      RAISE global_api_others_expt;
/* 20090525_Mori END*/
    END IF;
    -- ===========================
    -- ���o�Ώۂ̔N�����X�g�擾���� 
    -- ===========================
    -- �Ɩ��������̔N��
    gv_ym_lst_1 := TO_CHAR(gd_process_date, 'YYYYMM');
    -- �Ɩ��������̑O��
    IF (TO_CHAR(gd_process_date, 'MM') = '01') THEN
      gv_ym_lst_2 := (TO_CHAR(gd_process_date, 'YYYY') - 1) || '12';
    ELSE
      gv_ym_lst_2 := TO_CHAR(gd_process_date, 'YYYYMM') - 1;
    END IF;
    -- �Ɩ��������̑O�N����
    gv_ym_lst_3 := TO_CHAR(TO_CHAR(gd_process_date, 'YYYY')-1) || 
                   TO_CHAR(gd_process_date, 'MM');
    IF (TO_CHAR(gd_process_date, 'YYYYMM') <> TO_CHAR(gd_ar_gl_period_from, 'YYYYMM')) THEN
      -- ��v���ԊJ�n���̔N��
      gv_ym_lst_4 := TO_CHAR(gd_ar_gl_period_from, 'YYYYMM');
      -- ��v���ԊJ�n���̑O��
      IF (TO_CHAR(gd_ar_gl_period_from, 'MM') = '01') THEN
        gv_ym_lst_5 := (TO_CHAR(gd_ar_gl_period_from, 'YYYY') - 1) || '12';
      ELSE
        gv_ym_lst_5 := TO_CHAR(gd_ar_gl_period_from, 'YYYYMM') - 1;
      END IF;
      -- ��v���ԊJ�n���̑O�N����
      gv_ym_lst_6 := TO_CHAR(TO_CHAR(gd_ar_gl_period_from, 'YYYY')-1) || 
                     TO_CHAR(gd_ar_gl_period_from, 'MM');
    END IF;
    -- *** DEBUG_LOG ***
    -- �擾�����Ɩ������������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5  || CHR(10) ||
                 cv_debug_msg5_1  || gv_ym_lst_1 || CHR(10) ||
                 cv_debug_msg5_2  || gv_ym_lst_2 || CHR(10) ||
                 cv_debug_msg5_3  || gv_ym_lst_3 || CHR(10) ||
                 cv_debug_msg5_4  || gv_ym_lst_4 || CHR(10) ||
                 cv_debug_msg5_5  || gv_ym_lst_5 || CHR(10) ||
                 cv_debug_msg5_6  || gv_ym_lst_6 || CHR(10) ||
                 CHR(10) ||
                 ''
    );
    -- ===========================
    -- ���o�����A�o�͌����̏����l�ݒ� 
    -- ===========================
    gn_delete_cnt := 0;              -- �폜����
    gn_extrct_cnt := 0;              -- ���o����
    gn_output_cnt := 0;              -- �o�͌���
    -- *** DEBUG_LOG ***
    -- �擾�����Ɩ������������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg6  || CHR(10) ||
                 cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                 cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                 cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                 ''
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  /**********************************************************************************
   * Procedure Name   : check_parm
   * Description      : �p�����[�^�`�F�b�N (A-2)
   ***********************************************************************************/
  PROCEDURE check_parm(
     ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'check_parm';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- IN�p�����[�^�F�����敪��NULL�`�F�b�N
    IF (gv_prm_process_div IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_13             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_item
                    ,iv_token_value1 => cv_tkn_msg_proc_div
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- IN�p�����[�^�F�����敪�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_14
                    ,iv_token_name1  => cv_tkn_entry
                    ,iv_token_value1 => gv_prm_process_div
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- IN�p�����[�^�F�����敪�̑Ó����`�F�b�N
    IF (gv_prm_process_div NOT IN (cv_process_div_ins, cv_process_div_del)) THEN
      -- �p�����[�^�����敪��'1','9'�ł͂Ȃ��ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_15             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_item
                    ,iv_token_value1 => cv_tkn_msg_proc_div
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_parm;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
  /**********************************************************************************
   * Procedure Name   : delete_data
   * Description      : �����Ώۃf�[�^�폜 (A-3)
   ***********************************************************************************/
  PROCEDURE delete_data(
     ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_data';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_delete_cnt               NUMBER;              -- �폜����
    /* 2009.12.28 K.Hosoi E_�{�ғ�_00686�Ή� START */
    ld_calc_ar_gl_prid_frm      DATE;                -- �폜�Ώۃf�[�^���o���Ԍv�Z�p
    /* 2009.12.28 K.Hosoi E_�{�ғ�_00686�Ή� END */
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================
    -- �ϐ����������� 
    -- =======================
    ln_delete_cnt := 0;
--
    -- =======================
    -- ���ʏ����Ώۃf�[�^�폜���� 
    -- =======================
    BEGIN
      /* 2009.12.28 K.Hosoi E_�{�ғ�_00686�Ή� START */
      --SELECT COUNT(xsvsr.sum_org_code)
      --INTO  ln_delete_cnt
      --FROM  xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}��
      --WHERE  xsvsr.month_date_div = cv_month_date_div_day  -- �����敪
      --  AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
      --                            AND TO_CHAR(LAST_DAY(gd_process_date)     , 'YYYYMMDD') -- �̔��N����
      --;
      --gn_delete_cnt := ln_delete_cnt;
      --DELETE
      --FROM  xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}��
      --WHERE  xsvsr.month_date_div = cv_month_date_div_day  -- �����敪
      --  AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
      --                            AND TO_CHAR(LAST_DAY(gd_process_date)     , 'YYYYMMDD') -- �̔��N����
      --;
      -- �폜�Ώۃf�[�^���o���Ԍv�Z�p�ϐ��ɁA��v����From���i�[
      ld_calc_ar_gl_prid_frm := gd_ar_gl_period_from;
      --
      --�f�[�^�폜���[�v�J�n
      <<loop_del_sm_vst_sl_rp_dt>>
      LOOP
        -- �폜�Ώۃf�[�^���o���Ԍv�Z�p�ϐ� �̒l���A�Ɩ��������̌��������傫���ꍇ��EXIT
        EXIT WHEN ( ld_calc_ar_gl_prid_frm > LAST_DAY(gd_process_date));
        --
        DELETE
        FROM  xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}��
        WHERE  xsvsr.month_date_div = cv_month_date_div_day  -- �����敪
          AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                    AND TO_CHAR((ld_calc_ar_gl_prid_frm + 9), 'YYYYMMDD') -- �̔��N����
        ;
        ln_delete_cnt := ln_delete_cnt + SQL%ROWCOUNT;
        -- �R�~�b�g���s���܂��B
        COMMIT;
        --
        ld_calc_ar_gl_prid_frm := ld_calc_ar_gl_prid_frm + 10;
        --
      END LOOP;
      --
      gn_delete_cnt := ln_delete_cnt;
      /* 2009.12.28 K.Hosoi E_�{�ғ�_00686�Ή� END */
      -- *** DEBUG_LOG ***
      -- ���ʏ����폜�Ώۃf�[�^���������O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '���ʏ����폜�Ώۃf�[�^���� = ' || TO_CHAR(ln_delete_cnt) || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG ***
      -- ���ʏ����Ώۃf�[�^���폜�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg7 || CHR(10) ||
                   ''
      );
--
    -- =======================
    -- ���ʏ����Ώۃf�[�^�폜���� 
    -- =======================
-- 2012/02/17 Ver.1.9 A.Shirakawa DEL Start
--      SELECT COUNT(xsvsr.sum_org_code)
--      INTO  ln_delete_cnt
--      FROM  xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}��
--      WHERE  xsvsr.month_date_div = cv_month_date_div_mon  -- �����敪
--        AND  xsvsr.sales_date IN (
--                                   gv_ym_lst_1
--                                  ,gv_ym_lst_2
--                                  ,gv_ym_lst_3
--                                  ,gv_ym_lst_4
--                                  ,gv_ym_lst_5
--                                  ,gv_ym_lst_6
--                                 )  -- �̔��N����
--      ;
--      gn_delete_cnt := gn_delete_cnt + ln_delete_cnt;
-- 2012/02/17 Ver.1.9 A.Shirakawa DEL End
      DELETE
      FROM  xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}��
      WHERE  xsvsr.month_date_div = cv_month_date_div_mon  -- �����敪
        AND  xsvsr.sales_date IN (
                                   gv_ym_lst_1
                                  ,gv_ym_lst_2
                                  ,gv_ym_lst_3
                                  ,gv_ym_lst_4
                                  ,gv_ym_lst_5
                                  ,gv_ym_lst_6
                                 )  -- �̔��N����
      ;
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
      ln_delete_cnt := SQL%ROWCOUNT;
      gn_delete_cnt := gn_delete_cnt + ln_delete_cnt;
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
      /* 2009.12.28 K.Hosoi E_�{�ғ�_00686�Ή� START */
      -- �R�~�b�g���s��
      COMMIT;
      /* 2009.12.28 K.Hosoi E_�{�ғ�_00686�Ή� END */
      -- *** DEBUG_LOG ***
      -- ���ʏ����폜�Ώۃf�[�^���������O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '���ʏ����폜�Ώۃf�[�^���� = ' || TO_CHAR(ln_delete_cnt) || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG ***
      -- ���ʏ����Ώۃf�[�^���폜�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg8 || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_03             --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                 --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep  --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage            --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                      --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_api_expt;
    END;
    -- *** DEBUG_LOG ***
    -- ���ʏ����Ώۃf�[�^���폜�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5 || CHR(10) ||
                 ''
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_acct_dt
   * Description      : �K�┄��v��Ǘ��\�T�}���e�[�u���ɓo�^ (A-5)
   ***********************************************************************************/
  PROCEDURE insert_day_acct_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_acct_dt';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J����O ***
    insert_error_expt    EXCEPTION;    -- �o�^������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ======================
    -- �K�┄��v��Ǘ��\�T�}���e�[�u���o�^���� 
    -- ======================
    BEGIN
      INSERT INTO xxcso_sum_visit_sale_rep(
        created_by                 --�쐬��
       ,creation_date              --�쐬��
       ,last_updated_by            --�ŏI�X�V��
       ,last_update_date           --�ŏI�X�V��
       ,last_update_login          --�ŏI�X�V���O�C��
       ,request_id                 --�v��ID
       ,program_application_id     --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                 --�R���J�����g�E�v���O����ID
       ,program_update_date        --�v���O�����X�V��
       ,sum_org_type               --�W�v�g�D���
       ,sum_org_code               --�W�v�g�D�b�c
       ,group_base_code            --�O���[�v�e���_�b�c
       ,month_date_div             --�����敪
       ,sales_date                 --�̔��N�����^�̔��N��
       ,gvm_type                   --��ʁ^���̋@�^�l�b
       ,cust_new_num               --�ڋq�����i�V�K�j
       ,cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
       ,cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
       ,rslt_amt                   --�������
       ,rslt_new_amt               --������сi�V�K�j
       ,rslt_vd_new_amt            --������сiVD�F�V�K�j
       ,rslt_vd_amt                --������сiVD�j
       ,rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
       ,rslt_other_amt             --������сiVD�ȊO�j
       ,rslt_center_amt            --�������_�Q�������
       ,rslt_center_vd_amt         --�������_�Q������сiVD�j
       ,rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
       ,tgt_amt                    --����v��
       ,tgt_new_amt                --����v��i�V�K�j
       ,tgt_vd_new_amt             --����v��iVD�F�V�K�j
       ,tgt_vd_amt                 --����v��iVD�j
       ,tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
       ,tgt_other_amt              --����v��iVD�ȊO�j
       ,vis_num                    --�K�����
       ,vis_new_num                --�K����сi�V�K�j
       ,vis_vd_new_num             --�K����сiVD�F�V�K�j
       ,vis_vd_num                 --�K����сiVD�j
       ,vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
       ,vis_other_num              --�K����сiVD�ȊO�j
       ,vis_mc_num                 --�K����сiMC�j
       ,vis_sales_num              --�L������
       ,tgt_vis_num                --�K��v��
       ,tgt_vis_new_num            --�K��v��i�V�K�j
       ,tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
       ,tgt_vis_vd_num             --�K��v��iVD�j
       ,tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
       ,tgt_vis_other_num          --�K��v��iVD�ȊO�j
       ,tgt_vis_mc_num             --�K��v��iMC�j
       ,vis_a_num                  --�K��`����
       ,vis_b_num                  --�K��a����
       ,vis_c_num                  --�K��b����
       ,vis_d_num                  --�K��c����
       ,vis_e_num                  --�K��d����
       ,vis_f_num                  --�K��e����
       ,vis_g_num                  --�K��f����
       ,vis_h_num                  --�K��g����
       ,vis_i_num                  --�K���@����
       ,vis_j_num                  --�K��i����
       ,vis_k_num                  --�K��j����
       ,vis_l_num                  --�K��k����
       ,vis_m_num                  --�K��l����
       ,vis_n_num                  --�K��m����
       ,vis_o_num                  --�K��n����
       ,vis_p_num                  --�K��o����
       ,vis_q_num                  --�K��p����
       ,vis_r_num                  --�K��q����
       ,vis_s_num                  --�K��r����
       ,vis_t_num                  --�K��s����
       ,vis_u_num                  --�K��t����
       ,vis_v_num                  --�K��u����
       ,vis_w_num                  --�K��v����
       ,vis_x_num                  --�K��w����
       ,vis_y_num                  --�K��x����
       ,vis_z_num                  --�K��y����
      )VALUES(
        cn_created_by                                --�쐬��
       ,cd_creation_date                             --�쐬��
       ,cn_last_updated_by                           --�ŏI�X�V��
       ,cd_last_update_date                          --�ŏI�X�V��
       ,cn_last_update_login                         --�ŏI�X�V���O�C��
       ,cn_request_id                                --�v��ID
       ,cn_program_application_id                    --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,cn_program_id                                --�R���J�����g�E�v���O����ID
       ,cd_program_update_date                       --�v���O�����X�V��
       ,cv_sum_org_type_accnt                        --�W�v�g�D���
       ,g_get_day_acct_data_rec.sum_org_code               --�W�v�g�D�b�c
/* 20090519_Ogawa_T1_1037 START*/
--     ,cv_null                                            --�O���[�v�e���_�b�c
       ,g_get_day_acct_data_rec.group_base_code            --�O���[�v�e���_�b�c
/* 20090519_Ogawa_T1_1037 END*/
       ,cv_month_date_div_day                              --�����敪
       ,g_get_day_acct_data_rec.sales_date                 --�̔��N�����^�̔��N��
       ,g_get_day_acct_data_rec.gvm_type                   --��ʁ^���̋@�^�l�b
       ,g_get_day_acct_data_rec.cust_new_num               --�ڋq�����i�V�K�j
       ,g_get_day_acct_data_rec.cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
       ,g_get_day_acct_data_rec.cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
/* 20090519_Ogawa_T1_1024 START*/
/* 20090519_Ogawa_T1_1037 START*/
/* 20090519_Ogawa_T1_1038 START*/
--     /* 20090501_abe_����v��o�͑Ή� START*/
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --�������
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_new_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_new_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_new_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --������сi�V�K�j
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_vd_new_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_vd_new_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_vd_new_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --������сiVD�F�V�K�j
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_vd_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_vd_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_vd_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --������сiVD�j
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_other_new_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_other_new_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_other_new_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --������сiVD�ȊO�F�V�K�j
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_other_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_other_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_other_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --������сiVD�ȊO�j
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_center_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --�������_�Q�������
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_vd_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_center_vd_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_vd_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --�������_�Q������сiVD�j
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_other_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_center_other_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_other_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --�������_�Q������сiVD�ȊO�j
--     --,g_get_day_acct_data_rec.rslt_amt                   --�������
--     --,g_get_day_acct_data_rec.rslt_new_amt               --������сi�V�K�j
--     --,g_get_day_acct_data_rec.rslt_vd_new_amt            --������сiVD�F�V�K�j
--     --,g_get_day_acct_data_rec.rslt_vd_amt                --������сiVD�j
--     --,g_get_day_acct_data_rec.rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
--     --,g_get_day_acct_data_rec.rslt_other_amt             --������сiVD�ȊO�j
--     --,g_get_day_acct_data_rec.rslt_center_amt            --�������_�Q�������
--     --,g_get_day_acct_data_rec.rslt_center_vd_amt         --�������_�Q������сiVD�j
--     --,g_get_day_acct_data_rec.rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
--     /* 20090501_abe_����v��o�͑Ή� END*/
       ,g_get_day_acct_data_rec.rslt_amt                   --�������
       ,g_get_day_acct_data_rec.rslt_new_amt               --������сi�V�K�j
       ,g_get_day_acct_data_rec.rslt_vd_new_amt            --������сiVD�F�V�K�j
       ,g_get_day_acct_data_rec.rslt_vd_amt                --������сiVD�j
       ,g_get_day_acct_data_rec.rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
       ,g_get_day_acct_data_rec.rslt_other_amt             --������сiVD�ȊO�j
       ,g_get_day_acct_data_rec.rslt_center_amt            --�������_�Q�������
       ,g_get_day_acct_data_rec.rslt_center_vd_amt         --�������_�Q������сiVD�j
       ,g_get_day_acct_data_rec.rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
/* 20090519_Ogawa_T1_1024 END*/
/* 20090519_Ogawa_T1_1037 END*/
/* 20090519_Ogawa_T1_1038 END*/
       ,g_get_day_acct_data_rec.tgt_amt                    --����v��
       ,NULL                                               --����v��i�V�K�j
       ,NULL                                               --����v��iVD�F�V�K�j
       ,g_get_day_acct_data_rec.tgt_vd_amt                 --����v��iVD�j
       ,NULL                                               --����v��iVD�ȊO�F�V�K�j
       ,g_get_day_acct_data_rec.tgt_other_amt              --����v��iVD�ȊO�j
       ,g_get_day_acct_data_rec.vis_num                    --�K�����
       ,g_get_day_acct_data_rec.vis_new_num                --�K����сi�V�K�j
       ,g_get_day_acct_data_rec.vis_vd_new_num             --�K����сiVD�F�V�K�j
       ,g_get_day_acct_data_rec.vis_vd_num                 --�K����сiVD�j
       ,g_get_day_acct_data_rec.vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
       ,g_get_day_acct_data_rec.vis_other_num              --�K����сiVD�ȊO�j
       ,g_get_day_acct_data_rec.vis_mc_num                 --�K����сiMC�j
       ,g_get_day_acct_data_rec.vis_sales_num              --�L������
       ,g_get_day_acct_data_rec.tgt_vis_num                --�K��v��
       ,NULL                                               --�K��v��i�V�K�j
       ,NULL                                               --�K��v��iVD�F�V�K�j
       ,g_get_day_acct_data_rec.tgt_vis_vd_num             --�K��v��iVD�j
       ,NULL                                               --�K��v��iVD�ȊO�F�V�K�j
       ,g_get_day_acct_data_rec.tgt_vis_other_num          --�K��v��iVD�ȊO�j
       ,NULL                                               --�K��v��iMC�j
       ,g_get_day_acct_data_rec.vis_a_num                  --�K��`����
       ,g_get_day_acct_data_rec.vis_b_num                  --�K��a����
       ,g_get_day_acct_data_rec.vis_c_num                  --�K��b����
       ,g_get_day_acct_data_rec.vis_d_num                  --�K��c����
       ,g_get_day_acct_data_rec.vis_e_num                  --�K��d����
       ,g_get_day_acct_data_rec.vis_f_num                  --�K��e����
       ,g_get_day_acct_data_rec.vis_g_num                  --�K��f����
       ,g_get_day_acct_data_rec.vis_h_num                  --�K��g����
       ,g_get_day_acct_data_rec.vis_i_num                  --�K���@����
       ,g_get_day_acct_data_rec.vis_j_num                  --�K��i����
       ,g_get_day_acct_data_rec.vis_k_num                  --�K��j����
       ,g_get_day_acct_data_rec.vis_l_num                  --�K��k����
       ,g_get_day_acct_data_rec.vis_m_num                  --�K��l����
       ,g_get_day_acct_data_rec.vis_n_num                  --�K��m����
       ,g_get_day_acct_data_rec.vis_o_num                  --�K��n����
       ,g_get_day_acct_data_rec.vis_p_num                  --�K��o����
       ,g_get_day_acct_data_rec.vis_q_num                  --�K��p����
       ,g_get_day_acct_data_rec.vis_r_num                  --�K��q����
       ,g_get_day_acct_data_rec.vis_s_num                  --�K��r����
       ,g_get_day_acct_data_rec.vis_t_num                  --�K��s����
       ,g_get_day_acct_data_rec.vis_u_num                  --�K��t����
       ,g_get_day_acct_data_rec.vis_v_num                  --�K��u����
       ,g_get_day_acct_data_rec.vis_w_num                  --�K��v����
       ,g_get_day_acct_data_rec.vis_x_num                  --�K��w����
       ,g_get_day_acct_data_rec.vis_y_num                  --�K��x����
       ,g_get_day_acct_data_rec.vis_z_num                  --�K��y����
      )
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_05               --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                   --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_acct                    --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage              --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                        --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
    -- �o�͌����ɒǉ�
    gn_output_cnt := gn_output_cnt + 1;
--
  EXCEPTION
    -- *** �t�@�C��������O�n���h�� ***
    WHEN insert_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_day_acct_dt;
--
  /**********************************************************************************
   * Procedure Name   : get_day_acct_data
   * Description      : ���ʌڋq�ʃf�[�^�擾 (A-4)
   ***********************************************************************************/
  PROCEDURE get_day_acct_data(
     ov_errbuf         OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_day_acct_data';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_extrct_cnt        NUMBER;              -- ���o����
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
    get_data_error_expt    EXCEPTION;    -- �f�[�^���o������O
    prog_error_expt        EXCEPTION;    -- �T�u�v���O����������O
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- ���o�A�o�͌���������
    ln_extrct_cnt := 0;              -- ���o����
--
    BEGIN
      -- ========================
      -- ���ʌڋq�ʃf�[�^�擾
      -- ========================
      OPEN g_get_day_acct_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���I�[�v���������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn   || cv_day_acct || CHR(10)   ||
                   ''
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_04               --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_processing_name         --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_day_acct_data               --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmsg                  --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                        --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE get_data_error_expt;
    END;
--
    <<loop_g_get_day_acct_data>>
    LOOP 
      FETCH g_get_day_acct_data_cur INTO g_get_day_acct_data_rec;
      -- ���o�����i�[
      ln_extrct_cnt := g_get_day_acct_data_cur%ROWCOUNT;
      EXIT WHEN g_get_day_acct_data_cur%NOTFOUND
      OR  g_get_day_acct_data_cur%ROWCOUNT = 0;
      /* 2009.11.06 K.Satomura E_T4_00135�Ή� START */
      IF (g_get_day_acct_data_rec.sum_org_code IS NOT NULL
        AND g_get_day_acct_data_rec.group_base_code IS NOT NULL)
      THEN
      /* 2009.11.06 K.Satomura E_T4_00135�Ή� END */
        -- �K�┄��v��Ǘ��\�T�}���e�[�u���ɓo�^ (A-5)
        insert_day_acct_dt(
          ov_errbuf      =>  lv_errbuf             -- �G���[�E���b�Z�[�W
         ,ov_retcode     =>  lv_retcode            -- ���^�[���E�R�[�h
         ,ov_errmsg      =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE prog_error_expt;
        END IF;
      /* 2009.11.06 K.Satomura E_T4_00135�Ή� START */
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                             -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_12                        -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_sum_org_code                     -- �g�[�N���R�[�h1
                       ,iv_token_value1 => g_get_day_acct_data_rec.sum_org_code    -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_group_base_code                  -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_get_day_acct_data_rec.group_base_code -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_sales_date                       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_get_day_acct_data_rec.sales_date      -- �g�[�N���l3
                     );
        --
        lv_errbuf   := lv_errmsg;
        lv_retcode  := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
        --
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg || CHR(10) || ''
        );
        --
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg || CHR(10) || ''
        );
        --
      END IF;
      /* 2009.11.06 K.Satomura E_T4_00135�Ή� END */
    END LOOP;
    -- *** DEBUG_LOG ***
    -- ���ʌڋq�ʎ擾�o�^�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_d_acct  || CHR(10) ||
                 ''
    );
    -- �J�[�\���N���[�Y
    CLOSE g_get_day_acct_data_cur;
--
    -- *** DEBUG_LOG ***
    -- �J�[�\���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1|| cv_day_acct || CHR(10) ||
                 ''
    );
    -- ���o�����i�[
    gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
    -- *** DEBUG_LOG ***
    -- ���o�A�o�͌��������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg6  || CHR(10) ||
                 cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                 cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                 cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                 ''
    );
  EXCEPTION
    -- *** �f�[�^���o������O�n���h�� ***
    WHEN get_data_error_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   ''
      );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** �T�u�v���O����������O�n���h�� ***
    WHEN prog_error_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   ''
      );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_day_acct_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_emp_dt
   * Description      : ���ʉc�ƈ��ʎ擾�o�^ (A-6)
   ***********************************************************************************/
  PROCEDURE insert_day_emp_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_emp_dt';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_extrct_cnt        NUMBER;              -- ���o����
    ln_output_cnt        NUMBER;              -- �o�͌���
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ʉc�ƈ��ʃf�[�^�擾�p�J�[�\��
    CURSOR day_emp_dt_cur
    IS
      SELECT
        xcrv2.employee_number            sum_org_code               --�W�v�g�D�b�c
       ,xsvsr.sales_date                 sales_date                 --�̔��N�����^�̔��N��
       ,SUM(xsvsr.cust_new_num         ) cust_new_num               --�ڋq�����i�V�K�j
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --�������
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --������сi�V�K�j
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --������сiVD�F�V�K�j
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --������сiVD�j
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --������сiVD�ȊO�j
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --�������_�Q�������
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --�������_�Q������сiVD�j
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --����v��
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --����v��i�V�K�j
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --����v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --����v��iVD�j
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --����v��iVD�ȊO�j
       ,SUM(xsvsr.vis_num              ) vis_num                    --�K�����
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --�K����сi�V�K�j
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --�K����сiVD�F�V�K�j
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --�K����сiVD�j
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --�K����сiVD�ȊO�j
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --�K����сiMC�j
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --�L������
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --�K��v��
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --�K��v��i�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --�K��v��iVD�j
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --�K��v��iVD�ȊO�j
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --�K��v��iMC�j
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --�K��`����
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --�K��a����
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --�K��b����
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --�K��c����
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --�K��d����
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --�K��e����
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --�K��f����
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --�K��g����
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --�K���@����
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --�K��i����
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --�K��j����
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --�K��k����
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --�K��l����
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --�K��m����
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --�K��n����
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --�K��o����
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --�K��p����
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --�K��q����
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --�K��r����
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --�K��s����
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --�K��t����
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --�K��u����
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --�K��v����
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --�K��w����
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --�K��x����
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --�K��y����
      FROM
        xxcso_cust_resources_v2 xcrv2  -- �ڋq�S���c�ƈ��i�ŐV�j�r���[
       ,xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}���e�[�u��
      WHERE  xsvsr.sum_org_type = cv_sum_org_type_accnt  -- �W�v�g�D���
      AND    xcrv2.account_number = xsvsr.sum_org_code  -- �ڋq�R�[�h
      AND    xsvsr.month_date_div = cv_month_date_div_day  -- �����敪
      AND    xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                  AND TO_CHAR(LAST_DAY(gd_process_date), 'YYYYMMDD')
      GROUP BY  xcrv2.employee_number     --�]�ƈ��ԍ�
               ,xsvsr.sales_date          --�̔��N�����^�̔��N��
    ;
    -- *** ���[�J���E���R�[�h ***
    -- ���ʉc�ƈ��ʃf�[�^�擾�p���R�[�h
     day_emp_dt_rec day_emp_dt_cur%ROWTYPE;
    -- *** ���[�J����O ***
    insert_error_expt    EXCEPTION;    -- �o�^������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���o�A�o�͌���������
    ln_extrct_cnt := 0;              -- ���o����
    ln_output_cnt := 0;              -- �o�͌���
    BEGIN
      -- ========================
      -- ���ʉc�ƈ��ʃf�[�^�擾
      -- ========================
      -- �J�[�\���I�[�v��
      OPEN day_emp_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- �J�[�\���I�[�v���������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn   || cv_day_emp || CHR(10)   ||
                   ''
      );
      -- ======================
      -- �K�┄��v��Ǘ��\�T�}���e�[�u���o�^���� 
      -- ======================
      <<loop_day_emp_dt>>
      LOOP
        FETCH day_emp_dt_cur INTO day_emp_dt_rec;
        -- ���o�����擾
        ln_extrct_cnt := day_emp_dt_cur%ROWCOUNT;
        EXIT WHEN day_emp_dt_cur%NOTFOUND
        OR  day_emp_dt_cur%ROWCOUNT = 0;
        -- �o�^����
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --�쐬��
         ,creation_date              --�쐬��
         ,last_updated_by            --�ŏI�X�V��
         ,last_update_date           --�ŏI�X�V��
         ,last_update_login          --�ŏI�X�V���O�C��
         ,request_id                 --�v��ID
         ,program_application_id     --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                 --�R���J�����g�E�v���O����ID
         ,program_update_date        --�v���O�����X�V��
         ,sum_org_type               --�W�v�g�D���
         ,sum_org_code               --�W�v�g�D�b�c
         ,group_base_code            --�O���[�v�e���_�b�c
         ,month_date_div             --�����敪
         ,sales_date                 --�̔��N�����^�̔��N��
         ,gvm_type                   --��ʁ^���̋@�^�l�b
         ,cust_new_num               --�ڋq�����i�V�K�j
         ,cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
         ,cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
         ,rslt_amt                   --�������
         ,rslt_new_amt               --������сi�V�K�j
         ,rslt_vd_new_amt            --������сiVD�F�V�K�j
         ,rslt_vd_amt                --������сiVD�j
         ,rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
         ,rslt_other_amt             --������сiVD�ȊO�j
         ,rslt_center_amt            --�������_�Q�������
         ,rslt_center_vd_amt         --�������_�Q������сiVD�j
         ,rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
         ,tgt_amt                    --����v��
         ,tgt_new_amt                --����v��i�V�K�j
         ,tgt_vd_new_amt             --����v��iVD�F�V�K�j
         ,tgt_vd_amt                 --����v��iVD�j
         ,tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
         ,tgt_other_amt              --����v��iVD�ȊO�j
         ,vis_num                    --�K�����
         ,vis_new_num                --�K����сi�V�K�j
         ,vis_vd_new_num             --�K����сiVD�F�V�K�j
         ,vis_vd_num                 --�K����сiVD�j
         ,vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
         ,vis_other_num              --�K����сiVD�ȊO�j
         ,vis_mc_num                 --�K����сiMC�j
         ,vis_sales_num              --�L������
         ,tgt_vis_num                --�K��v��
         ,tgt_vis_new_num            --�K��v��i�V�K�j
         ,tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
         ,tgt_vis_vd_num             --�K��v��iVD�j
         ,tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
         ,tgt_vis_other_num          --�K��v��iVD�ȊO�j
         ,tgt_vis_mc_num             --�K��v��iMC�j
         ,vis_a_num                  --�K��`����
         ,vis_b_num                  --�K��a����
         ,vis_c_num                  --�K��b����
         ,vis_d_num                  --�K��c����
         ,vis_e_num                  --�K��d����
         ,vis_f_num                  --�K��e����
         ,vis_g_num                  --�K��f����
         ,vis_h_num                  --�K��g����
         ,vis_i_num                  --�K���@����
         ,vis_j_num                  --�K��i����
         ,vis_k_num                  --�K��j����
         ,vis_l_num                  --�K��k����
         ,vis_m_num                  --�K��l����
         ,vis_n_num                  --�K��m����
         ,vis_o_num                  --�K��n����
         ,vis_p_num                  --�K��o����
         ,vis_q_num                  --�K��p����
         ,vis_r_num                  --�K��q����
         ,vis_s_num                  --�K��r����
         ,vis_t_num                  --�K��s����
         ,vis_u_num                  --�K��t����
         ,vis_v_num                  --�K��u����
         ,vis_w_num                  --�K��v����
         ,vis_x_num                  --�K��w����
         ,vis_y_num                  --�K��x����
         ,vis_z_num                  --�K��y����
        ) VALUES(
          cn_created_by                             --�쐬��
         ,cd_creation_date                          --�쐬��
         ,cn_last_updated_by                        --�ŏI�X�V��
         ,cd_last_update_date                       --�ŏI�X�V��
         ,cn_last_update_login                      --�ŏI�X�V���O�C��
         ,cn_request_id                             --�v��ID
         ,cn_program_application_id                 --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                             --�R���J�����g�E�v���O����ID
         ,cd_program_update_date                    --�v���O�����X�V��
         ,cv_sum_org_type_emp                       --�W�v�g�D���
         ,day_emp_dt_rec.sum_org_code               --�W�v�g�D�b�c
         ,cv_null                                   --�O���[�v�e���_�b�c
         ,cv_month_date_div_day                     --�����敪
         ,day_emp_dt_rec.sales_date                 --�̔��N�����^�̔��N��
         ,NULL                                      --��ʁ^���̋@�^�l�b
         ,day_emp_dt_rec.cust_new_num               --�ڋq�����i�V�K�j
         ,day_emp_dt_rec.cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
         ,day_emp_dt_rec.cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
         ,day_emp_dt_rec.rslt_amt                   --�������
         ,day_emp_dt_rec.rslt_new_amt               --������сi�V�K�j
         ,day_emp_dt_rec.rslt_vd_new_amt            --������сiVD�F�V�K�j
         ,day_emp_dt_rec.rslt_vd_amt                --������сiVD�j
         ,day_emp_dt_rec.rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
         ,day_emp_dt_rec.rslt_other_amt             --������сiVD�ȊO�j
         ,day_emp_dt_rec.rslt_center_amt            --�������_�Q�������
         ,day_emp_dt_rec.rslt_center_vd_amt         --�������_�Q������сiVD�j
         ,day_emp_dt_rec.rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
         ,day_emp_dt_rec.tgt_amt                    --����v��
         ,day_emp_dt_rec.tgt_new_amt                --����v��i�V�K�j
         ,day_emp_dt_rec.tgt_vd_new_amt             --����v��iVD�F�V�K�j
         ,day_emp_dt_rec.tgt_vd_amt                 --����v��iVD�j
         ,day_emp_dt_rec.tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
         ,day_emp_dt_rec.tgt_other_amt              --����v��iVD�ȊO�j
         ,day_emp_dt_rec.vis_num                    --�K�����
         ,day_emp_dt_rec.vis_new_num                --�K����сi�V�K�j
         ,day_emp_dt_rec.vis_vd_new_num             --�K����сiVD�F�V�K�j
         ,day_emp_dt_rec.vis_vd_num                 --�K����сiVD�j
         ,day_emp_dt_rec.vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
         ,day_emp_dt_rec.vis_other_num              --�K����сiVD�ȊO�j
         ,day_emp_dt_rec.vis_mc_num                 --�K����сiMC�j
         ,day_emp_dt_rec.vis_sales_num              --�L������
         ,day_emp_dt_rec.tgt_vis_num                --�K��v��
         ,day_emp_dt_rec.tgt_vis_new_num            --�K��v��i�V�K�j
         ,day_emp_dt_rec.tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
         ,day_emp_dt_rec.tgt_vis_vd_num             --�K��v��iVD�j
         ,day_emp_dt_rec.tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
         ,day_emp_dt_rec.tgt_vis_other_num          --�K��v��iVD�ȊO�j
         ,day_emp_dt_rec.tgt_vis_mc_num             --�K��v��iMC�j
         ,day_emp_dt_rec.vis_a_num                  --�K��`����
         ,day_emp_dt_rec.vis_b_num                  --�K��a����
         ,day_emp_dt_rec.vis_c_num                  --�K��b����
         ,day_emp_dt_rec.vis_d_num                  --�K��c����
         ,day_emp_dt_rec.vis_e_num                  --�K��d����
         ,day_emp_dt_rec.vis_f_num                  --�K��e����
         ,day_emp_dt_rec.vis_g_num                  --�K��f����
         ,day_emp_dt_rec.vis_h_num                  --�K��g����
         ,day_emp_dt_rec.vis_i_num                  --�K���@����
         ,day_emp_dt_rec.vis_j_num                  --�K��i����
         ,day_emp_dt_rec.vis_k_num                  --�K��j����
         ,day_emp_dt_rec.vis_l_num                  --�K��k����
         ,day_emp_dt_rec.vis_m_num                  --�K��l����
         ,day_emp_dt_rec.vis_n_num                  --�K��m����
         ,day_emp_dt_rec.vis_o_num                  --�K��n����
         ,day_emp_dt_rec.vis_p_num                  --�K��o����
         ,day_emp_dt_rec.vis_q_num                  --�K��p����
         ,day_emp_dt_rec.vis_r_num                  --�K��q����
         ,day_emp_dt_rec.vis_s_num                  --�K��r����
         ,day_emp_dt_rec.vis_t_num                  --�K��s����
         ,day_emp_dt_rec.vis_u_num                  --�K��t����
         ,day_emp_dt_rec.vis_v_num                  --�K��u����
         ,day_emp_dt_rec.vis_w_num                  --�K��v����
         ,day_emp_dt_rec.vis_x_num                  --�K��w����
         ,day_emp_dt_rec.vis_y_num                  --�K��x����
         ,day_emp_dt_rec.vis_z_num                  --�K��y����
        )
        ;
        -- �o�͌������Z
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_emp_dt;
      -- *** DEBUG_LOG ***
      -- ���ʉc�ƈ��ʎ擾�o�^�����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_d_emp  || CHR(10) ||
                   ''
      );
      -- �J�[�\���N���[�Y
      CLOSE day_emp_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_day_emp || CHR(10)   ||
                   ''
      );
        -- ���o�����i�[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- �o�͌����i�[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- ���o�A�o�͌��������O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_05               --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                   --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_emp                     --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage              --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                        --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** �o�^������O�n���h�� ***
    WHEN insert_error_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_emp_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_emp_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_emp_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_emp_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_emp_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_day_emp_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_group_dt
   * Description      : ���ʉc�ƃO���[�v�ʎ擾�o�^ (A-7)
   ***********************************************************************************/
  PROCEDURE insert_day_group_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_group_dt';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_extrct_cnt        NUMBER;              -- ���o����
    ln_output_cnt        NUMBER;              -- �o�͌���
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ʉc�ƃO���[�v�ʃf�[�^�擾�p�J�[�\��
    CURSOR day_group_dt_cur
    IS
      SELECT
        inn_v.sum_org_code               sum_org_code               --�W�v�g�D�b�c
       ,inn_v.group_base_code            group_base_code            --�O���[�v�e���_�b�c
       ,inn_v.sales_date                 sales_date                 --�̔��N�����^�̔��N��
       ,SUM(inn_v.cust_new_num         ) cust_new_num               --�ڋq�����i�V�K�j
       ,SUM(inn_v.cust_vd_new_num      ) cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
       ,SUM(inn_v.cust_other_new_num   ) cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
       ,SUM(inn_v.rslt_amt             ) rslt_amt                   --�������
       ,SUM(inn_v.rslt_new_amt         ) rslt_new_amt               --������сi�V�K�j
       ,SUM(inn_v.rslt_vd_new_amt      ) rslt_vd_new_amt            --������сiVD�F�V�K�j
       ,SUM(inn_v.rslt_vd_amt          ) rslt_vd_amt                --������сiVD�j
       ,SUM(inn_v.rslt_other_new_amt   ) rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
       ,SUM(inn_v.rslt_other_amt       ) rslt_other_amt             --������сiVD�ȊO�j
       ,SUM(inn_v.rslt_center_amt      ) rslt_center_amt            --�������_�Q�������
       ,SUM(inn_v.rslt_center_vd_amt   ) rslt_center_vd_amt         --�������_�Q������сiVD�j
       ,SUM(inn_v.rslt_center_other_amt) rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
       ,SUM(inn_v.tgt_amt              ) tgt_amt                    --����v��
       ,SUM(inn_v.tgt_new_amt          ) tgt_new_amt                --����v��i�V�K�j
       ,SUM(inn_v.tgt_vd_new_amt       ) tgt_vd_new_amt             --����v��iVD�F�V�K�j
       ,SUM(inn_v.tgt_vd_amt           ) tgt_vd_amt                 --����v��iVD�j
       ,SUM(inn_v.tgt_other_new_amt    ) tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
       ,SUM(inn_v.tgt_other_amt        ) tgt_other_amt              --����v��iVD�ȊO�j
       ,SUM(inn_v.vis_num              ) vis_num                    --�K�����
       ,SUM(inn_v.vis_new_num          ) vis_new_num                --�K����сi�V�K�j
       ,SUM(inn_v.vis_vd_new_num       ) vis_vd_new_num             --�K����сiVD�F�V�K�j
       ,SUM(inn_v.vis_vd_num           ) vis_vd_num                 --�K����сiVD�j
       ,SUM(inn_v.vis_other_new_num    ) vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
       ,SUM(inn_v.vis_other_num        ) vis_other_num              --�K����сiVD�ȊO�j
       ,SUM(inn_v.vis_mc_num           ) vis_mc_num                 --�K����сiMC�j
       ,SUM(inn_v.vis_sales_num        ) vis_sales_num              --�L������
       ,SUM(inn_v.tgt_vis_num          ) tgt_vis_num                --�K��v��
       ,SUM(inn_v.tgt_vis_new_num      ) tgt_vis_new_num            --�K��v��i�V�K�j
       ,SUM(inn_v.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
       ,SUM(inn_v.tgt_vis_vd_num       ) tgt_vis_vd_num             --�K��v��iVD�j
       ,SUM(inn_v.tgt_vis_other_new_num) tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
       ,SUM(inn_v.tgt_vis_other_num    ) tgt_vis_other_num          --�K��v��iVD�ȊO�j
       ,SUM(inn_v.tgt_vis_mc_num       ) tgt_vis_mc_num             --�K��v��iMC�j
       ,SUM(inn_v.vis_a_num            ) vis_a_num                  --�K��`����
       ,SUM(inn_v.vis_b_num            ) vis_b_num                  --�K��a����
       ,SUM(inn_v.vis_c_num            ) vis_c_num                  --�K��b����
       ,SUM(inn_v.vis_d_num            ) vis_d_num                  --�K��c����
       ,SUM(inn_v.vis_e_num            ) vis_e_num                  --�K��d����
       ,SUM(inn_v.vis_f_num            ) vis_f_num                  --�K��e����
       ,SUM(inn_v.vis_g_num            ) vis_g_num                  --�K��f����
       ,SUM(inn_v.vis_h_num            ) vis_h_num                  --�K��g����
       ,SUM(inn_v.vis_i_num            ) vis_i_num                  --�K���@����
       ,SUM(inn_v.vis_j_num            ) vis_j_num                  --�K��i����
       ,SUM(inn_v.vis_k_num            ) vis_k_num                  --�K��j����
       ,SUM(inn_v.vis_l_num            ) vis_l_num                  --�K��k����
       ,SUM(inn_v.vis_m_num            ) vis_m_num                  --�K��l����
       ,SUM(inn_v.vis_n_num            ) vis_n_num                  --�K��m����
       ,SUM(inn_v.vis_o_num            ) vis_o_num                  --�K��n����
       ,SUM(inn_v.vis_p_num            ) vis_p_num                  --�K��o����
       ,SUM(inn_v.vis_q_num            ) vis_q_num                  --�K��p����
       ,SUM(inn_v.vis_r_num            ) vis_r_num                  --�K��q����
       ,SUM(inn_v.vis_s_num            ) vis_s_num                  --�K��r����
       ,SUM(inn_v.vis_t_num            ) vis_t_num                  --�K��s����
       ,SUM(inn_v.vis_u_num            ) vis_u_num                  --�K��t����
       ,SUM(inn_v.vis_v_num            ) vis_v_num                  --�K��u����
       ,SUM(inn_v.vis_w_num            ) vis_w_num                  --�K��v����
       ,SUM(inn_v.vis_x_num            ) vis_x_num                  --�K��w����
       ,SUM(inn_v.vis_y_num            ) vis_y_num                  --�K��x����
       ,SUM(inn_v.vis_z_num            ) vis_z_num                  --�K��y����
      FROM
        (
         SELECT
           CASE WHEN (
                      TO_DATE(xrrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                     )
                THEN  NVL(xrrv2.group_number_new, cv_null)
                ELSE  NVL(xrrv2.group_number_old, cv_null)
           END                              sum_org_code             --�W�v�g�D�b�c
          ,CASE WHEN (
                      TO_DATE(xrrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                     )
                THEN  xrrv2.work_base_code_new
                ELSE  xrrv2.work_base_code_old
           END                              group_base_code          --�O���[�v�e���_�b�c
          ,xsvsr.sales_date                 sales_date               --�̔��N�����^�̔��N��
          ,xsvsr.cust_new_num               cust_new_num             --�ڋq�����i�V�K�j
          ,xsvsr.cust_vd_new_num            cust_vd_new_num          --�ڋq�����iVD�F�V�K�j
          ,xsvsr.cust_other_new_num         cust_other_new_num       --�ڋq�����iVD�ȊO�F�V�K�j
          ,xsvsr.rslt_amt                   rslt_amt                 --�������
          ,xsvsr.rslt_new_amt               rslt_new_amt             --������сi�V�K�j
          ,xsvsr.rslt_vd_new_amt            rslt_vd_new_amt          --������сiVD�F�V�K�j
          ,xsvsr.rslt_vd_amt                rslt_vd_amt              --������сiVD�j
          ,xsvsr.rslt_other_new_amt         rslt_other_new_amt       --������сiVD�ȊO�F�V�K�j
          ,xsvsr.rslt_other_amt             rslt_other_amt           --������сiVD�ȊO�j
          ,xsvsr.rslt_center_amt            rslt_center_amt          --�������_�Q�������
          ,xsvsr.rslt_center_vd_amt         rslt_center_vd_amt       --�������_�Q������сiVD�j
          ,xsvsr.rslt_center_other_amt      rslt_center_other_amt    --�������_�Q������сiVD�ȊO�j
          ,xsvsr.tgt_amt                    tgt_amt                  --����v��
          ,xsvsr.tgt_new_amt                tgt_new_amt              --����v��i�V�K�j
          ,xsvsr.tgt_vd_new_amt             tgt_vd_new_amt           --����v��iVD�F�V�K�j
          ,xsvsr.tgt_vd_amt                 tgt_vd_amt               --����v��iVD�j
          ,xsvsr.tgt_other_new_amt          tgt_other_new_amt        --����v��iVD�ȊO�F�V�K�j
          ,xsvsr.tgt_other_amt              tgt_other_amt            --����v��iVD�ȊO�j
          ,xsvsr.vis_num                    vis_num                  --�K�����
          ,xsvsr.vis_new_num                vis_new_num              --�K����сi�V�K�j
          ,xsvsr.vis_vd_new_num             vis_vd_new_num           --�K����сiVD�F�V�K�j
          ,xsvsr.vis_vd_num                 vis_vd_num               --�K����сiVD�j
          ,xsvsr.vis_other_new_num          vis_other_new_num        --�K����сiVD�ȊO�F�V�K�j
          ,xsvsr.vis_other_num              vis_other_num            --�K����сiVD�ȊO�j
          ,xsvsr.vis_mc_num                 vis_mc_num               --�K����сiMC�j
          ,xsvsr.vis_sales_num              vis_sales_num            --�L������
          ,xsvsr.tgt_vis_num                tgt_vis_num              --�K��v��
          ,xsvsr.tgt_vis_new_num            tgt_vis_new_num          --�K��v��i�V�K�j
          ,xsvsr.tgt_vis_vd_new_num         tgt_vis_vd_new_num       --�K��v��iVD�F�V�K�j
          ,xsvsr.tgt_vis_vd_num             tgt_vis_vd_num           --�K��v��iVD�j
          ,xsvsr.tgt_vis_other_new_num      tgt_vis_other_new_num    --�K��v��iVD�ȊO�F�V�K�j
          ,xsvsr.tgt_vis_other_num          tgt_vis_other_num        --�K��v��iVD�ȊO�j
          ,xsvsr.tgt_vis_mc_num             tgt_vis_mc_num           --�K��v��iMC�j
          ,xsvsr.vis_a_num                  vis_a_num                --�K��`����
          ,xsvsr.vis_b_num                  vis_b_num                --�K��a����
          ,xsvsr.vis_c_num                  vis_c_num                --�K��b����
          ,xsvsr.vis_d_num                  vis_d_num                --�K��c����
          ,xsvsr.vis_e_num                  vis_e_num                --�K��d����
          ,xsvsr.vis_f_num                  vis_f_num                --�K��e����
          ,xsvsr.vis_g_num                  vis_g_num                --�K��f����
          ,xsvsr.vis_h_num                  vis_h_num                --�K��g����
          ,xsvsr.vis_i_num                  vis_i_num                --�K���@����
          ,xsvsr.vis_j_num                  vis_j_num                --�K��i����
          ,xsvsr.vis_k_num                  vis_k_num                --�K��j����
          ,xsvsr.vis_l_num                  vis_l_num                --�K��k����
          ,xsvsr.vis_m_num                  vis_m_num                --�K��l����
          ,xsvsr.vis_n_num                  vis_n_num                --�K��m����
          ,xsvsr.vis_o_num                  vis_o_num                --�K��n����
          ,xsvsr.vis_p_num                  vis_p_num                --�K��o����
          ,xsvsr.vis_q_num                  vis_q_num                --�K��p����
          ,xsvsr.vis_r_num                  vis_r_num                --�K��q����
          ,xsvsr.vis_s_num                  vis_s_num                --�K��r����
          ,xsvsr.vis_t_num                  vis_t_num                --�K��s����
          ,xsvsr.vis_u_num                  vis_u_num                --�K��t����
          ,xsvsr.vis_v_num                  vis_v_num                --�K��u����
          ,xsvsr.vis_w_num                  vis_w_num                --�K��v����
          ,xsvsr.vis_x_num                  vis_x_num                --�K��w����
          ,xsvsr.vis_y_num                  vis_y_num                --�K��x����
          ,xsvsr.vis_z_num                  vis_z_num                --�K��y����
         FROM
           xxcso_resource_relations_v2 xrrv2  -- ���\�[�X�֘A�}�X�^�i�ŐV�j�r���[
          ,xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}���e�[�u��
         WHERE  xsvsr.sum_org_type = cv_sum_org_type_emp  -- �W�v�g�D���
           AND  xrrv2.employee_number = xsvsr.sum_org_code  -- �]�ƈ��ԍ�
           AND  xsvsr.month_date_div = cv_month_date_div_day  -- �����敪
           AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                     AND TO_CHAR(LAST_DAY(gd_process_date), 'YYYYMMDD')
        ) inn_v
      GROUP BY  inn_v.sum_org_code           --�O���[�v�ԍ�
               ,inn_v.group_base_code        --�O���[�v�e���_�b�c
               ,inn_v.sales_date             --�̔��N�����^�̔��N��
    ;
    -- *** ���[�J���E���R�[�h ***
    -- ���ʉc�ƃO���[�v�ʃf�[�^�擾�p���R�[�h
     day_group_dt_rec day_group_dt_cur%ROWTYPE;
    -- *** ���[�J����O ***
    insert_error_expt    EXCEPTION;    -- �o�^������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���o�A�o�͌���������
    ln_extrct_cnt := 0;              -- ���o����
    ln_output_cnt := 0;              -- �o�͌���
    -- ========================
    -- ���ʉc�ƈ��ʃf�[�^�擾
    -- ========================
    -- �J�[�\���I�[�v��
    OPEN day_group_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- �J�[�\���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_day_group || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- �K�┄��v��Ǘ��\�T�}���e�[�u���o�^���� 
      -- ======================
      <<loop_day_group_dt>>
      LOOP
        FETCH day_group_dt_cur INTO day_group_dt_rec;
        -- ���o�����擾
        ln_extrct_cnt := day_group_dt_cur%ROWCOUNT;
        EXIT WHEN day_group_dt_cur%NOTFOUND
        OR  day_group_dt_cur%ROWCOUNT = 0;
        -- �o�^����
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --�쐬��
         ,creation_date              --�쐬��
         ,last_updated_by            --�ŏI�X�V��
         ,last_update_date           --�ŏI�X�V��
         ,last_update_login          --�ŏI�X�V���O�C��
         ,request_id                 --�v��ID
         ,program_application_id     --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                 --�R���J�����g�E�v���O����ID
         ,program_update_date        --�v���O�����X�V��
         ,sum_org_type               --�W�v�g�D���
         ,sum_org_code               --�W�v�g�D�b�c
         ,group_base_code            --�O���[�v�e���_�b�c
         ,month_date_div             --�����敪
         ,sales_date                 --�̔��N�����^�̔��N��
         ,gvm_type                   --��ʁ^���̋@�^�l�b
         ,cust_new_num               --�ڋq�����i�V�K�j
         ,cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
         ,cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
         ,rslt_amt                   --�������
         ,rslt_new_amt               --������сi�V�K�j
         ,rslt_vd_new_amt            --������сiVD�F�V�K�j
         ,rslt_vd_amt                --������сiVD�j
         ,rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
         ,rslt_other_amt             --������сiVD�ȊO�j
         ,rslt_center_amt            --�������_�Q�������
         ,rslt_center_vd_amt         --�������_�Q������сiVD�j
         ,rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
         ,tgt_amt                    --����v��
         ,tgt_new_amt                --����v��i�V�K�j
         ,tgt_vd_new_amt             --����v��iVD�F�V�K�j
         ,tgt_vd_amt                 --����v��iVD�j
         ,tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
         ,tgt_other_amt              --����v��iVD�ȊO�j
         ,vis_num                    --�K�����
         ,vis_new_num                --�K����сi�V�K�j
         ,vis_vd_new_num             --�K����сiVD�F�V�K�j
         ,vis_vd_num                 --�K����сiVD�j
         ,vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
         ,vis_other_num              --�K����сiVD�ȊO�j
         ,vis_mc_num                 --�K����сiMC�j
         ,vis_sales_num              --�L������
         ,tgt_vis_num                --�K��v��
         ,tgt_vis_new_num            --�K��v��i�V�K�j
         ,tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
         ,tgt_vis_vd_num             --�K��v��iVD�j
         ,tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
         ,tgt_vis_other_num          --�K��v��iVD�ȊO�j
         ,tgt_vis_mc_num             --�K��v��iMC�j
         ,vis_a_num                  --�K��`����
         ,vis_b_num                  --�K��a����
         ,vis_c_num                  --�K��b����
         ,vis_d_num                  --�K��c����
         ,vis_e_num                  --�K��d����
         ,vis_f_num                  --�K��e����
         ,vis_g_num                  --�K��f����
         ,vis_h_num                  --�K��g����
         ,vis_i_num                  --�K���@����
         ,vis_j_num                  --�K��i����
         ,vis_k_num                  --�K��j����
         ,vis_l_num                  --�K��k����
         ,vis_m_num                  --�K��l����
         ,vis_n_num                  --�K��m����
         ,vis_o_num                  --�K��n����
         ,vis_p_num                  --�K��o����
         ,vis_q_num                  --�K��p����
         ,vis_r_num                  --�K��q����
         ,vis_s_num                  --�K��r����
         ,vis_t_num                  --�K��s����
         ,vis_u_num                  --�K��t����
         ,vis_v_num                  --�K��u����
         ,vis_w_num                  --�K��v����
         ,vis_x_num                  --�K��w����
         ,vis_y_num                  --�K��x����
         ,vis_z_num                  --�K��y����
        ) VALUES(
          cn_created_by                              --�쐬��
         ,cd_creation_date                           --�쐬��
         ,cn_last_updated_by                         --�ŏI�X�V��
         ,cd_last_update_date                        --�ŏI�X�V��
         ,cn_last_update_login                       --�ŏI�X�V���O�C��
         ,cn_request_id                              --�v��ID
         ,cn_program_application_id                  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                              --�R���J�����g�E�v���O����ID
         ,cd_program_update_date                     --�v���O�����X�V��
         ,cv_sum_org_type_group                      --�W�v�g�D���
         ,day_group_dt_rec.sum_org_code              --�W�v�g�D�b�c
         ,day_group_dt_rec.group_base_code            --�O���[�v�e���_�b�c
         ,cv_month_date_div_day                      --�����敪
         ,day_group_dt_rec.sales_date                --�̔��N�����^�̔��N��
         ,NULL                                       --��ʁ^���̋@�^�l�b
         ,day_group_dt_rec.cust_new_num              --�ڋq�����i�V�K�j
         ,day_group_dt_rec.cust_vd_new_num           --�ڋq�����iVD�F�V�K�j
         ,day_group_dt_rec.cust_other_new_num        --�ڋq�����iVD�ȊO�F�V�K�j
         ,day_group_dt_rec.rslt_amt                  --�������
         ,day_group_dt_rec.rslt_new_amt              --������сi�V�K�j
         ,day_group_dt_rec.rslt_vd_new_amt           --������сiVD�F�V�K�j
         ,day_group_dt_rec.rslt_vd_amt               --������сiVD�j
         ,day_group_dt_rec.rslt_other_new_amt        --������сiVD�ȊO�F�V�K�j
         ,day_group_dt_rec.rslt_other_amt            --������сiVD�ȊO�j
         ,day_group_dt_rec.rslt_center_amt           --�������_�Q�������
         ,day_group_dt_rec.rslt_center_vd_amt        --�������_�Q������сiVD�j
         ,day_group_dt_rec.rslt_center_other_amt     --�������_�Q������сiVD�ȊO�j
         ,day_group_dt_rec.tgt_amt                   --����v��
         ,day_group_dt_rec.tgt_new_amt               --����v��i�V�K�j
         ,day_group_dt_rec.tgt_vd_new_amt            --����v��iVD�F�V�K�j
         ,day_group_dt_rec.tgt_vd_amt                --����v��iVD�j
         ,day_group_dt_rec.tgt_other_new_amt         --����v��iVD�ȊO�F�V�K�j
         ,day_group_dt_rec.tgt_other_amt             --����v��iVD�ȊO�j
         ,day_group_dt_rec.vis_num                   --�K�����
         ,day_group_dt_rec.vis_new_num               --�K����сi�V�K�j
         ,day_group_dt_rec.vis_vd_new_num            --�K����сiVD�F�V�K�j
         ,day_group_dt_rec.vis_vd_num                --�K����сiVD�j
         ,day_group_dt_rec.vis_other_new_num         --�K����сiVD�ȊO�F�V�K�j
         ,day_group_dt_rec.vis_other_num             --�K����сiVD�ȊO�j
         ,day_group_dt_rec.vis_mc_num                --�K����сiMC�j
         ,day_group_dt_rec.vis_sales_num             --�L������
         ,day_group_dt_rec.tgt_vis_num               --�K��v��
         ,day_group_dt_rec.tgt_vis_new_num           --�K��v��i�V�K�j
         ,day_group_dt_rec.tgt_vis_vd_new_num        --�K��v��iVD�F�V�K�j
         ,day_group_dt_rec.tgt_vis_vd_num            --�K��v��iVD�j
         ,day_group_dt_rec.tgt_vis_other_new_num     --�K��v��iVD�ȊO�F�V�K�j
         ,day_group_dt_rec.tgt_vis_other_num         --�K��v��iVD�ȊO�j
         ,day_group_dt_rec.tgt_vis_mc_num            --�K��v��iMC�j
         ,day_group_dt_rec.vis_a_num                 --�K��`����
         ,day_group_dt_rec.vis_b_num                 --�K��a����
         ,day_group_dt_rec.vis_c_num                 --�K��b����
         ,day_group_dt_rec.vis_d_num                 --�K��c����
         ,day_group_dt_rec.vis_e_num                 --�K��d����
         ,day_group_dt_rec.vis_f_num                 --�K��e����
         ,day_group_dt_rec.vis_g_num                 --�K��f����
         ,day_group_dt_rec.vis_h_num                 --�K��g����
         ,day_group_dt_rec.vis_i_num                 --�K���@����
         ,day_group_dt_rec.vis_j_num                 --�K��i����
         ,day_group_dt_rec.vis_k_num                 --�K��j����
         ,day_group_dt_rec.vis_l_num                 --�K��k����
         ,day_group_dt_rec.vis_m_num                 --�K��l����
         ,day_group_dt_rec.vis_n_num                 --�K��m����
         ,day_group_dt_rec.vis_o_num                 --�K��n����
         ,day_group_dt_rec.vis_p_num                 --�K��o����
         ,day_group_dt_rec.vis_q_num                 --�K��p����
         ,day_group_dt_rec.vis_r_num                 --�K��q����
         ,day_group_dt_rec.vis_s_num                 --�K��r����
         ,day_group_dt_rec.vis_t_num                 --�K��s����
         ,day_group_dt_rec.vis_u_num                 --�K��t����
         ,day_group_dt_rec.vis_v_num                 --�K��u����
         ,day_group_dt_rec.vis_w_num                 --�K��v����
         ,day_group_dt_rec.vis_x_num                 --�K��w����
         ,day_group_dt_rec.vis_y_num                 --�K��x����
         ,day_group_dt_rec.vis_z_num                 --�K��y����
        )
        ;
        -- �o�͌������Z
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_group_dt;
      -- *** DEBUG_LOG ***
      -- ���ʃO���[�v�ʎ擾�o�^�����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_d_grp  || CHR(10) ||
                   ''
      );
      -- �J�[�\���N���[�Y
      CLOSE day_group_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_day_group || CHR(10)   ||
                   ''
      );
        -- ���o�����i�[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- �o�͌����i�[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- ���o�A�o�͌��������O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_05               --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                   --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_group                   --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage              --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                        --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** �o�^������O�n���h�� ***
    WHEN insert_error_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_group_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_group_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_group_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_group_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_group_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_day_group_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_base_dt
   * Description      : ���ʋ��_�^�ەʎ擾�o�^ (A-8)
   ***********************************************************************************/
  PROCEDURE insert_day_base_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_base_dt';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_extrct_cnt        NUMBER;              -- ���o����
    ln_output_cnt        NUMBER;              -- �o�͌���
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ʋ��_�^�ەʃf�[�^�擾�p�J�[�\��
    CURSOR day_base_dt_cur
    IS
      SELECT
        xsvsr.group_base_code            sum_org_code          --�W�v�g�D�b�c
       ,xsvsr.sales_date                 sales_date            --�̔��N�����^�̔��N��
       ,SUM(xsvsr.cust_new_num         ) cust_new_num          --�ڋq�����i�V�K�j
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num       --�ڋq�����iVD�F�V�K�j
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num    --�ڋq�����iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_amt             ) rslt_amt              --�������
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt          --������сi�V�K�j
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt       --������сiVD�F�V�K�j
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt           --������сiVD�j
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt    --������сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt        --������сiVD�ȊO�j
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt       --�������_�Q�������
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt    --�������_�Q������сiVD�j
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt --�������_�Q������сiVD�ȊO�j
       ,SUM(xsvsr.tgt_amt              ) tgt_amt               --����v��
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt           --����v��i�V�K�j
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt        --����v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt            --����v��iVD�j
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt     --����v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt         --����v��iVD�ȊO�j
       ,SUM(xsvsr.vis_num              ) vis_num               --�K�����
       ,SUM(xsvsr.vis_new_num          ) vis_new_num           --�K����сi�V�K�j
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num        --�K����сiVD�F�V�K�j
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num            --�K����сiVD�j
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num     --�K����сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.vis_other_num        ) vis_other_num         --�K����сiVD�ȊO�j
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num            --�K����сiMC�j
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num         --�L������
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num           --�K��v��
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num       --�K��v��i�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num    --�K��v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num        --�K��v��iVD�j
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num --�K��v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num     --�K��v��iVD�ȊO�j
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num        --�K��v��iMC�j
       ,SUM(xsvsr.vis_a_num            ) vis_a_num             --�K��`����
       ,SUM(xsvsr.vis_b_num            ) vis_b_num             --�K��a����
       ,SUM(xsvsr.vis_c_num            ) vis_c_num             --�K��b����
       ,SUM(xsvsr.vis_d_num            ) vis_d_num             --�K��c����
       ,SUM(xsvsr.vis_e_num            ) vis_e_num             --�K��d����
       ,SUM(xsvsr.vis_f_num            ) vis_f_num             --�K��e����
       ,SUM(xsvsr.vis_g_num            ) vis_g_num             --�K��f����
       ,SUM(xsvsr.vis_h_num            ) vis_h_num             --�K��g����
       ,SUM(xsvsr.vis_i_num            ) vis_i_num             --�K���@����
       ,SUM(xsvsr.vis_j_num            ) vis_j_num             --�K��i����
       ,SUM(xsvsr.vis_k_num            ) vis_k_num             --�K��j����
       ,SUM(xsvsr.vis_l_num            ) vis_l_num             --�K��k����
       ,SUM(xsvsr.vis_m_num            ) vis_m_num             --�K��l����
       ,SUM(xsvsr.vis_n_num            ) vis_n_num             --�K��m����
       ,SUM(xsvsr.vis_o_num            ) vis_o_num             --�K��n����
       ,SUM(xsvsr.vis_p_num            ) vis_p_num             --�K��o����
       ,SUM(xsvsr.vis_q_num            ) vis_q_num             --�K��p����
       ,SUM(xsvsr.vis_r_num            ) vis_r_num             --�K��q����
       ,SUM(xsvsr.vis_s_num            ) vis_s_num             --�K��r����
       ,SUM(xsvsr.vis_t_num            ) vis_t_num             --�K��s����
       ,SUM(xsvsr.vis_u_num            ) vis_u_num             --�K��t����
       ,SUM(xsvsr.vis_v_num            ) vis_v_num             --�K��u����
       ,SUM(xsvsr.vis_w_num            ) vis_w_num             --�K��v����
       ,SUM(xsvsr.vis_x_num            ) vis_x_num             --�K��w����
       ,SUM(xsvsr.vis_y_num            ) vis_y_num             --�K��x����
       ,SUM(xsvsr.vis_z_num            ) vis_z_num             --�K��y����
      FROM
        xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}���e�[�u��
      WHERE  xsvsr.sum_org_type = cv_sum_org_type_group  -- �W�v�g�D���
        AND  xsvsr.month_date_div = cv_month_date_div_day  -- �����敪
        AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                  AND TO_CHAR(LAST_DAY(gd_process_date), 'YYYYMMDD')
      GROUP BY  xsvsr.group_base_code  --�O���[�v�e���_CD
               ,xsvsr.sales_date       --�̔��N�����^�̔��N��
    ;
    -- *** ���[�J���E���R�[�h ***
    -- ���ʋ��_�^�ەʃf�[�^�擾�p���R�[�h
     day_base_dt_rec day_base_dt_cur%ROWTYPE;
    -- *** ���[�J����O ***
    insert_error_expt    EXCEPTION;    -- �o�^������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���o�A�o�͌���������
    ln_extrct_cnt := 0;              -- ���o����
    ln_output_cnt := 0;              -- �o�͌���
    -- ========================
    -- ���ʋ��_�^�ەʃf�[�^�擾
    -- ========================
    -- �J�[�\���I�[�v��
    OPEN day_base_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- �J�[�\���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_day_base || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- �K�┄��v��Ǘ��\�T�}���e�[�u���o�^���� 
      -- ======================
      <<loop_day_base_dt>>
      LOOP
        FETCH day_base_dt_cur INTO day_base_dt_rec;
        -- ���o�����擾
        ln_extrct_cnt := day_base_dt_cur%ROWCOUNT;
        EXIT WHEN day_base_dt_cur%NOTFOUND
        OR  day_base_dt_cur%ROWCOUNT = 0;
        -- �o�^����
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --�쐬��
         ,creation_date              --�쐬��
         ,last_updated_by            --�ŏI�X�V��
         ,last_update_date           --�ŏI�X�V��
         ,last_update_login          --�ŏI�X�V���O�C��
         ,request_id                 --�v��ID
         ,program_application_id     --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                 --�R���J�����g�E�v���O����ID
         ,program_update_date        --�v���O�����X�V��
         ,sum_org_type               --�W�v�g�D���
         ,sum_org_code               --�W�v�g�D�b�c
         ,group_base_code            --�O���[�v�e���_�b�c
         ,month_date_div             --�����敪
         ,sales_date                 --�̔��N�����^�̔��N��
         ,gvm_type                   --��ʁ^���̋@�^�l�b
         ,cust_new_num               --�ڋq�����i�V�K�j
         ,cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
         ,cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
         ,rslt_amt                   --�������
         ,rslt_new_amt               --������сi�V�K�j
         ,rslt_vd_new_amt            --������сiVD�F�V�K�j
         ,rslt_vd_amt                --������сiVD�j
         ,rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
         ,rslt_other_amt             --������сiVD�ȊO�j
         ,rslt_center_amt            --�������_�Q�������
         ,rslt_center_vd_amt         --�������_�Q������сiVD�j
         ,rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
         ,tgt_amt                    --����v��
         ,tgt_new_amt                --����v��i�V�K�j
         ,tgt_vd_new_amt             --����v��iVD�F�V�K�j
         ,tgt_vd_amt                 --����v��iVD�j
         ,tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
         ,tgt_other_amt              --����v��iVD�ȊO�j
         ,vis_num                    --�K�����
         ,vis_new_num                --�K����сi�V�K�j
         ,vis_vd_new_num             --�K����сiVD�F�V�K�j
         ,vis_vd_num                 --�K����сiVD�j
         ,vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
         ,vis_other_num              --�K����сiVD�ȊO�j
         ,vis_mc_num                 --�K����сiMC�j
         ,vis_sales_num              --�L������
         ,tgt_vis_num                --�K��v��
         ,tgt_vis_new_num            --�K��v��i�V�K�j
         ,tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
         ,tgt_vis_vd_num             --�K��v��iVD�j
         ,tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
         ,tgt_vis_other_num          --�K��v��iVD�ȊO�j
         ,tgt_vis_mc_num             --�K��v��iMC�j
         ,vis_a_num                  --�K��`����
         ,vis_b_num                  --�K��a����
         ,vis_c_num                  --�K��b����
         ,vis_d_num                  --�K��c����
         ,vis_e_num                  --�K��d����
         ,vis_f_num                  --�K��e����
         ,vis_g_num                  --�K��f����
         ,vis_h_num                  --�K��g����
         ,vis_i_num                  --�K���@����
         ,vis_j_num                  --�K��i����
         ,vis_k_num                  --�K��j����
         ,vis_l_num                  --�K��k����
         ,vis_m_num                  --�K��l����
         ,vis_n_num                  --�K��m����
         ,vis_o_num                  --�K��n����
         ,vis_p_num                  --�K��o����
         ,vis_q_num                  --�K��p����
         ,vis_r_num                  --�K��q����
         ,vis_s_num                  --�K��r����
         ,vis_t_num                  --�K��s����
         ,vis_u_num                  --�K��t����
         ,vis_v_num                  --�K��u����
         ,vis_w_num                  --�K��v����
         ,vis_x_num                  --�K��w����
         ,vis_y_num                  --�K��x����
         ,vis_z_num                  --�K��y����
        ) VALUES(
          cn_created_by                             --�쐬��
         ,cd_creation_date                          --�쐬��
         ,cn_last_updated_by                        --�ŏI�X�V��
         ,cd_last_update_date                       --�ŏI�X�V��
         ,cn_last_update_login                      --�ŏI�X�V���O�C��
         ,cn_request_id                             --�v��ID
         ,cn_program_application_id                 --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                             --�R���J�����g�E�v���O����ID
         ,cd_program_update_date                    --�v���O�����X�V��
         ,cv_sum_org_type_dept                      --�W�v�g�D���
         ,day_base_dt_rec.sum_org_code              --�W�v�g�D�b�c
         ,cv_null                                   --�O���[�v�e���_�b�c
         ,cv_month_date_div_day                     --�����敪
         ,day_base_dt_rec.sales_date                --�̔��N�����^�̔��N��
         ,NULL                                      --��ʁ^���̋@�^�l�b
         ,day_base_dt_rec.cust_new_num              --�ڋq�����i�V�K�j
         ,day_base_dt_rec.cust_vd_new_num           --�ڋq�����iVD�F�V�K�j
         ,day_base_dt_rec.cust_other_new_num        --�ڋq�����iVD�ȊO�F�V�K�j
         ,day_base_dt_rec.rslt_amt                  --�������
         ,day_base_dt_rec.rslt_new_amt              --������сi�V�K�j
         ,day_base_dt_rec.rslt_vd_new_amt           --������сiVD�F�V�K�j
         ,day_base_dt_rec.rslt_vd_amt               --������сiVD�j
         ,day_base_dt_rec.rslt_other_new_amt        --������сiVD�ȊO�F�V�K�j
         ,day_base_dt_rec.rslt_other_amt            --������сiVD�ȊO�j
         ,day_base_dt_rec.rslt_center_amt           --�������_�Q�������
         ,day_base_dt_rec.rslt_center_vd_amt        --�������_�Q������сiVD�j
         ,day_base_dt_rec.rslt_center_other_amt     --�������_�Q������сiVD�ȊO�j
         ,day_base_dt_rec.tgt_amt                   --����v��
         ,day_base_dt_rec.tgt_new_amt               --����v��i�V�K�j
         ,day_base_dt_rec.tgt_vd_new_amt            --����v��iVD�F�V�K�j
         ,day_base_dt_rec.tgt_vd_amt                --����v��iVD�j
         ,day_base_dt_rec.tgt_other_new_amt         --����v��iVD�ȊO�F�V�K�j
         ,day_base_dt_rec.tgt_other_amt             --����v��iVD�ȊO�j
         ,day_base_dt_rec.vis_num                   --�K�����
         ,day_base_dt_rec.vis_new_num               --�K����сi�V�K�j
         ,day_base_dt_rec.vis_vd_new_num            --�K����сiVD�F�V�K�j
         ,day_base_dt_rec.vis_vd_num                --�K����сiVD�j
         ,day_base_dt_rec.vis_other_new_num         --�K����сiVD�ȊO�F�V�K�j
         ,day_base_dt_rec.vis_other_num             --�K����сiVD�ȊO�j
         ,day_base_dt_rec.vis_mc_num                --�K����сiMC�j
         ,day_base_dt_rec.vis_sales_num             --�L������
         ,day_base_dt_rec.tgt_vis_num               --�K��v��
         ,day_base_dt_rec.tgt_vis_new_num           --�K��v��i�V�K�j
         ,day_base_dt_rec.tgt_vis_vd_new_num        --�K��v��iVD�F�V�K�j
         ,day_base_dt_rec.tgt_vis_vd_num            --�K��v��iVD�j
         ,day_base_dt_rec.tgt_vis_other_new_num     --�K��v��iVD�ȊO�F�V�K�j
         ,day_base_dt_rec.tgt_vis_other_num         --�K��v��iVD�ȊO�j
         ,day_base_dt_rec.tgt_vis_mc_num            --�K��v��iMC�j
         ,day_base_dt_rec.vis_a_num                 --�K��`����
         ,day_base_dt_rec.vis_b_num                 --�K��a����
         ,day_base_dt_rec.vis_c_num                 --�K��b����
         ,day_base_dt_rec.vis_d_num                 --�K��c����
         ,day_base_dt_rec.vis_e_num                 --�K��d����
         ,day_base_dt_rec.vis_f_num                 --�K��e����
         ,day_base_dt_rec.vis_g_num                 --�K��f����
         ,day_base_dt_rec.vis_h_num                 --�K��g����
         ,day_base_dt_rec.vis_i_num                 --�K���@����
         ,day_base_dt_rec.vis_j_num                 --�K��i����
         ,day_base_dt_rec.vis_k_num                 --�K��j����
         ,day_base_dt_rec.vis_l_num                 --�K��k����
         ,day_base_dt_rec.vis_m_num                 --�K��l����
         ,day_base_dt_rec.vis_n_num                 --�K��m����
         ,day_base_dt_rec.vis_o_num                 --�K��n����
         ,day_base_dt_rec.vis_p_num                 --�K��o����
         ,day_base_dt_rec.vis_q_num                 --�K��p����
         ,day_base_dt_rec.vis_r_num                 --�K��q����
         ,day_base_dt_rec.vis_s_num                 --�K��r����
         ,day_base_dt_rec.vis_t_num                 --�K��s����
         ,day_base_dt_rec.vis_u_num                 --�K��t����
         ,day_base_dt_rec.vis_v_num                 --�K��u����
         ,day_base_dt_rec.vis_w_num                 --�K��v����
         ,day_base_dt_rec.vis_x_num                 --�K��w����
         ,day_base_dt_rec.vis_y_num                 --�K��x����
         ,day_base_dt_rec.vis_z_num                 --�K��y����
        )
        ;
        -- �o�͌������Z
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_base_dt;
      -- *** DEBUG_LOG ***
      -- ���ʋ��_�^�ەʎ擾�o�^�����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_d_base  || CHR(10) ||
                   ''
      );
      -- �J�[�\���N���[�Y
      CLOSE day_base_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_day_base || CHR(10)   ||
                   ''
      );
        -- ���o�����i�[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- �o�͌����i�[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- ���o�A�o�͌��������O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_05               --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                   --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_base                    --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage              --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                        --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** �o�^������O�n���h�� ***
    WHEN insert_error_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_base_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_base_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_base_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_base_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_base_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_day_base_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_area_dt
   * Description      : ���ʒn��c�ƕ��^���ʎ擾�o�^ (A-9)
   ***********************************************************************************/
  PROCEDURE insert_day_area_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_area_dt';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_extrct_cnt        NUMBER;              -- ���o����
    ln_output_cnt        NUMBER;              -- �o�͌���
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ʒn��c�ƕ��^���ʃf�[�^�擾�p�J�[�\��
    CURSOR day_area_dt_cur
    IS
      SELECT
        xablv.base_code                  sum_org_code               --�W�v�g�D�b�c
       ,xsvsr.sales_date                 sales_date                 --�̔��N�����^�̔��N��
       ,SUM(xsvsr.cust_new_num         ) cust_new_num               --�ڋq�����i�V�K�j
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --�������
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --������сi�V�K�j
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --������сiVD�F�V�K�j
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --������сiVD�j
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --������сiVD�ȊO�j
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --�������_�Q�������
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --�������_�Q������сiVD�j
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --����v��
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --����v��i�V�K�j
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --����v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --����v��iVD�j
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --����v��iVD�ȊO�j
       ,SUM(xsvsr.vis_num              ) vis_num                    --�K�����
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --�K����сi�V�K�j
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --�K����сiVD�F�V�K�j
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --�K����сiVD�j
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --�K����сiVD�ȊO�j
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --�K����сiMC�j
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --�L������
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --�K��v��
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --�K��v��i�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --�K��v��iVD�j
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --�K��v��iVD�ȊO�j
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --�K��v��iMC�j
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --�K��`����
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --�K��a����
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --�K��b����
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --�K��c����
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --�K��d����
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --�K��e����
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --�K��f����
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --�K��g����
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --�K���@����
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --�K��i����
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --�K��j����
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --�K��k����
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --�K��l����
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --�K��m����
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --�K��n����
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --�K��o����
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --�K��p����
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --�K��q����
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --�K��r����
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --�K��s����
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --�K��t����
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --�K��u����
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --�K��v����
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --�K��w����
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --�K��x����
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --�K��y����
      FROM
        xxcso_aff_base_level_v xablv  -- AFF����K�w�}�X�^�r���[
       ,xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}���e�[�u��
      WHERE  xsvsr.sum_org_type = cv_sum_org_type_dept  -- �W�v�g�D���
        AND  xablv.child_base_code = xsvsr.sum_org_code  -- ���_�R�[�h�i�q�j
        AND  xsvsr.month_date_div = cv_month_date_div_day  -- �����敪
        AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                  AND TO_CHAR(LAST_DAY(gd_process_date), 'YYYYMMDD')
      GROUP BY  xablv.base_code        --���_�R�[�h
               ,xsvsr.sales_date       --�̔��N�����^�̔��N��
    ;
    -- *** ���[�J���E���R�[�h ***
    -- ���ʒn��c�ƕ��^���ʃf�[�^�擾�p���R�[�h
     day_area_dt_rec day_area_dt_cur%ROWTYPE;
    -- *** ���[�J����O ***
    insert_error_expt    EXCEPTION;    -- �o�^������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���o�A�o�͌���������
    ln_extrct_cnt := 0;              -- ���o����
    ln_output_cnt := 0;              -- �o�͌���
    -- ========================
    -- ���ʒn��c�ƕ��^���ʃf�[�^�擾
    -- ========================
    -- �J�[�\���I�[�v��
    OPEN day_area_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- �J�[�\���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_day_area || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- �K�┄��v��Ǘ��\�T�}���e�[�u���o�^���� 
      -- ======================
      <<loop_day_area_dt>>
      LOOP
        FETCH day_area_dt_cur INTO day_area_dt_rec;
        -- ���o�����擾
        ln_extrct_cnt := day_area_dt_cur%ROWCOUNT;
        EXIT WHEN day_area_dt_cur%NOTFOUND
        OR  day_area_dt_cur%ROWCOUNT = 0;
        -- �o�^����
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --�쐬��
         ,creation_date              --�쐬��
         ,last_updated_by            --�ŏI�X�V��
         ,last_update_date           --�ŏI�X�V��
         ,last_update_login          --�ŏI�X�V���O�C��
         ,request_id                 --�v��ID
         ,program_application_id     --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                 --�R���J�����g�E�v���O����ID
         ,program_update_date        --�v���O�����X�V��
         ,sum_org_type               --�W�v�g�D���
         ,sum_org_code               --�W�v�g�D�b�c
         ,group_base_code            --�O���[�v�e���_�b�c
         ,month_date_div             --�����敪
         ,sales_date                 --�̔��N�����^�̔��N��
         ,gvm_type                   --��ʁ^���̋@�^�l�b
         ,cust_new_num               --�ڋq�����i�V�K�j
         ,cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
         ,cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
         ,rslt_amt                   --�������
         ,rslt_new_amt               --������сi�V�K�j
         ,rslt_vd_new_amt            --������сiVD�F�V�K�j
         ,rslt_vd_amt                --������сiVD�j
         ,rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
         ,rslt_other_amt             --������сiVD�ȊO�j
         ,rslt_center_amt            --�������_�Q�������
         ,rslt_center_vd_amt         --�������_�Q������сiVD�j
         ,rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
         ,tgt_amt                    --����v��
         ,tgt_new_amt                --����v��i�V�K�j
         ,tgt_vd_new_amt             --����v��iVD�F�V�K�j
         ,tgt_vd_amt                 --����v��iVD�j
         ,tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
         ,tgt_other_amt              --����v��iVD�ȊO�j
         ,vis_num                    --�K�����
         ,vis_new_num                --�K����сi�V�K�j
         ,vis_vd_new_num             --�K����сiVD�F�V�K�j
         ,vis_vd_num                 --�K����сiVD�j
         ,vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
         ,vis_other_num              --�K����сiVD�ȊO�j
         ,vis_mc_num                 --�K����сiMC�j
         ,vis_sales_num              --�L������
         ,tgt_vis_num                --�K��v��
         ,tgt_vis_new_num            --�K��v��i�V�K�j
         ,tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
         ,tgt_vis_vd_num             --�K��v��iVD�j
         ,tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
         ,tgt_vis_other_num          --�K��v��iVD�ȊO�j
         ,tgt_vis_mc_num             --�K��v��iMC�j
         ,vis_a_num                  --�K��`����
         ,vis_b_num                  --�K��a����
         ,vis_c_num                  --�K��b����
         ,vis_d_num                  --�K��c����
         ,vis_e_num                  --�K��d����
         ,vis_f_num                  --�K��e����
         ,vis_g_num                  --�K��f����
         ,vis_h_num                  --�K��g����
         ,vis_i_num                  --�K���@����
         ,vis_j_num                  --�K��i����
         ,vis_k_num                  --�K��j����
         ,vis_l_num                  --�K��k����
         ,vis_m_num                  --�K��l����
         ,vis_n_num                  --�K��m����
         ,vis_o_num                  --�K��n����
         ,vis_p_num                  --�K��o����
         ,vis_q_num                  --�K��p����
         ,vis_r_num                  --�K��q����
         ,vis_s_num                  --�K��r����
         ,vis_t_num                  --�K��s����
         ,vis_u_num                  --�K��t����
         ,vis_v_num                  --�K��u����
         ,vis_w_num                  --�K��v����
         ,vis_x_num                  --�K��w����
         ,vis_y_num                  --�K��x����
         ,vis_z_num                  --�K��y����
        ) VALUES(
          cn_created_by                             --�쐬��
         ,cd_creation_date                          --�쐬��
         ,cn_last_updated_by                        --�ŏI�X�V��
         ,cd_last_update_date                       --�ŏI�X�V��
         ,cn_last_update_login                      --�ŏI�X�V���O�C��
         ,cn_request_id                             --�v��ID
         ,cn_program_application_id                 --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                             --�R���J�����g�E�v���O����ID
         ,cd_program_update_date                    --�v���O�����X�V��
         ,cv_sum_org_type_area                      --�W�v�g�D���
         ,day_area_dt_rec.sum_org_code              --�W�v�g�D�b�c
         ,cv_null                                   --�O���[�v�e���_�b�c
         ,cv_month_date_div_day                     --�����敪
         ,day_area_dt_rec.sales_date                --�̔��N�����^�̔��N��
         ,NULL                                      --��ʁ^���̋@�^�l�b
         ,day_area_dt_rec.cust_new_num              --�ڋq�����i�V�K�j
         ,day_area_dt_rec.cust_vd_new_num           --�ڋq�����iVD�F�V�K�j
         ,day_area_dt_rec.cust_other_new_num        --�ڋq�����iVD�ȊO�F�V�K�j
         ,day_area_dt_rec.rslt_amt                  --�������
         ,day_area_dt_rec.rslt_new_amt              --������сi�V�K�j
         ,day_area_dt_rec.rslt_vd_new_amt           --������сiVD�F�V�K�j
         ,day_area_dt_rec.rslt_vd_amt               --������сiVD�j
         ,day_area_dt_rec.rslt_other_new_amt        --������сiVD�ȊO�F�V�K�j
         ,day_area_dt_rec.rslt_other_amt            --������сiVD�ȊO�j
         ,day_area_dt_rec.rslt_center_amt           --�������_�Q�������
         ,day_area_dt_rec.rslt_center_vd_amt        --�������_�Q������сiVD�j
         ,day_area_dt_rec.rslt_center_other_amt     --�������_�Q������сiVD�ȊO�j
         ,day_area_dt_rec.tgt_amt                   --����v��
         ,day_area_dt_rec.tgt_new_amt               --����v��i�V�K�j
         ,day_area_dt_rec.tgt_vd_new_amt            --����v��iVD�F�V�K�j
         ,day_area_dt_rec.tgt_vd_amt                --����v��iVD�j
         ,day_area_dt_rec.tgt_other_new_amt         --����v��iVD�ȊO�F�V�K�j
         ,day_area_dt_rec.tgt_other_amt             --����v��iVD�ȊO�j
         ,day_area_dt_rec.vis_num                   --�K�����
         ,day_area_dt_rec.vis_new_num               --�K����сi�V�K�j
         ,day_area_dt_rec.vis_vd_new_num            --�K����сiVD�F�V�K�j
         ,day_area_dt_rec.vis_vd_num                --�K����сiVD�j
         ,day_area_dt_rec.vis_other_new_num         --�K����сiVD�ȊO�F�V�K�j
         ,day_area_dt_rec.vis_other_num             --�K����сiVD�ȊO�j
         ,day_area_dt_rec.vis_mc_num                --�K����сiMC�j
         ,day_area_dt_rec.vis_sales_num             --�L������
         ,day_area_dt_rec.tgt_vis_num               --�K��v��
         ,day_area_dt_rec.tgt_vis_new_num           --�K��v��i�V�K�j
         ,day_area_dt_rec.tgt_vis_vd_new_num        --�K��v��iVD�F�V�K�j
         ,day_area_dt_rec.tgt_vis_vd_num            --�K��v��iVD�j
         ,day_area_dt_rec.tgt_vis_other_new_num     --�K��v��iVD�ȊO�F�V�K�j
         ,day_area_dt_rec.tgt_vis_other_num         --�K��v��iVD�ȊO�j
         ,day_area_dt_rec.tgt_vis_mc_num            --�K��v��iMC�j
         ,day_area_dt_rec.vis_a_num                 --�K��`����
         ,day_area_dt_rec.vis_b_num                 --�K��a����
         ,day_area_dt_rec.vis_c_num                 --�K��b����
         ,day_area_dt_rec.vis_d_num                 --�K��c����
         ,day_area_dt_rec.vis_e_num                 --�K��d����
         ,day_area_dt_rec.vis_f_num                 --�K��e����
         ,day_area_dt_rec.vis_g_num                 --�K��f����
         ,day_area_dt_rec.vis_h_num                 --�K��g����
         ,day_area_dt_rec.vis_i_num                 --�K���@����
         ,day_area_dt_rec.vis_j_num                 --�K��i����
         ,day_area_dt_rec.vis_k_num                 --�K��j����
         ,day_area_dt_rec.vis_l_num                 --�K��k����
         ,day_area_dt_rec.vis_m_num                 --�K��l����
         ,day_area_dt_rec.vis_n_num                 --�K��m����
         ,day_area_dt_rec.vis_o_num                 --�K��n����
         ,day_area_dt_rec.vis_p_num                 --�K��o����
         ,day_area_dt_rec.vis_q_num                 --�K��p����
         ,day_area_dt_rec.vis_r_num                 --�K��q����
         ,day_area_dt_rec.vis_s_num                 --�K��r����
         ,day_area_dt_rec.vis_t_num                 --�K��s����
         ,day_area_dt_rec.vis_u_num                 --�K��t����
         ,day_area_dt_rec.vis_v_num                 --�K��u����
         ,day_area_dt_rec.vis_w_num                 --�K��v����
         ,day_area_dt_rec.vis_x_num                 --�K��w����
         ,day_area_dt_rec.vis_y_num                 --�K��x����
         ,day_area_dt_rec.vis_z_num                 --�K��y����
        )
        ;
        -- �o�͌������Z
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_area_dt;
      -- *** DEBUG_LOG ***
      -- ���ʒn��c�ƕ��^���ʎ擾�o�^�����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_d_area  || CHR(10) ||
                   ''
      );
      -- �J�[�\���N���[�Y
      CLOSE day_area_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_day_area || CHR(10)   ||
                   ''
      );
        -- ���o�����i�[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- �o�͌����i�[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- ���o�A�o�͌��������O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_05               --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                   --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_area                    --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage              --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                        --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** �o�^������O�n���h�� ***
    WHEN insert_error_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_area_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_area_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_area_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_area_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (day_area_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE day_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_day_area_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_acct_dt
   * Description      : ���ʌڋq�ʎ擾�o�^ (A-10)
   ***********************************************************************************/
  PROCEDURE insert_mon_acct_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_acct_dt';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_extrct_cnt        NUMBER;              -- ���o����
    ln_output_cnt        NUMBER;              -- �o�͌���
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ʌڋq�ʃf�[�^�擾�p�J�[�\��
    CURSOR mon_acct_dt_cur
    IS
      SELECT
        xsvsr.sum_org_code               sum_org_code               --�W�v�g�D�b�c
/* 20090519_Ogawa_T1_1024 START*/
       ,xsvsr.group_base_code            group_base_code            --�O���[�v�e���_�b�c
/* 20090519_Ogawa_T1_1024 END*/
       ,SUBSTRB(xsvsr.sales_date, 1, 6)  sales_date                 --�̔��N�����^�̔��N��
       ,xsvsr.gvm_type                   gvm_type                   --��ʁ^���̋@�^�l�b
       ,MAX(xsvsr.cust_new_num         ) cust_new_num               --�ڋq�����i�V�K�j
       ,MAX(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
       ,MAX(xsvsr.cust_other_new_num   ) cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --�������
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --������сi�V�K�j
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --������сiVD�F�V�K�j
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --������сiVD�j
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --������сiVD�ȊO�j
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --�������_�Q�������
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --�������_�Q������сiVD�j
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --����v��
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --����v��i�V�K�j
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --����v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --����v��iVD�j
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --����v��iVD�ȊO�j
       ,SUM(xsvsr.vis_num              ) vis_num                    --�K�����
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --�K����сi�V�K�j
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --�K����сiVD�F�V�K�j
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --�K����сiVD�j
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --�K����сiVD�ȊO�j
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --�K����сiMC�j
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --�L������
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --�K��v��
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --�K��v��i�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --�K��v��iVD�j
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --�K��v��iVD�ȊO�j
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --�K��v��iMC�j
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --�K��`����
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --�K��a����
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --�K��b����
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --�K��c����
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --�K��d����
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --�K��e����
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --�K��f����
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --�K��g����
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --�K���@����
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --�K��i����
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --�K��j����
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --�K��k����
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --�K��l����
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --�K��m����
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --�K��n����
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --�K��o����
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --�K��p����
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --�K��q����
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --�K��r����
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --�K��s����
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --�K��t����
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --�K��u����
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --�K��v����
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --�K��w����
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --�K��x����
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --�K��y����
      FROM
/* 20090519_Ogawa_T1_1024 START*/
--      xxcso_cust_accounts_v xcav  -- �ڋq�}�X�^�r���[
--     ,xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}���e�[�u��
        xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}���e�[�u��
/* 20090519_Ogawa_T1_1024 END*/
      WHERE  xsvsr.sum_org_type = cv_sum_org_type_accnt  -- �W�v�g�D���
/* 20090519_Ogawa_T1_1024 START*/
--      AND  xcav.account_number = xsvsr.sum_org_code  -- �ڋq�R�[�h
/* 20090519_Ogawa_T1_1024 END*/
        AND  xsvsr.month_date_div = cv_month_date_div_day  -- �����敪
        AND  SUBSTRB(xsvsr.sales_date, 1, 6) IN (
                                                  gv_ym_lst_1
                                                 ,gv_ym_lst_2
                                                 ,gv_ym_lst_3
                                                 ,gv_ym_lst_4
                                                 ,gv_ym_lst_5
                                                 ,gv_ym_lst_6
                                                )  -- �̔��N����
/* 20090519_Ogawa_T1_1024 START*/
--      AND  ((
--                  (
--                   xcav.customer_class_code IS NULL -- �ڋq�敪
--                  )
--             AND  (
--                   xcav.customer_status IN (
--                                             cv_customer_status_10
--                                            ,cv_customer_status_20
--                                           )  -- �ڋq�X�e�[�^�X
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_10 -- �ڋq�敪
--                  )
--             AND  (
--                   xcav.customer_status IN (
--                                             cv_customer_status_25
--                                            ,cv_customer_status_30
--                                            ,cv_customer_status_40
--                                            ,cv_customer_status_50
--                                           )  -- �ڋq�X�e�[�^�X
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_12 -- �ڋq�敪
--                  )
--             AND  (
--                   xcav.customer_status IN (
--                                             cv_customer_status_30
--                                            ,cv_customer_status_40
--                                           )  -- �ڋq�X�e�[�^�X
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_15 -- �ڋq�敪
--                  )
--             AND  (
--                   xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_16 -- �ڋq�敪
--                  )
--             AND  (
--                   xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_17 -- �ڋq�敪
--                  )
--             AND  (
--                   xcav.customer_status = cv_customer_status_99 -- �ڋq�X�e�[�^�X
--                  )
--           ))
/* 20090519_Ogawa_T1_1024 END*/
      GROUP BY  sum_org_code  --�ڋq�R�[�h
/* 20090519_Ogawa_T1_1024 START*/
               ,xsvsr.group_base_code  --�O���[�v�e���_�b�c
/* 20090519_Ogawa_T1_1024 END*/
               ,SUBSTRB(xsvsr.sales_date, 1, 6)       --�̔��N����
               ,gvm_type         --��ʁ^���̋@�^�l�b
    ;
    -- *** ���[�J���E���R�[�h ***
    -- ���ʌڋq�ʃf�[�^�擾�p���R�[�h
     mon_acct_dt_rec mon_acct_dt_cur%ROWTYPE;
    -- *** ���[�J����O ***
    insert_error_expt    EXCEPTION;    -- �o�^������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���o�A�o�͌���������
    ln_extrct_cnt := 0;              -- ���o����
    ln_output_cnt := 0;              -- �o�͌���
    -- ========================
    -- ���ʌڋq�ʃf�[�^�擾
    -- ========================
    -- �J�[�\���I�[�v��
    OPEN mon_acct_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- �J�[�\���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_acct || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- �K�┄��v��Ǘ��\�T�}���e�[�u���o�^���� 
      -- ======================
      <<loop_mon_acct_dt>>
      LOOP
        FETCH mon_acct_dt_cur INTO mon_acct_dt_rec;
        -- ���o�����擾
        ln_extrct_cnt := mon_acct_dt_cur%ROWCOUNT;
        EXIT WHEN mon_acct_dt_cur%NOTFOUND
        OR  mon_acct_dt_cur%ROWCOUNT = 0;
        -- �o�^����
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --�쐬��
         ,creation_date              --�쐬��
         ,last_updated_by            --�ŏI�X�V��
         ,last_update_date           --�ŏI�X�V��
         ,last_update_login          --�ŏI�X�V���O�C��
         ,request_id                 --�v��ID
         ,program_application_id     --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                 --�R���J�����g�E�v���O����ID
         ,program_update_date        --�v���O�����X�V��
         ,sum_org_type               --�W�v�g�D���
         ,sum_org_code               --�W�v�g�D�b�c
         ,group_base_code            --�O���[�v�e���_�b�c
         ,month_date_div             --�����敪
         ,sales_date                 --�̔��N�����^�̔��N��
         ,gvm_type                   --��ʁ^���̋@�^�l�b
         ,cust_new_num               --�ڋq�����i�V�K�j
         ,cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
         ,cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
         ,rslt_amt                   --�������
         ,rslt_new_amt               --������сi�V�K�j
         ,rslt_vd_new_amt            --������сiVD�F�V�K�j
         ,rslt_vd_amt                --������сiVD�j
         ,rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
         ,rslt_other_amt             --������сiVD�ȊO�j
         ,rslt_center_amt            --�������_�Q�������
         ,rslt_center_vd_amt         --�������_�Q������сiVD�j
         ,rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
         ,tgt_amt                    --����v��
         ,tgt_new_amt                --����v��i�V�K�j
         ,tgt_vd_new_amt             --����v��iVD�F�V�K�j
         ,tgt_vd_amt                 --����v��iVD�j
         ,tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
         ,tgt_other_amt              --����v��iVD�ȊO�j
         ,vis_num                    --�K�����
         ,vis_new_num                --�K����сi�V�K�j
         ,vis_vd_new_num             --�K����сiVD�F�V�K�j
         ,vis_vd_num                 --�K����сiVD�j
         ,vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
         ,vis_other_num              --�K����сiVD�ȊO�j
         ,vis_mc_num                 --�K����сiMC�j
         ,vis_sales_num              --�L������
         ,tgt_vis_num                --�K��v��
         ,tgt_vis_new_num            --�K��v��i�V�K�j
         ,tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
         ,tgt_vis_vd_num             --�K��v��iVD�j
         ,tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
         ,tgt_vis_other_num          --�K��v��iVD�ȊO�j
         ,tgt_vis_mc_num             --�K��v��iMC�j
         ,vis_a_num                  --�K��`����
         ,vis_b_num                  --�K��a����
         ,vis_c_num                  --�K��b����
         ,vis_d_num                  --�K��c����
         ,vis_e_num                  --�K��d����
         ,vis_f_num                  --�K��e����
         ,vis_g_num                  --�K��f����
         ,vis_h_num                  --�K��g����
         ,vis_i_num                  --�K���@����
         ,vis_j_num                  --�K��i����
         ,vis_k_num                  --�K��j����
         ,vis_l_num                  --�K��k����
         ,vis_m_num                  --�K��l����
         ,vis_n_num                  --�K��m����
         ,vis_o_num                  --�K��n����
         ,vis_p_num                  --�K��o����
         ,vis_q_num                  --�K��p����
         ,vis_r_num                  --�K��q����
         ,vis_s_num                  --�K��r����
         ,vis_t_num                  --�K��s����
         ,vis_u_num                  --�K��t����
         ,vis_v_num                  --�K��u����
         ,vis_w_num                  --�K��v����
         ,vis_x_num                  --�K��w����
         ,vis_y_num                  --�K��x����
         ,vis_z_num                  --�K��y����
        ) VALUES(
          cn_created_by                              --�쐬��
         ,cd_creation_date                           --�쐬��
         ,cn_last_updated_by                         --�ŏI�X�V��
         ,cd_last_update_date                        --�ŏI�X�V��
         ,cn_last_update_login                       --�ŏI�X�V���O�C��
         ,cn_request_id                              --�v��ID
         ,cn_program_application_id                  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                              --�R���J�����g�E�v���O����ID
         ,cd_program_update_date                     --�v���O�����X�V��
         ,cv_sum_org_type_accnt                      --�W�v�g�D���
         ,mon_acct_dt_rec.sum_org_code               --�W�v�g�D�b�c
/* 20090519_Ogawa_T1_1024 START*/
--       ,cv_null                                    --�O���[�v�e���_�b�c
         ,mon_acct_dt_rec.group_base_code
/* 20090519_Ogawa_T1_1024 END*/
         ,cv_month_date_div_mon                      --�����敪
         ,mon_acct_dt_rec.sales_date                 --�̔��N�����^�̔��N��
         ,mon_acct_dt_rec.gvm_type                   --��ʁ^���̋@�^�l�b
         ,mon_acct_dt_rec.cust_new_num               --�ڋq�����i�V�K�j
         ,mon_acct_dt_rec.cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
         ,mon_acct_dt_rec.cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
         ,mon_acct_dt_rec.rslt_amt                   --�������
         ,mon_acct_dt_rec.rslt_new_amt               --������сi�V�K�j
         ,mon_acct_dt_rec.rslt_vd_new_amt            --������сiVD�F�V�K�j
         ,mon_acct_dt_rec.rslt_vd_amt                --������сiVD�j
         ,mon_acct_dt_rec.rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
         ,mon_acct_dt_rec.rslt_other_amt             --������сiVD�ȊO�j
         ,mon_acct_dt_rec.rslt_center_amt            --�������_�Q�������
         ,mon_acct_dt_rec.rslt_center_vd_amt         --�������_�Q������сiVD�j
         ,mon_acct_dt_rec.rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
         ,mon_acct_dt_rec.tgt_amt                    --����v��
         ,mon_acct_dt_rec.tgt_new_amt                --����v��i�V�K�j
         ,mon_acct_dt_rec.tgt_vd_new_amt             --����v��iVD�F�V�K�j
         ,mon_acct_dt_rec.tgt_vd_amt                 --����v��iVD�j
         ,mon_acct_dt_rec.tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
         ,mon_acct_dt_rec.tgt_other_amt              --����v��iVD�ȊO�j
         ,mon_acct_dt_rec.vis_num                    --�K�����
         ,mon_acct_dt_rec.vis_new_num                --�K����сi�V�K�j
         ,mon_acct_dt_rec.vis_vd_new_num             --�K����сiVD�F�V�K�j
         ,mon_acct_dt_rec.vis_vd_num                 --�K����сiVD�j
         ,mon_acct_dt_rec.vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
         ,mon_acct_dt_rec.vis_other_num              --�K����сiVD�ȊO�j
         ,mon_acct_dt_rec.vis_mc_num                 --�K����сiMC�j
         ,mon_acct_dt_rec.vis_sales_num              --�L������
         ,mon_acct_dt_rec.tgt_vis_num                --�K��v��
         ,mon_acct_dt_rec.tgt_vis_new_num            --�K��v��i�V�K�j
         ,mon_acct_dt_rec.tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
         ,mon_acct_dt_rec.tgt_vis_vd_num             --�K��v��iVD�j
         ,mon_acct_dt_rec.tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
         ,mon_acct_dt_rec.tgt_vis_other_num          --�K��v��iVD�ȊO�j
         ,mon_acct_dt_rec.tgt_vis_mc_num             --�K��v��iMC�j
         ,mon_acct_dt_rec.vis_a_num                  --�K��`����
         ,mon_acct_dt_rec.vis_b_num                  --�K��a����
         ,mon_acct_dt_rec.vis_c_num                  --�K��b����
         ,mon_acct_dt_rec.vis_d_num                  --�K��c����
         ,mon_acct_dt_rec.vis_e_num                  --�K��d����
         ,mon_acct_dt_rec.vis_f_num                  --�K��e����
         ,mon_acct_dt_rec.vis_g_num                  --�K��f����
         ,mon_acct_dt_rec.vis_h_num                  --�K��g����
         ,mon_acct_dt_rec.vis_i_num                  --�K���@����
         ,mon_acct_dt_rec.vis_j_num                  --�K��i����
         ,mon_acct_dt_rec.vis_k_num                  --�K��j����
         ,mon_acct_dt_rec.vis_l_num                  --�K��k����
         ,mon_acct_dt_rec.vis_m_num                  --�K��l����
         ,mon_acct_dt_rec.vis_n_num                  --�K��m����
         ,mon_acct_dt_rec.vis_o_num                  --�K��n����
         ,mon_acct_dt_rec.vis_p_num                  --�K��o����
         ,mon_acct_dt_rec.vis_q_num                  --�K��p����
         ,mon_acct_dt_rec.vis_r_num                  --�K��q����
         ,mon_acct_dt_rec.vis_s_num                  --�K��r����
         ,mon_acct_dt_rec.vis_t_num                  --�K��s����
         ,mon_acct_dt_rec.vis_u_num                  --�K��t����
         ,mon_acct_dt_rec.vis_v_num                  --�K��u����
         ,mon_acct_dt_rec.vis_w_num                  --�K��v����
         ,mon_acct_dt_rec.vis_x_num                  --�K��w����
         ,mon_acct_dt_rec.vis_y_num                  --�K��x����
         ,mon_acct_dt_rec.vis_z_num                  --�K��y����
        )
        ;
        -- �o�͌������Z
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_mon_acct_dt;
      -- *** DEBUG_LOG ***
      -- ���ʌڋq�ʎ擾�o�^�����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_acct  || CHR(10) ||
                   ''
      );
      -- �J�[�\���N���[�Y
      CLOSE mon_acct_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_acct || CHR(10)   ||
                   ''
      );
        -- ���o�����i�[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- �o�͌����i�[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- ���o�A�o�͌��������O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_05               --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                   --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_acct                    --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage              --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                        --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** �o�^������O�n���h�� ***
    WHEN insert_error_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_acct_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_acct_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_acct_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_acct_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_acct_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_acct_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_acct_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_acct_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_mon_acct_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_emp_dt
   * Description      : ���ʉc�ƈ��ʎ擾�o�^ (A-11)
   ***********************************************************************************/
  PROCEDURE insert_mon_emp_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_emp_dt';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_extrct_cnt        NUMBER;              -- ���o����
    ln_output_cnt        NUMBER;              -- �o�͌���
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ʉc�ƈ��ʃf�[�^�擾�p�J�[�\��
    CURSOR mon_emp_dt_cur
    IS
      SELECT
        xcrv2.employee_number            sum_org_code               --�W�v�g�D�b�c
       ,xsvsr.sales_date                 sales_date                 --�̔��N�����^�̔��N��
       ,SUM(xsvsr.cust_new_num         ) cust_new_num               --�ڋq�����i�V�K�j
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --�������
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --������сi�V�K�j
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --������сiVD�F�V�K�j
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --������сiVD�j
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --������сiVD�ȊO�j
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --�������_�Q�������
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --�������_�Q������сiVD�j
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
       ,MAX(
            DECODE(xdmp.sales_plan_rel_div
                   ,'1', xspmp.tgt_sales_prsn_total_amt
                   ,'2', xspmp.bsc_sls_prsn_total_amt
                  )
           )                             tgt_sales_prsn_total_amt   --���ʔ���\�Z
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --����v��
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --����v��i�V�K�j
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --����v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --����v��iVD�j
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --����v��iVD�ȊO�j
       ,SUM(xsvsr.vis_num              ) vis_num                    --�K�����
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --�K����сi�V�K�j
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --�K����сiVD�F�V�K�j
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --�K����сiVD�j
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --�K����сiVD�ȊO�j
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --�K����сiMC�j
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --�L������
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --�K��v��
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --�K��v��i�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --�K��v��iVD�j
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --�K��v��iVD�ȊO�j
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --�K��v��iMC�j
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --�K��`����
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --�K��a����
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --�K��b����
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --�K��c����
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --�K��d����
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --�K��e����
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --�K��f����
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --�K��g����
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --�K���@����
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --�K��i����
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --�K��j����
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --�K��k����
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --�K��l����
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --�K��m����
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --�K��n����
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --�K��o����
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --�K��p����
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --�K��q����
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --�K��r����
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --�K��s����
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --�K��t����
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --�K��u����
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --�K��v����
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --�K��w����
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --�K��x����
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --�K��y����
      FROM
        xxcso_cust_resources_v2 xcrv2  -- �ڋq�S���c�ƈ��i�ŐV�j�r���[
       ,xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}���e�[�u��
       ,xxcso_sls_prsn_mnthly_plns xspmp  -- �c�ƈ��ʌ��ʌv��e�[�u��
       ,xxcso_resources_v2 xrv2  -- ���\�[�X�}�X�^�i�ŐV�j�r���[
       ,xxcso_dept_monthly_plans xdmp  -- ���_�ʌ��ʌv��e�[�u��
      WHERE  xcrv2.account_number = xsvsr.sum_org_code  -- �ڋq�R�[�h
        AND  xsvsr.sum_org_type = cv_sum_org_type_accnt  -- �W�v�g�D���
        AND  xsvsr.month_date_div = cv_month_date_div_mon  -- �����敪
        AND  xsvsr.sales_date IN (
                                   gv_ym_lst_1
                                  ,gv_ym_lst_2
                                  ,gv_ym_lst_3
                                  ,gv_ym_lst_4
                                  ,gv_ym_lst_5
                                  ,gv_ym_lst_6
                                 )  -- �̔��N����
        AND  xcrv2.employee_number =  xspmp.employee_number --�]�ƈ��ԍ��i�c�ƈ��ʌ��ʌv��TBL�j
        AND  xcrv2.employee_number =  xrv2.employee_number --�]�ƈ��ԍ��i���\�[�X�}�X�^�j
        AND  (
              CASE WHEN (
                         TO_DATE(xrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                        )
                   THEN  xrv2.work_base_code_new
                   ELSE  xrv2.work_base_code_old
              END
             ) = xspmp.base_code  -- �Ζ��n���_�R�[�h���ߓ����f
        AND  xsvsr.sales_date = xspmp.year_month  -- �̔��N����
        AND  xdmp.base_code = xspmp.base_code  -- ���_CD
        AND  xdmp.year_month = xspmp.year_month  -- �N��
      GROUP BY  xcrv2.employee_number    --�]�ƈ��ԍ�
               ,xsvsr.sales_date         --�̔��N�����^�̔��N��
    ;
    -- *** ���[�J���E���R�[�h ***
    -- ���ʉc�ƈ��ʃf�[�^�擾�p���R�[�h
     mon_emp_dt_rec mon_emp_dt_cur%ROWTYPE;
    -- *** ���[�J����O ***
    insert_error_expt    EXCEPTION;    -- �o�^������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���o�A�o�͌���������
    ln_extrct_cnt := 0;              -- ���o����
    ln_output_cnt := 0;              -- �o�͌���
    -- ========================
    -- ���ʉc�ƈ��ʃf�[�^�擾
    -- ========================
    -- �J�[�\���I�[�v��
    OPEN mon_emp_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- �J�[�\���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_emp || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- �K�┄��v��Ǘ��\�T�}���e�[�u���o�^���� 
      -- ======================
      <<loop_mon_emp_dt>>
      LOOP
        FETCH mon_emp_dt_cur INTO mon_emp_dt_rec;
        -- ���o�����擾
        ln_extrct_cnt := mon_emp_dt_cur%ROWCOUNT;
        EXIT WHEN mon_emp_dt_cur%NOTFOUND
        OR  mon_emp_dt_cur%ROWCOUNT = 0;
        -- �o�^����
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --�쐬��
         ,creation_date              --�쐬��
         ,last_updated_by            --�ŏI�X�V��
         ,last_update_date           --�ŏI�X�V��
         ,last_update_login          --�ŏI�X�V���O�C��
         ,request_id                 --�v��ID
         ,program_application_id     --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                 --�R���J�����g�E�v���O����ID
         ,program_update_date        --�v���O�����X�V��
         ,sum_org_type               --�W�v�g�D���
         ,sum_org_code               --�W�v�g�D�b�c
         ,group_base_code            --�O���[�v�e���_�b�c
         ,month_date_div             --�����敪
         ,sales_date                 --�̔��N�����^�̔��N��
         ,gvm_type                   --��ʁ^���̋@�^�l�b
         ,cust_new_num               --�ڋq�����i�V�K�j
         ,cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
         ,cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
         ,rslt_amt                   --�������
         ,rslt_new_amt               --������сi�V�K�j
         ,rslt_vd_new_amt            --������сiVD�F�V�K�j
         ,rslt_vd_amt                --������сiVD�j
         ,rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
         ,rslt_other_amt             --������сiVD�ȊO�j
         ,rslt_center_amt            --�������_�Q�������
         ,rslt_center_vd_amt         --�������_�Q������сiVD�j
         ,rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
         ,tgt_sales_prsn_total_amt   --���ʔ���\�Z
         ,tgt_amt                    --����v��
         ,tgt_new_amt                --����v��i�V�K�j
         ,tgt_vd_new_amt             --����v��iVD�F�V�K�j
         ,tgt_vd_amt                 --����v��iVD�j
         ,tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
         ,tgt_other_amt              --����v��iVD�ȊO�j
         ,vis_num                    --�K�����
         ,vis_new_num                --�K����сi�V�K�j
         ,vis_vd_new_num             --�K����сiVD�F�V�K�j
         ,vis_vd_num                 --�K����сiVD�j
         ,vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
         ,vis_other_num              --�K����сiVD�ȊO�j
         ,vis_mc_num                 --�K����сiMC�j
         ,vis_sales_num              --�L������
         ,tgt_vis_num                --�K��v��
         ,tgt_vis_new_num            --�K��v��i�V�K�j
         ,tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
         ,tgt_vis_vd_num             --�K��v��iVD�j
         ,tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
         ,tgt_vis_other_num          --�K��v��iVD�ȊO�j
         ,tgt_vis_mc_num             --�K��v��iMC�j
         ,vis_a_num                  --�K��`����
         ,vis_b_num                  --�K��a����
         ,vis_c_num                  --�K��b����
         ,vis_d_num                  --�K��c����
         ,vis_e_num                  --�K��d����
         ,vis_f_num                  --�K��e����
         ,vis_g_num                  --�K��f����
         ,vis_h_num                  --�K��g����
         ,vis_i_num                  --�K���@����
         ,vis_j_num                  --�K��i����
         ,vis_k_num                  --�K��j����
         ,vis_l_num                  --�K��k����
         ,vis_m_num                  --�K��l����
         ,vis_n_num                  --�K��m����
         ,vis_o_num                  --�K��n����
         ,vis_p_num                  --�K��o����
         ,vis_q_num                  --�K��p����
         ,vis_r_num                  --�K��q����
         ,vis_s_num                  --�K��r����
         ,vis_t_num                  --�K��s����
         ,vis_u_num                  --�K��t����
         ,vis_v_num                  --�K��u����
         ,vis_w_num                  --�K��v����
         ,vis_x_num                  --�K��w����
         ,vis_y_num                  --�K��x����
         ,vis_z_num                  --�K��y����
        ) VALUES(
          cn_created_by                             --�쐬��
         ,cd_creation_date                          --�쐬��
         ,cn_last_updated_by                        --�ŏI�X�V��
         ,cd_last_update_date                       --�ŏI�X�V��
         ,cn_last_update_login                      --�ŏI�X�V���O�C��
         ,cn_request_id                             --�v��ID
         ,cn_program_application_id                 --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                             --�R���J�����g�E�v���O����ID
         ,cd_program_update_date                    --�v���O�����X�V��
         ,cv_sum_org_type_emp                       --�W�v�g�D���
         ,mon_emp_dt_rec.sum_org_code               --�W�v�g�D�b�c
         ,cv_null                                   --�O���[�v�e���_�b�c
         ,cv_month_date_div_mon                     --�����敪
         ,mon_emp_dt_rec.sales_date                 --�̔��N�����^�̔��N��
         ,NULL                                      --��ʁ^���̋@�^�l�b
         ,mon_emp_dt_rec.cust_new_num               --�ڋq�����i�V�K�j
         ,mon_emp_dt_rec.cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
         ,mon_emp_dt_rec.cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
         ,mon_emp_dt_rec.rslt_amt                   --�������
         ,mon_emp_dt_rec.rslt_new_amt               --������сi�V�K�j
         ,mon_emp_dt_rec.rslt_vd_new_amt            --������сiVD�F�V�K�j
         ,mon_emp_dt_rec.rslt_vd_amt                --������сiVD�j
         ,mon_emp_dt_rec.rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
         ,mon_emp_dt_rec.rslt_other_amt             --������сiVD�ȊO�j
         ,mon_emp_dt_rec.rslt_center_amt            --�������_�Q�������
         ,mon_emp_dt_rec.rslt_center_vd_amt         --�������_�Q������сiVD�j
         ,mon_emp_dt_rec.rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
         ,mon_emp_dt_rec.tgt_sales_prsn_total_amt   --���ʔ���\�Z
         ,mon_emp_dt_rec.tgt_amt                    --����v��
         ,mon_emp_dt_rec.tgt_new_amt                --����v��i�V�K�j
         ,mon_emp_dt_rec.tgt_vd_new_amt             --����v��iVD�F�V�K�j
         ,mon_emp_dt_rec.tgt_vd_amt                 --����v��iVD�j
         ,mon_emp_dt_rec.tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
         ,mon_emp_dt_rec.tgt_other_amt              --����v��iVD�ȊO�j
         ,mon_emp_dt_rec.vis_num                    --�K�����
         ,mon_emp_dt_rec.vis_new_num                --�K����сi�V�K�j
         ,mon_emp_dt_rec.vis_vd_new_num             --�K����сiVD�F�V�K�j
         ,mon_emp_dt_rec.vis_vd_num                 --�K����сiVD�j
         ,mon_emp_dt_rec.vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
         ,mon_emp_dt_rec.vis_other_num              --�K����сiVD�ȊO�j
         ,mon_emp_dt_rec.vis_mc_num                 --�K����сiMC�j
         ,mon_emp_dt_rec.vis_sales_num              --�L������
         ,mon_emp_dt_rec.tgt_vis_num                --�K��v��
         ,mon_emp_dt_rec.tgt_vis_new_num            --�K��v��i�V�K�j
         ,mon_emp_dt_rec.tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
         ,mon_emp_dt_rec.tgt_vis_vd_num             --�K��v��iVD�j
         ,mon_emp_dt_rec.tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
         ,mon_emp_dt_rec.tgt_vis_other_num          --�K��v��iVD�ȊO�j
         ,mon_emp_dt_rec.tgt_vis_mc_num             --�K��v��iMC�j
         ,mon_emp_dt_rec.vis_a_num                  --�K��`����
         ,mon_emp_dt_rec.vis_b_num                  --�K��a����
         ,mon_emp_dt_rec.vis_c_num                  --�K��b����
         ,mon_emp_dt_rec.vis_d_num                  --�K��c����
         ,mon_emp_dt_rec.vis_e_num                  --�K��d����
         ,mon_emp_dt_rec.vis_f_num                  --�K��e����
         ,mon_emp_dt_rec.vis_g_num                  --�K��f����
         ,mon_emp_dt_rec.vis_h_num                  --�K��g����
         ,mon_emp_dt_rec.vis_i_num                  --�K���@����
         ,mon_emp_dt_rec.vis_j_num                  --�K��i����
         ,mon_emp_dt_rec.vis_k_num                  --�K��j����
         ,mon_emp_dt_rec.vis_l_num                  --�K��k����
         ,mon_emp_dt_rec.vis_m_num                  --�K��l����
         ,mon_emp_dt_rec.vis_n_num                  --�K��m����
         ,mon_emp_dt_rec.vis_o_num                  --�K��n����
         ,mon_emp_dt_rec.vis_p_num                  --�K��o����
         ,mon_emp_dt_rec.vis_q_num                  --�K��p����
         ,mon_emp_dt_rec.vis_r_num                  --�K��q����
         ,mon_emp_dt_rec.vis_s_num                  --�K��r����
         ,mon_emp_dt_rec.vis_t_num                  --�K��s����
         ,mon_emp_dt_rec.vis_u_num                  --�K��t����
         ,mon_emp_dt_rec.vis_v_num                  --�K��u����
         ,mon_emp_dt_rec.vis_w_num                  --�K��v����
         ,mon_emp_dt_rec.vis_x_num                  --�K��w����
         ,mon_emp_dt_rec.vis_y_num                  --�K��x����
         ,mon_emp_dt_rec.vis_z_num                  --�K��y����
        )
        ;
        -- �o�͌������Z
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_mon_emp_dt;
      -- *** DEBUG_LOG ***
      -- ���ʉc�ƈ��ʎ擾�o�^�����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_emp  || CHR(10) ||
                   ''
      );
      -- �J�[�\���N���[�Y
      CLOSE mon_emp_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_emp || CHR(10)   ||
                   ''
      );
        -- ���o�����i�[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- �o�͌����i�[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- ���o�A�o�͌��������O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_05               --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                   --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_emp                     --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage              --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                        --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** �o�^������O�n���h�� ***
    WHEN insert_error_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_emp_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_emp_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_emp_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_emp_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_emp_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_mon_emp_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_group_dt
   * Description      : ���ʉc�ƃO���[�v�ʎ擾�o�^ (A-12)
   ***********************************************************************************/
  PROCEDURE insert_mon_group_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_group_dt';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_extrct_cnt        NUMBER;              -- ���o����
    ln_output_cnt        NUMBER;              -- �o�͌���
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ʉc�ƃO���[�v�ʃf�[�^�擾�p�J�[�\��
    CURSOR mon_group_dt_cur
    IS
      SELECT
        inn_v.sum_org_code                  sum_org_code               --�W�v�g�D�b�c
       ,inn_v.group_base_code               group_base_code            --�O���[�v�e���_�b�c
       ,inn_v.sales_date                    sales_date                 --�̔��N�����^�̔��N��
       ,SUM(inn_v.cust_new_num            ) cust_new_num               --�ڋq�����i�V�K�j
       ,SUM(inn_v.cust_vd_new_num         ) cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
       ,SUM(inn_v.cust_other_new_num      ) cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
       ,SUM(inn_v.rslt_amt                ) rslt_amt                   --�������
       ,SUM(inn_v.rslt_new_amt            ) rslt_new_amt               --������сi�V�K�j
       ,SUM(inn_v.rslt_vd_new_amt         ) rslt_vd_new_amt            --������сiVD�F�V�K�j
       ,SUM(inn_v.rslt_vd_amt             ) rslt_vd_amt                --������сiVD�j
       ,SUM(inn_v.rslt_other_new_amt      ) rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
       ,SUM(inn_v.rslt_other_amt          ) rslt_other_amt             --������сiVD�ȊO�j
       ,SUM(inn_v.rslt_center_amt         ) rslt_center_amt            --�������_�Q�������
       ,SUM(inn_v.rslt_center_vd_amt      ) rslt_center_vd_amt         --�������_�Q������сiVD�j
       ,SUM(inn_v.rslt_center_other_amt   ) rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
       ,SUM(inn_v.tgt_sales_prsn_total_amt) tgt_sales_prsn_total_amt   --���ʔ���\�Z
       ,SUM(inn_v.tgt_amt                 ) tgt_amt                    --����v��
       ,SUM(inn_v.tgt_new_amt             ) tgt_new_amt                --����v��i�V�K�j
       ,SUM(inn_v.tgt_vd_new_amt          ) tgt_vd_new_amt             --����v��iVD�F�V�K�j
       ,SUM(inn_v.tgt_vd_amt              ) tgt_vd_amt                 --����v��iVD�j
       ,SUM(inn_v.tgt_other_new_amt       ) tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
       ,SUM(inn_v.tgt_other_amt           ) tgt_other_amt              --����v��iVD�ȊO�j
       ,SUM(inn_v.vis_num                 ) vis_num                    --�K�����
       ,SUM(inn_v.vis_new_num             ) vis_new_num                --�K����сi�V�K�j
       ,SUM(inn_v.vis_vd_new_num          ) vis_vd_new_num             --�K����сiVD�F�V�K�j
       ,SUM(inn_v.vis_vd_num              ) vis_vd_num                 --�K����сiVD�j
       ,SUM(inn_v.vis_other_new_num       ) vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
       ,SUM(inn_v.vis_other_num           ) vis_other_num              --�K����сiVD�ȊO�j
       ,SUM(inn_v.vis_mc_num              ) vis_mc_num                 --�K����сiMC�j
       ,SUM(inn_v.vis_sales_num           ) vis_sales_num              --�L������
       ,SUM(inn_v.tgt_vis_num             ) tgt_vis_num                --�K��v��
       ,SUM(inn_v.tgt_vis_new_num         ) tgt_vis_new_num            --�K��v��i�V�K�j
       ,SUM(inn_v.tgt_vis_vd_new_num      ) tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
       ,SUM(inn_v.tgt_vis_vd_num          ) tgt_vis_vd_num             --�K��v��iVD�j
       ,SUM(inn_v.tgt_vis_other_new_num   ) tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
       ,SUM(inn_v.tgt_vis_other_num       ) tgt_vis_other_num          --�K��v��iVD�ȊO�j
       ,SUM(inn_v.tgt_vis_mc_num          ) tgt_vis_mc_num             --�K��v��iMC�j
       ,SUM(inn_v.vis_a_num               ) vis_a_num                  --�K��`����
       ,SUM(inn_v.vis_b_num               ) vis_b_num                  --�K��a����
       ,SUM(inn_v.vis_c_num               ) vis_c_num                  --�K��b����
       ,SUM(inn_v.vis_d_num               ) vis_d_num                  --�K��c����
       ,SUM(inn_v.vis_e_num               ) vis_e_num                  --�K��d����
       ,SUM(inn_v.vis_f_num               ) vis_f_num                  --�K��e����
       ,SUM(inn_v.vis_g_num               ) vis_g_num                  --�K��f����
       ,SUM(inn_v.vis_h_num               ) vis_h_num                  --�K��g����
       ,SUM(inn_v.vis_i_num               ) vis_i_num                  --�K���@����
       ,SUM(inn_v.vis_j_num               ) vis_j_num                  --�K��i����
       ,SUM(inn_v.vis_k_num               ) vis_k_num                  --�K��j����
       ,SUM(inn_v.vis_l_num               ) vis_l_num                  --�K��k����
       ,SUM(inn_v.vis_m_num               ) vis_m_num                  --�K��l����
       ,SUM(inn_v.vis_n_num               ) vis_n_num                  --�K��m����
       ,SUM(inn_v.vis_o_num               ) vis_o_num                  --�K��n����
       ,SUM(inn_v.vis_p_num               ) vis_p_num                  --�K��o����
       ,SUM(inn_v.vis_q_num               ) vis_q_num                  --�K��p����
       ,SUM(inn_v.vis_r_num               ) vis_r_num                  --�K��q����
       ,SUM(inn_v.vis_s_num               ) vis_s_num                  --�K��r����
       ,SUM(inn_v.vis_t_num               ) vis_t_num                  --�K��s����
       ,SUM(inn_v.vis_u_num               ) vis_u_num                  --�K��t����
       ,SUM(inn_v.vis_v_num               ) vis_v_num                  --�K��u����
       ,SUM(inn_v.vis_w_num               ) vis_w_num                  --�K��v����
       ,SUM(inn_v.vis_x_num               ) vis_x_num                  --�K��w����
       ,SUM(inn_v.vis_y_num               ) vis_y_num                  --�K��x����
       ,SUM(inn_v.vis_z_num               ) vis_z_num                  --�K��y����
      FROM
        (
         SELECT
           CASE WHEN (
                      TO_DATE(xrrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                     )
                THEN  NVL(xrrv2.group_number_new, cv_null)
                ELSE  NVL(xrrv2.group_number_old, cv_null)
           END                              sum_org_code               --�W�v�g�D�b�c
          ,CASE WHEN (
                      TO_DATE(xrrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                     )
                THEN  xrrv2.work_base_code_new
                ELSE  xrrv2.work_base_code_old
           END                              group_base_code            --�O���[�v�e���_�b�c
          ,xsvsr.sales_date                 sales_date                 --�̔��N�����^�̔��N��
          ,xsvsr.cust_new_num               cust_new_num               --�ڋq�����i�V�K�j
          ,xsvsr.cust_vd_new_num            cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
          ,xsvsr.cust_other_new_num         cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
          ,xsvsr.rslt_amt                   rslt_amt                   --�������
          ,xsvsr.rslt_new_amt               rslt_new_amt               --������сi�V�K�j
          ,xsvsr.rslt_vd_new_amt            rslt_vd_new_amt            --������сiVD�F�V�K�j
          ,xsvsr.rslt_vd_amt                rslt_vd_amt                --������сiVD�j
          ,xsvsr.rslt_other_new_amt         rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
          ,xsvsr.rslt_other_amt             rslt_other_amt             --������сiVD�ȊO�j
          ,xsvsr.rslt_center_amt            rslt_center_amt            --�������_�Q�������
          ,xsvsr.rslt_center_vd_amt         rslt_center_vd_amt         --�������_�Q������сiVD�j
          ,xsvsr.rslt_center_other_amt      rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
          ,xsvsr.tgt_sales_prsn_total_amt   tgt_sales_prsn_total_amt   --���ʔ���\�Z
          ,xsvsr.tgt_amt                    tgt_amt                    --����v��
          ,xsvsr.tgt_new_amt                tgt_new_amt                --����v��i�V�K�j
          ,xsvsr.tgt_vd_new_amt             tgt_vd_new_amt             --����v��iVD�F�V�K�j
          ,xsvsr.tgt_vd_amt                 tgt_vd_amt                 --����v��iVD�j
          ,xsvsr.tgt_other_new_amt          tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
          ,xsvsr.tgt_other_amt              tgt_other_amt              --����v��iVD�ȊO�j
          ,xsvsr.vis_num                    vis_num                    --�K�����
          ,xsvsr.vis_new_num                vis_new_num                --�K����сi�V�K�j
          ,xsvsr.vis_vd_new_num             vis_vd_new_num             --�K����сiVD�F�V�K�j
          ,xsvsr.vis_vd_num                 vis_vd_num                 --�K����сiVD�j
          ,xsvsr.vis_other_new_num          vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
          ,xsvsr.vis_other_num              vis_other_num              --�K����сiVD�ȊO�j
          ,xsvsr.vis_mc_num                 vis_mc_num                 --�K����сiMC�j
          ,xsvsr.vis_sales_num              vis_sales_num              --�L������
          ,xsvsr.tgt_vis_num                tgt_vis_num                --�K��v��
          ,xsvsr.tgt_vis_new_num            tgt_vis_new_num            --�K��v��i�V�K�j
          ,xsvsr.tgt_vis_vd_new_num         tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
          ,xsvsr.tgt_vis_vd_num             tgt_vis_vd_num             --�K��v��iVD�j
          ,xsvsr.tgt_vis_other_new_num      tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
          ,xsvsr.tgt_vis_other_num          tgt_vis_other_num          --�K��v��iVD�ȊO�j
          ,xsvsr.tgt_vis_mc_num             tgt_vis_mc_num             --�K��v��iMC�j
          ,xsvsr.vis_a_num                  vis_a_num                  --�K��`����
          ,xsvsr.vis_b_num                  vis_b_num                  --�K��a����
          ,xsvsr.vis_c_num                  vis_c_num                  --�K��b����
          ,xsvsr.vis_d_num                  vis_d_num                  --�K��c����
          ,xsvsr.vis_e_num                  vis_e_num                  --�K��d����
          ,xsvsr.vis_f_num                  vis_f_num                  --�K��e����
          ,xsvsr.vis_g_num                  vis_g_num                  --�K��f����
          ,xsvsr.vis_h_num                  vis_h_num                  --�K��g����
          ,xsvsr.vis_i_num                  vis_i_num                  --�K���@����
          ,xsvsr.vis_j_num                  vis_j_num                  --�K��i����
          ,xsvsr.vis_k_num                  vis_k_num                  --�K��j����
          ,xsvsr.vis_l_num                  vis_l_num                  --�K��k����
          ,xsvsr.vis_m_num                  vis_m_num                  --�K��l����
          ,xsvsr.vis_n_num                  vis_n_num                  --�K��m����
          ,xsvsr.vis_o_num                  vis_o_num                  --�K��n����
          ,xsvsr.vis_p_num                  vis_p_num                  --�K��o����
          ,xsvsr.vis_q_num                  vis_q_num                  --�K��p����
          ,xsvsr.vis_r_num                  vis_r_num                  --�K��q����
          ,xsvsr.vis_s_num                  vis_s_num                  --�K��r����
          ,xsvsr.vis_t_num                  vis_t_num                  --�K��s����
          ,xsvsr.vis_u_num                  vis_u_num                  --�K��t����
          ,xsvsr.vis_v_num                  vis_v_num                  --�K��u����
          ,xsvsr.vis_w_num                  vis_w_num                  --�K��v����
          ,xsvsr.vis_x_num                  vis_x_num                  --�K��w����
          ,xsvsr.vis_y_num                  vis_y_num                  --�K��x����
          ,xsvsr.vis_z_num                  vis_z_num                  --�K��y����
         FROM
           xxcso_resource_relations_v2 xrrv2  -- ���\�[�X�֘A�}�X�^�i�ŐV�j�r���[
          ,xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}���e�[�u��
         WHERE  xrrv2.employee_number = xsvsr.sum_org_code  -- �]�ƈ��ԍ�
           AND  xsvsr.sum_org_type = cv_sum_org_type_emp  -- �W�v�g�D���
           AND  xsvsr.month_date_div = cv_month_date_div_mon  -- �����敪
           AND  xsvsr.sales_date IN (
                                      gv_ym_lst_1
                                     ,gv_ym_lst_2
                                     ,gv_ym_lst_3
                                     ,gv_ym_lst_4
                                     ,gv_ym_lst_5
                                     ,gv_ym_lst_6
                                    )  -- �̔��N����
        ) inn_v
      GROUP BY  inn_v.sum_org_code     --�O���[�v�ԍ�
               ,inn_v.group_base_code  --�O���[�v�e���_�b�c
               ,inn_v.sales_date       --�̔��N�����^�̔��N��
    ;
    -- *** ���[�J���E���R�[�h ***
    -- ���ʉc�ƃO���[�v�ʃf�[�^�擾�p���R�[�h
     mon_group_dt_rec mon_group_dt_cur%ROWTYPE;
    -- *** ���[�J����O ***
    insert_error_expt    EXCEPTION;    -- �o�^������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���o�A�o�͌���������
    ln_extrct_cnt := 0;              -- ���o����
    ln_output_cnt := 0;              -- �o�͌���
    -- ========================
    -- ���ʉc�ƃO���[�v�ʃf�[�^�擾
    -- ========================
    -- �J�[�\���I�[�v��
    OPEN mon_group_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- �J�[�\���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_group || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- �K�┄��v��Ǘ��\�T�}���e�[�u���o�^���� 
      -- ======================
      <<loop_mon_group_dt>>
      LOOP
        FETCH mon_group_dt_cur INTO mon_group_dt_rec;
        -- ���o�����擾
        ln_extrct_cnt := mon_group_dt_cur%ROWCOUNT;
        EXIT WHEN mon_group_dt_cur%NOTFOUND
        OR  mon_group_dt_cur%ROWCOUNT = 0;
        -- �o�^����
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --�쐬��
         ,creation_date              --�쐬��
         ,last_updated_by            --�ŏI�X�V��
         ,last_update_date           --�ŏI�X�V��
         ,last_update_login          --�ŏI�X�V���O�C��
         ,request_id                 --�v��ID
         ,program_application_id     --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                 --�R���J�����g�E�v���O����ID
         ,program_update_date        --�v���O�����X�V��
         ,sum_org_type               --�W�v�g�D���
         ,sum_org_code               --�W�v�g�D�b�c
         ,group_base_code            --�O���[�v�e���_�b�c
         ,month_date_div             --�����敪
         ,sales_date                 --�̔��N�����^�̔��N��
         ,gvm_type                   --��ʁ^���̋@�^�l�b
         ,cust_new_num               --�ڋq�����i�V�K�j
         ,cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
         ,cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
         ,rslt_amt                   --�������
         ,rslt_new_amt               --������сi�V�K�j
         ,rslt_vd_new_amt            --������сiVD�F�V�K�j
         ,rslt_vd_amt                --������сiVD�j
         ,rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
         ,rslt_other_amt             --������сiVD�ȊO�j
         ,rslt_center_amt            --�������_�Q�������
         ,rslt_center_vd_amt         --�������_�Q������сiVD�j
         ,rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
         ,tgt_sales_prsn_total_amt   --���ʔ���\�Z
         ,tgt_amt                    --����v��
         ,tgt_new_amt                --����v��i�V�K�j
         ,tgt_vd_new_amt             --����v��iVD�F�V�K�j
         ,tgt_vd_amt                 --����v��iVD�j
         ,tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
         ,tgt_other_amt              --����v��iVD�ȊO�j
         ,vis_num                    --�K�����
         ,vis_new_num                --�K����сi�V�K�j
         ,vis_vd_new_num             --�K����сiVD�F�V�K�j
         ,vis_vd_num                 --�K����сiVD�j
         ,vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
         ,vis_other_num              --�K����сiVD�ȊO�j
         ,vis_mc_num                 --�K����сiMC�j
         ,vis_sales_num              --�L������
         ,tgt_vis_num                --�K��v��
         ,tgt_vis_new_num            --�K��v��i�V�K�j
         ,tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
         ,tgt_vis_vd_num             --�K��v��iVD�j
         ,tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
         ,tgt_vis_other_num          --�K��v��iVD�ȊO�j
         ,tgt_vis_mc_num             --�K��v��iMC�j
         ,vis_a_num                  --�K��`����
         ,vis_b_num                  --�K��a����
         ,vis_c_num                  --�K��b����
         ,vis_d_num                  --�K��c����
         ,vis_e_num                  --�K��d����
         ,vis_f_num                  --�K��e����
         ,vis_g_num                  --�K��f����
         ,vis_h_num                  --�K��g����
         ,vis_i_num                  --�K���@����
         ,vis_j_num                  --�K��i����
         ,vis_k_num                  --�K��j����
         ,vis_l_num                  --�K��k����
         ,vis_m_num                  --�K��l����
         ,vis_n_num                  --�K��m����
         ,vis_o_num                  --�K��n����
         ,vis_p_num                  --�K��o����
         ,vis_q_num                  --�K��p����
         ,vis_r_num                  --�K��q����
         ,vis_s_num                  --�K��r����
         ,vis_t_num                  --�K��s����
         ,vis_u_num                  --�K��t����
         ,vis_v_num                  --�K��u����
         ,vis_w_num                  --�K��v����
         ,vis_x_num                  --�K��w����
         ,vis_y_num                  --�K��x����
         ,vis_z_num                  --�K��y����
        ) VALUES(
          cn_created_by                              --�쐬��
         ,cd_creation_date                           --�쐬��
         ,cn_last_updated_by                         --�ŏI�X�V��
         ,cd_last_update_date                        --�ŏI�X�V��
         ,cn_last_update_login                       --�ŏI�X�V���O�C��
         ,cn_request_id                              --�v��ID
         ,cn_program_application_id                  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                              --�R���J�����g�E�v���O����ID
         ,cd_program_update_date                     --�v���O�����X�V��
         ,cv_sum_org_type_group                      --�W�v�g�D���
         ,mon_group_dt_rec.sum_org_code              --�W�v�g�D�b�c
         ,mon_group_dt_rec.group_base_code           --�O���[�v�e���_�b�c
         ,cv_month_date_div_mon                      --�����敪
         ,mon_group_dt_rec.sales_date                --�̔��N�����^�̔��N��
         ,NULL                                       --��ʁ^���̋@�^�l�b
         ,mon_group_dt_rec.cust_new_num              --�ڋq�����i�V�K�j
         ,mon_group_dt_rec.cust_vd_new_num           --�ڋq�����iVD�F�V�K�j
         ,mon_group_dt_rec.cust_other_new_num        --�ڋq�����iVD�ȊO�F�V�K�j
         ,mon_group_dt_rec.rslt_amt                  --�������
         ,mon_group_dt_rec.rslt_new_amt              --������сi�V�K�j
         ,mon_group_dt_rec.rslt_vd_new_amt           --������сiVD�F�V�K�j
         ,mon_group_dt_rec.rslt_vd_amt               --������сiVD�j
         ,mon_group_dt_rec.rslt_other_new_amt        --������сiVD�ȊO�F�V�K�j
         ,mon_group_dt_rec.rslt_other_amt            --������сiVD�ȊO�j
         ,mon_group_dt_rec.rslt_center_amt           --�������_�Q�������
         ,mon_group_dt_rec.rslt_center_vd_amt        --�������_�Q������сiVD�j
         ,mon_group_dt_rec.rslt_center_other_amt     --�������_�Q������сiVD�ȊO�j
         ,mon_group_dt_rec.tgt_sales_prsn_total_amt  --���ʔ���\�Z
         ,mon_group_dt_rec.tgt_amt                   --����v��
         ,mon_group_dt_rec.tgt_new_amt               --����v��i�V�K�j
         ,mon_group_dt_rec.tgt_vd_new_amt            --����v��iVD�F�V�K�j
         ,mon_group_dt_rec.tgt_vd_amt                --����v��iVD�j
         ,mon_group_dt_rec.tgt_other_new_amt         --����v��iVD�ȊO�F�V�K�j
         ,mon_group_dt_rec.tgt_other_amt             --����v��iVD�ȊO�j
         ,mon_group_dt_rec.vis_num                   --�K�����
         ,mon_group_dt_rec.vis_new_num               --�K����сi�V�K�j
         ,mon_group_dt_rec.vis_vd_new_num            --�K����сiVD�F�V�K�j
         ,mon_group_dt_rec.vis_vd_num                --�K����сiVD�j
         ,mon_group_dt_rec.vis_other_new_num         --�K����сiVD�ȊO�F�V�K�j
         ,mon_group_dt_rec.vis_other_num             --�K����сiVD�ȊO�j
         ,mon_group_dt_rec.vis_mc_num                --�K����сiMC�j
         ,mon_group_dt_rec.vis_sales_num             --�L������
         ,mon_group_dt_rec.tgt_vis_num               --�K��v��
         ,mon_group_dt_rec.tgt_vis_new_num           --�K��v��i�V�K�j
         ,mon_group_dt_rec.tgt_vis_vd_new_num        --�K��v��iVD�F�V�K�j
         ,mon_group_dt_rec.tgt_vis_vd_num            --�K��v��iVD�j
         ,mon_group_dt_rec.tgt_vis_other_new_num     --�K��v��iVD�ȊO�F�V�K�j
         ,mon_group_dt_rec.tgt_vis_other_num         --�K��v��iVD�ȊO�j
         ,mon_group_dt_rec.tgt_vis_mc_num            --�K��v��iMC�j
         ,mon_group_dt_rec.vis_a_num                 --�K��`����
         ,mon_group_dt_rec.vis_b_num                 --�K��a����
         ,mon_group_dt_rec.vis_c_num                 --�K��b����
         ,mon_group_dt_rec.vis_d_num                 --�K��c����
         ,mon_group_dt_rec.vis_e_num                 --�K��d����
         ,mon_group_dt_rec.vis_f_num                 --�K��e����
         ,mon_group_dt_rec.vis_g_num                 --�K��f����
         ,mon_group_dt_rec.vis_h_num                 --�K��g����
         ,mon_group_dt_rec.vis_i_num                 --�K���@����
         ,mon_group_dt_rec.vis_j_num                 --�K��i����
         ,mon_group_dt_rec.vis_k_num                 --�K��j����
         ,mon_group_dt_rec.vis_l_num                 --�K��k����
         ,mon_group_dt_rec.vis_m_num                 --�K��l����
         ,mon_group_dt_rec.vis_n_num                 --�K��m����
         ,mon_group_dt_rec.vis_o_num                 --�K��n����
         ,mon_group_dt_rec.vis_p_num                 --�K��o����
         ,mon_group_dt_rec.vis_q_num                 --�K��p����
         ,mon_group_dt_rec.vis_r_num                 --�K��q����
         ,mon_group_dt_rec.vis_s_num                 --�K��r����
         ,mon_group_dt_rec.vis_t_num                 --�K��s����
         ,mon_group_dt_rec.vis_u_num                 --�K��t����
         ,mon_group_dt_rec.vis_v_num                 --�K��u����
         ,mon_group_dt_rec.vis_w_num                 --�K��v����
         ,mon_group_dt_rec.vis_x_num                 --�K��w����
         ,mon_group_dt_rec.vis_y_num                 --�K��x����
         ,mon_group_dt_rec.vis_z_num                 --�K��y����
        )
        ;
        -- �o�͌������Z
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_mon_group_dt;
      -- *** DEBUG_LOG ***
      -- �����ʉc�ƃO���[�v�ʎ擾�o�^�����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_grp  || CHR(10) ||
                   ''
      );
      -- �J�[�\���N���[�Y
      CLOSE mon_group_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_group || CHR(10)   ||
                   ''
      );
        -- ���o�����i�[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- �o�͌����i�[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- ���o�A�o�͌��������O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_05               --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                   --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_group                   --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage              --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                        --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** �o�^������O�n���h�� ***
    WHEN insert_error_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_group_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_group_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_group_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_group_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_group_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_mon_group_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_base_dt
   * Description      : ���ʋ��_�^�ەʎ擾�o�^ (A-13)
   ***********************************************************************************/
  PROCEDURE insert_mon_base_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_base_dt';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_extrct_cnt        NUMBER;              -- ���o����
    ln_output_cnt        NUMBER;              -- �o�͌���
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ʋ��_�^�ەʃf�[�^�擾�p�J�[�\��
    CURSOR mon_base_dt_cur
    IS
      SELECT
        xsvsr.group_base_code               sum_org_code               --�W�v�g�D�b�c
       ,xsvsr.sales_date                    sales_date                 --�̔��N�����^�̔��N��
       ,SUM(xsvsr.cust_new_num            ) cust_new_num               --�ڋq�����i�V�K�j
       ,SUM(xsvsr.cust_vd_new_num         ) cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
       ,SUM(xsvsr.cust_other_new_num      ) cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_amt                ) rslt_amt                   --�������
       ,SUM(xsvsr.rslt_new_amt            ) rslt_new_amt               --������сi�V�K�j
       ,SUM(xsvsr.rslt_vd_new_amt         ) rslt_vd_new_amt            --������сiVD�F�V�K�j
       ,SUM(xsvsr.rslt_vd_amt             ) rslt_vd_amt                --������сiVD�j
       ,SUM(xsvsr.rslt_other_new_amt      ) rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_other_amt          ) rslt_other_amt             --������сiVD�ȊO�j
       ,SUM(xsvsr.rslt_center_amt         ) rslt_center_amt            --�������_�Q�������
       ,SUM(xsvsr.rslt_center_vd_amt      ) rslt_center_vd_amt         --�������_�Q������сiVD�j
       ,SUM(xsvsr.rslt_center_other_amt   ) rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
       ,SUM(xsvsr.tgt_sales_prsn_total_amt) tgt_sales_prsn_total_amt   --���ʔ���\�Z
       ,SUM(xsvsr.tgt_amt                 ) tgt_amt                    --����v��
       ,SUM(xsvsr.tgt_new_amt             ) tgt_new_amt                --����v��i�V�K�j
       ,SUM(xsvsr.tgt_vd_new_amt          ) tgt_vd_new_amt             --����v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vd_amt              ) tgt_vd_amt                 --����v��iVD�j
       ,SUM(xsvsr.tgt_other_new_amt       ) tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_other_amt           ) tgt_other_amt              --����v��iVD�ȊO�j
       ,SUM(xsvsr.vis_num                 ) vis_num                    --�K�����
       ,SUM(xsvsr.vis_new_num             ) vis_new_num                --�K����сi�V�K�j
       ,SUM(xsvsr.vis_vd_new_num          ) vis_vd_new_num             --�K����сiVD�F�V�K�j
       ,SUM(xsvsr.vis_vd_num              ) vis_vd_num                 --�K����сiVD�j
       ,SUM(xsvsr.vis_other_new_num       ) vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.vis_other_num           ) vis_other_num              --�K����сiVD�ȊO�j
       ,SUM(xsvsr.vis_mc_num              ) vis_mc_num                 --�K����сiMC�j
       ,SUM(xsvsr.vis_sales_num           ) vis_sales_num              --�L������
       ,SUM(xsvsr.tgt_vis_num             ) tgt_vis_num                --�K��v��
       ,SUM(xsvsr.tgt_vis_new_num         ) tgt_vis_new_num            --�K��v��i�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_new_num      ) tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_num          ) tgt_vis_vd_num             --�K��v��iVD�j
       ,SUM(xsvsr.tgt_vis_other_new_num   ) tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_vis_other_num       ) tgt_vis_other_num          --�K��v��iVD�ȊO�j
       ,SUM(xsvsr.tgt_vis_mc_num          ) tgt_vis_mc_num             --�K��v��iMC�j
       ,SUM(xsvsr.vis_a_num               ) vis_a_num                  --�K��`����
       ,SUM(xsvsr.vis_b_num               ) vis_b_num                  --�K��a����
       ,SUM(xsvsr.vis_c_num               ) vis_c_num                  --�K��b����
       ,SUM(xsvsr.vis_d_num               ) vis_d_num                  --�K��c����
       ,SUM(xsvsr.vis_e_num               ) vis_e_num                  --�K��d����
       ,SUM(xsvsr.vis_f_num               ) vis_f_num                  --�K��e����
       ,SUM(xsvsr.vis_g_num               ) vis_g_num                  --�K��f����
       ,SUM(xsvsr.vis_h_num               ) vis_h_num                  --�K��g����
       ,SUM(xsvsr.vis_i_num               ) vis_i_num                  --�K���@����
       ,SUM(xsvsr.vis_j_num               ) vis_j_num                  --�K��i����
       ,SUM(xsvsr.vis_k_num               ) vis_k_num                  --�K��j����
       ,SUM(xsvsr.vis_l_num               ) vis_l_num                  --�K��k����
       ,SUM(xsvsr.vis_m_num               ) vis_m_num                  --�K��l����
       ,SUM(xsvsr.vis_n_num               ) vis_n_num                  --�K��m����
       ,SUM(xsvsr.vis_o_num               ) vis_o_num                  --�K��n����
       ,SUM(xsvsr.vis_p_num               ) vis_p_num                  --�K��o����
       ,SUM(xsvsr.vis_q_num               ) vis_q_num                  --�K��p����
       ,SUM(xsvsr.vis_r_num               ) vis_r_num                  --�K��q����
       ,SUM(xsvsr.vis_s_num               ) vis_s_num                  --�K��r����
       ,SUM(xsvsr.vis_t_num               ) vis_t_num                  --�K��s����
       ,SUM(xsvsr.vis_u_num               ) vis_u_num                  --�K��t����
       ,SUM(xsvsr.vis_v_num               ) vis_v_num                  --�K��u����
       ,SUM(xsvsr.vis_w_num               ) vis_w_num                  --�K��v����
       ,SUM(xsvsr.vis_x_num               ) vis_x_num                  --�K��w����
       ,SUM(xsvsr.vis_y_num               ) vis_y_num                  --�K��x����
       ,SUM(xsvsr.vis_z_num               ) vis_z_num                  --�K��y����
      FROM
           xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}���e�[�u��
         WHERE  xsvsr.sum_org_type = cv_sum_org_type_group  -- �W�v�g�D���
           AND  xsvsr.month_date_div = cv_month_date_div_mon  -- �����敪
           AND  xsvsr.sales_date IN (
                                      gv_ym_lst_1
                                     ,gv_ym_lst_2
                                     ,gv_ym_lst_3
                                     ,gv_ym_lst_4
                                     ,gv_ym_lst_5
                                     ,gv_ym_lst_6
                                    )  -- �̔��N����
      GROUP BY  xsvsr.group_base_code     --�Ζ��n���_�R�[�h
               ,xsvsr.sales_date          --�̔��N�����^�̔��N��
    ;
    -- *** ���[�J���E���R�[�h ***
    -- ���ʋ��_�^�ەʃf�[�^�擾�p���R�[�h
     mon_base_dt_rec mon_base_dt_cur%ROWTYPE;
    -- *** ���[�J����O ***
    insert_error_expt    EXCEPTION;    -- �o�^������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���o�A�o�͌���������
    ln_extrct_cnt := 0;              -- ���o����
    ln_output_cnt := 0;              -- �o�͌���
    -- ========================
    -- ���ʋ��_�^�ەʃf�[�^�擾
    -- ========================
    -- �J�[�\���I�[�v��
    OPEN mon_base_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- �J�[�\���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_base || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- �K�┄��v��Ǘ��\�T�}���e�[�u���o�^���� 
      -- ======================
      <<loop_mon_base_dt>>
      LOOP
        FETCH mon_base_dt_cur INTO mon_base_dt_rec;
        -- ���o�����擾
        ln_extrct_cnt := mon_base_dt_cur%ROWCOUNT;
        EXIT WHEN mon_base_dt_cur%NOTFOUND
        OR  mon_base_dt_cur%ROWCOUNT = 0;
        -- �o�^����
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --�쐬��
         ,creation_date              --�쐬��
         ,last_updated_by            --�ŏI�X�V��
         ,last_update_date           --�ŏI�X�V��
         ,last_update_login          --�ŏI�X�V���O�C��
         ,request_id                 --�v��ID
         ,program_application_id     --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                 --�R���J�����g�E�v���O����ID
         ,program_update_date        --�v���O�����X�V��
         ,sum_org_type               --�W�v�g�D���
         ,sum_org_code               --�W�v�g�D�b�c
         ,group_base_code            --�O���[�v�e���_�b�c
         ,month_date_div             --�����敪
         ,sales_date                 --�̔��N�����^�̔��N��
         ,gvm_type                   --��ʁ^���̋@�^�l�b
         ,cust_new_num               --�ڋq�����i�V�K�j
         ,cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
         ,cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
         ,rslt_amt                   --�������
         ,rslt_new_amt               --������сi�V�K�j
         ,rslt_vd_new_amt            --������сiVD�F�V�K�j
         ,rslt_vd_amt                --������сiVD�j
         ,rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
         ,rslt_other_amt             --������сiVD�ȊO�j
         ,rslt_center_amt            --�������_�Q�������
         ,rslt_center_vd_amt         --�������_�Q������сiVD�j
         ,rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
         ,tgt_sales_prsn_total_amt   --���ʔ���\�Z
         ,tgt_amt                    --����v��
         ,tgt_new_amt                --����v��i�V�K�j
         ,tgt_vd_new_amt             --����v��iVD�F�V�K�j
         ,tgt_vd_amt                 --����v��iVD�j
         ,tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
         ,tgt_other_amt              --����v��iVD�ȊO�j
         ,vis_num                    --�K�����
         ,vis_new_num                --�K����сi�V�K�j
         ,vis_vd_new_num             --�K����сiVD�F�V�K�j
         ,vis_vd_num                 --�K����сiVD�j
         ,vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
         ,vis_other_num              --�K����сiVD�ȊO�j
         ,vis_mc_num                 --�K����сiMC�j
         ,vis_sales_num              --�L������
         ,tgt_vis_num                --�K��v��
         ,tgt_vis_new_num            --�K��v��i�V�K�j
         ,tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
         ,tgt_vis_vd_num             --�K��v��iVD�j
         ,tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
         ,tgt_vis_other_num          --�K��v��iVD�ȊO�j
         ,tgt_vis_mc_num             --�K��v��iMC�j
         ,vis_a_num                  --�K��`����
         ,vis_b_num                  --�K��a����
         ,vis_c_num                  --�K��b����
         ,vis_d_num                  --�K��c����
         ,vis_e_num                  --�K��d����
         ,vis_f_num                  --�K��e����
         ,vis_g_num                  --�K��f����
         ,vis_h_num                  --�K��g����
         ,vis_i_num                  --�K���@����
         ,vis_j_num                  --�K��i����
         ,vis_k_num                  --�K��j����
         ,vis_l_num                  --�K��k����
         ,vis_m_num                  --�K��l����
         ,vis_n_num                  --�K��m����
         ,vis_o_num                  --�K��n����
         ,vis_p_num                  --�K��o����
         ,vis_q_num                  --�K��p����
         ,vis_r_num                  --�K��q����
         ,vis_s_num                  --�K��r����
         ,vis_t_num                  --�K��s����
         ,vis_u_num                  --�K��t����
         ,vis_v_num                  --�K��u����
         ,vis_w_num                  --�K��v����
         ,vis_x_num                  --�K��w����
         ,vis_y_num                  --�K��x����
         ,vis_z_num                  --�K��y����
        ) VALUES(
          cn_created_by                             --�쐬��
         ,cd_creation_date                          --�쐬��
         ,cn_last_updated_by                        --�ŏI�X�V��
         ,cd_last_update_date                       --�ŏI�X�V��
         ,cn_last_update_login                      --�ŏI�X�V���O�C��
         ,cn_request_id                             --�v��ID
         ,cn_program_application_id                 --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                             --�R���J�����g�E�v���O����ID
         ,cd_program_update_date                    --�v���O�����X�V��
         ,cv_sum_org_type_dept                      --�W�v�g�D���
         ,mon_base_dt_rec.sum_org_code              --�W�v�g�D�b�c
         ,cv_null                                   --�O���[�v�e���_�b�c
         ,cv_month_date_div_mon                     --�����敪
         ,mon_base_dt_rec.sales_date                --�̔��N�����^�̔��N��
         ,NULL                                      --��ʁ^���̋@�^�l�b
         ,mon_base_dt_rec.cust_new_num              --�ڋq�����i�V�K�j
         ,mon_base_dt_rec.cust_vd_new_num           --�ڋq�����iVD�F�V�K�j
         ,mon_base_dt_rec.cust_other_new_num        --�ڋq�����iVD�ȊO�F�V�K�j
         ,mon_base_dt_rec.rslt_amt                  --�������
         ,mon_base_dt_rec.rslt_new_amt              --������сi�V�K�j
         ,mon_base_dt_rec.rslt_vd_new_amt           --������сiVD�F�V�K�j
         ,mon_base_dt_rec.rslt_vd_amt               --������сiVD�j
         ,mon_base_dt_rec.rslt_other_new_amt        --������сiVD�ȊO�F�V�K�j
         ,mon_base_dt_rec.rslt_other_amt            --������сiVD�ȊO�j
         ,mon_base_dt_rec.rslt_center_amt           --�������_�Q�������
         ,mon_base_dt_rec.rslt_center_vd_amt        --�������_�Q������сiVD�j
         ,mon_base_dt_rec.rslt_center_other_amt     --�������_�Q������сiVD�ȊO�j
         ,mon_base_dt_rec.tgt_sales_prsn_total_amt  --���ʔ���\�Z
         ,mon_base_dt_rec.tgt_amt                   --����v��
         ,mon_base_dt_rec.tgt_new_amt               --����v��i�V�K�j
         ,mon_base_dt_rec.tgt_vd_new_amt            --����v��iVD�F�V�K�j
         ,mon_base_dt_rec.tgt_vd_amt                --����v��iVD�j
         ,mon_base_dt_rec.tgt_other_new_amt         --����v��iVD�ȊO�F�V�K�j
         ,mon_base_dt_rec.tgt_other_amt             --����v��iVD�ȊO�j
         ,mon_base_dt_rec.vis_num                   --�K�����
         ,mon_base_dt_rec.vis_new_num               --�K����сi�V�K�j
         ,mon_base_dt_rec.vis_vd_new_num            --�K����сiVD�F�V�K�j
         ,mon_base_dt_rec.vis_vd_num                --�K����сiVD�j
         ,mon_base_dt_rec.vis_other_new_num         --�K����сiVD�ȊO�F�V�K�j
         ,mon_base_dt_rec.vis_other_num             --�K����сiVD�ȊO�j
         ,mon_base_dt_rec.vis_mc_num                --�K����сiMC�j
         ,mon_base_dt_rec.vis_sales_num             --�L������
         ,mon_base_dt_rec.tgt_vis_num               --�K��v��
         ,mon_base_dt_rec.tgt_vis_new_num           --�K��v��i�V�K�j
         ,mon_base_dt_rec.tgt_vis_vd_new_num        --�K��v��iVD�F�V�K�j
         ,mon_base_dt_rec.tgt_vis_vd_num            --�K��v��iVD�j
         ,mon_base_dt_rec.tgt_vis_other_new_num     --�K��v��iVD�ȊO�F�V�K�j
         ,mon_base_dt_rec.tgt_vis_other_num         --�K��v��iVD�ȊO�j
         ,mon_base_dt_rec.tgt_vis_mc_num            --�K��v��iMC�j
         ,mon_base_dt_rec.vis_a_num                 --�K��`����
         ,mon_base_dt_rec.vis_b_num                 --�K��a����
         ,mon_base_dt_rec.vis_c_num                 --�K��b����
         ,mon_base_dt_rec.vis_d_num                 --�K��c����
         ,mon_base_dt_rec.vis_e_num                 --�K��d����
         ,mon_base_dt_rec.vis_f_num                 --�K��e����
         ,mon_base_dt_rec.vis_g_num                 --�K��f����
         ,mon_base_dt_rec.vis_h_num                 --�K��g����
         ,mon_base_dt_rec.vis_i_num                 --�K���@����
         ,mon_base_dt_rec.vis_j_num                 --�K��i����
         ,mon_base_dt_rec.vis_k_num                 --�K��j����
         ,mon_base_dt_rec.vis_l_num                 --�K��k����
         ,mon_base_dt_rec.vis_m_num                 --�K��l����
         ,mon_base_dt_rec.vis_n_num                 --�K��m����
         ,mon_base_dt_rec.vis_o_num                 --�K��n����
         ,mon_base_dt_rec.vis_p_num                 --�K��o����
         ,mon_base_dt_rec.vis_q_num                 --�K��p����
         ,mon_base_dt_rec.vis_r_num                 --�K��q����
         ,mon_base_dt_rec.vis_s_num                 --�K��r����
         ,mon_base_dt_rec.vis_t_num                 --�K��s����
         ,mon_base_dt_rec.vis_u_num                 --�K��t����
         ,mon_base_dt_rec.vis_v_num                 --�K��u����
         ,mon_base_dt_rec.vis_w_num                 --�K��v����
         ,mon_base_dt_rec.vis_x_num                 --�K��w����
         ,mon_base_dt_rec.vis_y_num                 --�K��x����
         ,mon_base_dt_rec.vis_z_num                 --�K��y����
        )
        ;
        -- �o�͌������Z
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_mon_base_dt;
      -- *** DEBUG_LOG ***
      -- ���ʋ��_�^�ەʎ擾�o�^�����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_base  || CHR(10) ||
                   ''
      );
      -- �J�[�\���N���[�Y
      CLOSE mon_base_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_base || CHR(10)   ||
                   ''
      );
        -- ���o�����i�[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- �o�͌����i�[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- ���o�A�o�͌��������O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_05               --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                   --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_base                    --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage              --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                        --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** �o�^������O�n���h�� ***
    WHEN insert_error_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_base_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_base_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_base_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_base_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_base_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_mon_base_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_area_dt
   * Description      : ���ʒn��c�ƕ��^���ʎ擾�o�^ (A-14)
   ***********************************************************************************/
  PROCEDURE insert_mon_area_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_area_dt';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_extrct_cnt        NUMBER;              -- ���o����
    ln_output_cnt        NUMBER;              -- �o�͌���
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ʒn��c�ƕ��^���ʃf�[�^�擾�p�J�[�\��
    CURSOR mon_area_dt_cur
    IS
      SELECT
        xablv.base_code                  sum_org_code               --�W�v�g�D�b�c
       ,xsvsr.sales_date                 sales_date                 --�̔��N�����^�̔��N��
       ,SUM(xsvsr.cust_new_num         ) cust_new_num               --�ڋq�����i�V�K�j
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --�������
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --������сi�V�K�j
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --������сiVD�F�V�K�j
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --������сiVD�j
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --������сiVD�ȊO�j
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --�������_�Q�������
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --�������_�Q������сiVD�j
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
       ,SUM(xsvsr.tgt_sales_prsn_total_amt) tgt_sales_prsn_total_amt   --���ʔ���\�Z
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --����v��
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --����v��i�V�K�j
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --����v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --����v��iVD�j
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --����v��iVD�ȊO�j
       ,SUM(xsvsr.vis_num              ) vis_num                    --�K�����
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --�K����сi�V�K�j
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --�K����сiVD�F�V�K�j
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --�K����сiVD�j
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --�K����сiVD�ȊO�j
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --�K����сiMC�j
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --�L������
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --�K��v��
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --�K��v��i�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --�K��v��iVD�j
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --�K��v��iVD�ȊO�j
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --�K��v��iMC�j
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --�K��`����
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --�K��a����
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --�K��b����
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --�K��c����
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --�K��d����
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --�K��e����
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --�K��f����
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --�K��g����
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --�K���@����
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --�K��i����
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --�K��j����
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --�K��k����
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --�K��l����
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --�K��m����
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --�K��n����
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --�K��o����
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --�K��p����
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --�K��q����
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --�K��r����
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --�K��s����
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --�K��t����
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --�K��u����
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --�K��v����
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --�K��w����
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --�K��x����
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --�K��y����
      FROM
        xxcso_aff_base_level_v xablv  -- AFF����K�w�}�X�^�r���[
       ,xxcso_sum_visit_sale_rep xsvsr  -- �K�┄��v��Ǘ��\�T�}���e�[�u��
      WHERE  xablv.child_base_code = xsvsr.sum_org_code  -- ���_�R�[�h�i�q�j
        AND  xsvsr.sum_org_type = cv_sum_org_type_dept  -- �W�v�g�D���
        AND  xsvsr.month_date_div = cv_month_date_div_mon  -- �����敪
        AND  xsvsr.sales_date IN (
                                   gv_ym_lst_1
                                  ,gv_ym_lst_2
                                  ,gv_ym_lst_3
                                  ,gv_ym_lst_4
                                  ,gv_ym_lst_5
                                  ,gv_ym_lst_6
                                 )  -- �̔��N����
      GROUP BY  xablv.base_code      --���_�R�[�h
               ,xsvsr.sales_date     --�̔��N�����^�̔��N��
    ;
    -- *** ���[�J���E���R�[�h ***
    -- ���ʒn��c�ƕ��^���ʃf�[�^�擾�p���R�[�h
     mon_area_dt_rec mon_area_dt_cur%ROWTYPE;
    -- *** ���[�J����O ***
    insert_error_expt    EXCEPTION;    -- �o�^������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���o�A�o�͌���������
    ln_extrct_cnt := 0;              -- ���o����
    ln_output_cnt := 0;              -- �o�͌���
    -- ========================
    -- ���ʒn��c�ƕ��^���ʃf�[�^�擾
    -- ========================
    -- �J�[�\���I�[�v��
    OPEN mon_area_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- �J�[�\���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_area || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- �K�┄��v��Ǘ��\�T�}���e�[�u���o�^���� 
      -- ======================
      <<loop_mon_area_dt>>
      LOOP
        FETCH mon_area_dt_cur INTO mon_area_dt_rec;
        -- ���o�����擾
        ln_extrct_cnt := mon_area_dt_cur%ROWCOUNT;
        EXIT WHEN mon_area_dt_cur%NOTFOUND
        OR  mon_area_dt_cur%ROWCOUNT = 0;
        -- �o�^����
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --�쐬��
         ,creation_date              --�쐬��
         ,last_updated_by            --�ŏI�X�V��
         ,last_update_date           --�ŏI�X�V��
         ,last_update_login          --�ŏI�X�V���O�C��
         ,request_id                 --�v��ID
         ,program_application_id     --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                 --�R���J�����g�E�v���O����ID
         ,program_update_date        --�v���O�����X�V��
         ,sum_org_type               --�W�v�g�D���
         ,sum_org_code               --�W�v�g�D�b�c
         ,group_base_code            --�O���[�v�e���_�b�c
         ,month_date_div             --�����敪
         ,sales_date                 --�̔��N�����^�̔��N��
         ,gvm_type                   --��ʁ^���̋@�^�l�b
         ,cust_new_num               --�ڋq�����i�V�K�j
         ,cust_vd_new_num            --�ڋq�����iVD�F�V�K�j
         ,cust_other_new_num         --�ڋq�����iVD�ȊO�F�V�K�j
         ,rslt_amt                   --�������
         ,rslt_new_amt               --������сi�V�K�j
         ,rslt_vd_new_amt            --������сiVD�F�V�K�j
         ,rslt_vd_amt                --������сiVD�j
         ,rslt_other_new_amt         --������сiVD�ȊO�F�V�K�j
         ,rslt_other_amt             --������сiVD�ȊO�j
         ,rslt_center_amt            --�������_�Q�������
         ,rslt_center_vd_amt         --�������_�Q������сiVD�j
         ,rslt_center_other_amt      --�������_�Q������сiVD�ȊO�j
         ,tgt_sales_prsn_total_amt   --���ʔ���\�Z
         ,tgt_amt                    --����v��
         ,tgt_new_amt                --����v��i�V�K�j
         ,tgt_vd_new_amt             --����v��iVD�F�V�K�j
         ,tgt_vd_amt                 --����v��iVD�j
         ,tgt_other_new_amt          --����v��iVD�ȊO�F�V�K�j
         ,tgt_other_amt              --����v��iVD�ȊO�j
         ,vis_num                    --�K�����
         ,vis_new_num                --�K����сi�V�K�j
         ,vis_vd_new_num             --�K����сiVD�F�V�K�j
         ,vis_vd_num                 --�K����сiVD�j
         ,vis_other_new_num          --�K����сiVD�ȊO�F�V�K�j
         ,vis_other_num              --�K����сiVD�ȊO�j
         ,vis_mc_num                 --�K����сiMC�j
         ,vis_sales_num              --�L������
         ,tgt_vis_num                --�K��v��
         ,tgt_vis_new_num            --�K��v��i�V�K�j
         ,tgt_vis_vd_new_num         --�K��v��iVD�F�V�K�j
         ,tgt_vis_vd_num             --�K��v��iVD�j
         ,tgt_vis_other_new_num      --�K��v��iVD�ȊO�F�V�K�j
         ,tgt_vis_other_num          --�K��v��iVD�ȊO�j
         ,tgt_vis_mc_num             --�K��v��iMC�j
         ,vis_a_num                  --�K��`����
         ,vis_b_num                  --�K��a����
         ,vis_c_num                  --�K��b����
         ,vis_d_num                  --�K��c����
         ,vis_e_num                  --�K��d����
         ,vis_f_num                  --�K��e����
         ,vis_g_num                  --�K��f����
         ,vis_h_num                  --�K��g����
         ,vis_i_num                  --�K���@����
         ,vis_j_num                  --�K��i����
         ,vis_k_num                  --�K��j����
         ,vis_l_num                  --�K��k����
         ,vis_m_num                  --�K��l����
         ,vis_n_num                  --�K��m����
         ,vis_o_num                  --�K��n����
         ,vis_p_num                  --�K��o����
         ,vis_q_num                  --�K��p����
         ,vis_r_num                  --�K��q����
         ,vis_s_num                  --�K��r����
         ,vis_t_num                  --�K��s����
         ,vis_u_num                  --�K��t����
         ,vis_v_num                  --�K��u����
         ,vis_w_num                  --�K��v����
         ,vis_x_num                  --�K��w����
         ,vis_y_num                  --�K��x����
         ,vis_z_num                  --�K��y����
        ) VALUES(
          cn_created_by                             --�쐬��
         ,cd_creation_date                          --�쐬��
         ,cn_last_updated_by                        --�ŏI�X�V��
         ,cd_last_update_date                       --�ŏI�X�V��
         ,cn_last_update_login                      --�ŏI�X�V���O�C��
         ,cn_request_id                             --�v��ID
         ,cn_program_application_id                 --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,cn_program_id                             --�R���J�����g�E�v���O����ID
         ,cd_program_update_date                    --�v���O�����X�V��
         ,cv_sum_org_type_area                      --�W�v�g�D���
         ,mon_area_dt_rec.sum_org_code              --�W�v�g�D�b�c
         ,cv_null                                   --�O���[�v�e���_�b�c
         ,cv_month_date_div_mon                     --�����敪
         ,mon_area_dt_rec.sales_date                --�̔��N�����^�̔��N��
         ,NULL                                      --��ʁ^���̋@�^�l�b
         ,mon_area_dt_rec.cust_new_num              --�ڋq�����i�V�K�j
         ,mon_area_dt_rec.cust_vd_new_num           --�ڋq�����iVD�F�V�K�j
         ,mon_area_dt_rec.cust_other_new_num        --�ڋq�����iVD�ȊO�F�V�K�j
         ,mon_area_dt_rec.rslt_amt                  --�������
         ,mon_area_dt_rec.rslt_new_amt              --������сi�V�K�j
         ,mon_area_dt_rec.rslt_vd_new_amt           --������сiVD�F�V�K�j
         ,mon_area_dt_rec.rslt_vd_amt               --������сiVD�j
         ,mon_area_dt_rec.rslt_other_new_amt        --������сiVD�ȊO�F�V�K�j
         ,mon_area_dt_rec.rslt_other_amt            --������сiVD�ȊO�j
         ,mon_area_dt_rec.rslt_center_amt           --�������_�Q�������
         ,mon_area_dt_rec.rslt_center_vd_amt        --�������_�Q������сiVD�j
         ,mon_area_dt_rec.rslt_center_other_amt     --�������_�Q������сiVD�ȊO�j
         ,mon_area_dt_rec.tgt_sales_prsn_total_amt  --���ʔ���\�Z
         ,mon_area_dt_rec.tgt_amt                   --����v��
         ,mon_area_dt_rec.tgt_new_amt               --����v��i�V�K�j
         ,mon_area_dt_rec.tgt_vd_new_amt            --����v��iVD�F�V�K�j
         ,mon_area_dt_rec.tgt_vd_amt                --����v��iVD�j
         ,mon_area_dt_rec.tgt_other_new_amt         --����v��iVD�ȊO�F�V�K�j
         ,mon_area_dt_rec.tgt_other_amt             --����v��iVD�ȊO�j
         ,mon_area_dt_rec.vis_num                   --�K�����
         ,mon_area_dt_rec.vis_new_num               --�K����сi�V�K�j
         ,mon_area_dt_rec.vis_vd_new_num            --�K����сiVD�F�V�K�j
         ,mon_area_dt_rec.vis_vd_num                --�K����сiVD�j
         ,mon_area_dt_rec.vis_other_new_num         --�K����сiVD�ȊO�F�V�K�j
         ,mon_area_dt_rec.vis_other_num             --�K����сiVD�ȊO�j
         ,mon_area_dt_rec.vis_mc_num                --�K����сiMC�j
         ,mon_area_dt_rec.vis_sales_num             --�L������
         ,mon_area_dt_rec.tgt_vis_num               --�K��v��
         ,mon_area_dt_rec.tgt_vis_new_num           --�K��v��i�V�K�j
         ,mon_area_dt_rec.tgt_vis_vd_new_num        --�K��v��iVD�F�V�K�j
         ,mon_area_dt_rec.tgt_vis_vd_num            --�K��v��iVD�j
         ,mon_area_dt_rec.tgt_vis_other_new_num     --�K��v��iVD�ȊO�F�V�K�j
         ,mon_area_dt_rec.tgt_vis_other_num         --�K��v��iVD�ȊO�j
         ,mon_area_dt_rec.tgt_vis_mc_num            --�K��v��iMC�j
         ,mon_area_dt_rec.vis_a_num                 --�K��`����
         ,mon_area_dt_rec.vis_b_num                 --�K��a����
         ,mon_area_dt_rec.vis_c_num                 --�K��b����
         ,mon_area_dt_rec.vis_d_num                 --�K��c����
         ,mon_area_dt_rec.vis_e_num                 --�K��d����
         ,mon_area_dt_rec.vis_f_num                 --�K��e����
         ,mon_area_dt_rec.vis_g_num                 --�K��f����
         ,mon_area_dt_rec.vis_h_num                 --�K��g����
         ,mon_area_dt_rec.vis_i_num                 --�K���@����
         ,mon_area_dt_rec.vis_j_num                 --�K��i����
         ,mon_area_dt_rec.vis_k_num                 --�K��j����
         ,mon_area_dt_rec.vis_l_num                 --�K��k����
         ,mon_area_dt_rec.vis_m_num                 --�K��l����
         ,mon_area_dt_rec.vis_n_num                 --�K��m����
         ,mon_area_dt_rec.vis_o_num                 --�K��n����
         ,mon_area_dt_rec.vis_p_num                 --�K��o����
         ,mon_area_dt_rec.vis_q_num                 --�K��p����
         ,mon_area_dt_rec.vis_r_num                 --�K��q����
         ,mon_area_dt_rec.vis_s_num                 --�K��r����
         ,mon_area_dt_rec.vis_t_num                 --�K��s����
         ,mon_area_dt_rec.vis_u_num                 --�K��t����
         ,mon_area_dt_rec.vis_v_num                 --�K��u����
         ,mon_area_dt_rec.vis_w_num                 --�K��v����
         ,mon_area_dt_rec.vis_x_num                 --�K��w����
         ,mon_area_dt_rec.vis_y_num                 --�K��x����
         ,mon_area_dt_rec.vis_z_num                 --�K��y����
        )
        ;
        -- �o�͌������Z
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_area_dt;
      -- *** DEBUG_LOG ***
      -- ���ʒn��c�ƕ��^���ʎ擾�o�^�����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_area  || CHR(10) ||
                   ''
      );
      -- �J�[�\���N���[�Y
      CLOSE mon_area_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_area || CHR(10)   ||
                   ''
      );
        -- ���o�����i�[
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- �o�͌����i�[
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- ���o�A�o�͌��������O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_05               --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                   --�g�[�N���R�[�h1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_area                    --�g�[�N���l1
                      ,iv_token_name2  => cv_tkn_errmessage              --�g�[�N���R�[�h2
                      ,iv_token_value2 => SQLERRM                        --�g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** �o�^������O�n���h�� ***
    WHEN insert_error_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_area_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_area_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_area_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_area_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (mon_area_dt_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE mon_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_mon_area_dt;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    /* 2009.11.06 K.Satomura E_T4_00135�Ή� START */
    gn_warn_cnt   := 0;
    /* 2009.11.06 K.Satomura E_T4_00135�Ή� END */
--
    -- ========================================
    -- A-1.�������� 
    -- ========================================
    init(
       ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    -- ========================================
    -- A-2.�p�����[�^�`�F�b�N 
    -- ========================================
    check_parm(
       ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    IF (gv_prm_process_div = cv_process_div_del) THEN
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
--
      -- ========================================
      -- A-3.�����Ώۃf�[�^�폜 
      -- ========================================
      delete_data(
         ov_errbuf      => lv_errbuf      -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode     => lv_retcode     -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg      => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    ELSIF (gv_prm_process_div = cv_process_div_ins) THEN
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
--
      -- =================================================
      -- A-4.���ʌڋq�ʃf�[�^�擾 
      -- =================================================
      get_day_acct_data(
         ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
/* 20090828_abe_0001194 START*/
----
--    -- =================================================
--    -- A-6.���ʉc�ƈ��ʎ擾�o�^ 
--    -- =================================================
--    insert_day_emp_dt(
--       ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
--      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
--      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-7.���ʉc�ƃO���[�v�ʎ擾�o�^ 
--    -- =================================================
--    insert_day_group_dt(
--       ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
--      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
--      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-8.���ʋ��_�^�ەʎ擾�o�^ 
--    -- =================================================
--    insert_day_base_dt(
--       ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
--      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
--      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-9.���ʒn��c�ƕ��^���ʎ擾�o�^ 
--    -- =================================================
--    insert_day_area_dt(
--       ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
--      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
--      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
/* 20090828_abe_0001194 END*/
--
      -- =================================================
      -- A-10.���ʌڋq�ʎ擾�o�^ 
      -- =================================================
      insert_mon_acct_dt(
         ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
/* 20090828_abe_0001194 START*/
----
--    -- =================================================
--    -- A-11.���ʉc�ƈ��ʎ擾�o�^ 
--    -- =================================================
--    insert_mon_emp_dt(
--       ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
--      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
--      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-12.���ʉc�ƃO���[�v�ʎ擾�o�^ 
--    -- =================================================
--    insert_mon_group_dt(
--       ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
--      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
--      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-13.���ʋ��_�^�ەʎ擾�o�^ 
--    -- =================================================
--    insert_mon_base_dt(
--       ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
--      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
--      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-14.���ʒn��c�ƕ��^���ʎ擾�o�^ 
--    -- =================================================
--    insert_mon_area_dt(
--       ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W            --# �Œ� #
--      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
--      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
/* 20090828_abe_0001194 END*/
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    END IF;
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
    /* 2009.11.06 K.Satomura E_T4_00135�Ή� START */
    IF (gn_warn_cnt > 0) THEN
      ov_retcode := cv_status_warn;
      --
    END IF;
    /* 2009.11.06 K.Satomura E_T4_00135�Ή� END */
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W  --# �Œ� #
-- 2012/02/17 Ver.1.9 A.Shirakawa MOD Start
--    ,retcode       OUT NOCOPY VARCHAR2 )  --   ���^�[���E�R�[�h    --# �Œ� #
    ,retcode       OUT NOCOPY VARCHAR2    --   ���^�[���E�R�[�h    --# �Œ� #
    ,iv_process_div IN        VARCHAR2 )  --   �����敪
-- 2012/02/17 Ver.1.9 A.Shirakawa MOD End
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  �Œ蕔 END   #############################
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    -- ===============================================
    -- �p�����[�^�̊i�[
    -- ===============================================
    gv_prm_process_div := iv_process_div;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --�G���[���b�Z�[�W
       );
    END IF;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    -- �����敪��'9'(�폜)�̏ꍇ�A�폜������\��
    IF (gv_prm_process_div = cv_process_div_del) THEN
      gn_extrct_cnt := gn_delete_cnt;
      gn_output_cnt := gn_delete_cnt;
    END IF;
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
    -- =======================
    -- A-15.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_extrct_cnt)  -- ���o����
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_output_cnt)  -- �o�͌���
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(0)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    /* 2009.11.06 K.Satomura E_T4_00135�Ή� START */
                    --,iv_token_value1 => TO_CHAR(0)
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                    /* 2009.11.06 K.Satomura E_T4_00135�Ή� END */
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    /* 2009.11.06 K.Satomura E_T4_00135�Ή� START */
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    /* 2009.11.06 K.Satomura E_T4_00135�Ή� END */
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
                   ''
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO019A10C;
/
