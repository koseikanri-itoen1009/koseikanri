CREATE OR REPLACE PACKAGE BODY xxinv100002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV100002C(body)
 * Description      : �̔��v��\
 * MD.050/070       : �̔��v��E����v�� (T_MD050_BPO_100)
 *                    �̔��v��\         (T_MD070_BPO_10B)
 * Version          : 1.8
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  pro_get_cus_option           P �f�[�^�擾    - �J�X�^���I�v�V�����擾        (B-1-0)
 *  prc_sale_plan                P �f�[�^���o    - �̔��v��\��񒊏o(�S���_��)  (B-1-1-1)
 *  prc_sale_plan_1              P �f�[�^���o    - �̔��v��\��x�񒊏o(���_��)    (B-1-1-2)
 *  prc_create_xml_data_user     P XML�f�[�^�ϊ� - ���[�U�[��񕔕�       (user_info)
 *  prc_create_xml_data_param    P XML�f�[�^�ϊ� - �p�����[�^��񕔕�     (param_info)
 *  prc_create_xml_data          P XML�f�[�^�쐬 - ���[�f�[�^�o��
 *  submain                      P ���C�������v���V�[�W��
 *  main                         P �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 *  convert_into_xml             F XML�f�[�^�ϊ�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/18   1.0   Tatsuya Kurata   �V�K�쐬
 *  2008/04/22   1.1   Masanobu Kimura  �����ύX�v��#27
 *  2008/04/28   1.2   Sumie Nakamura   �d����W���P���w�b�_(�A�h�I��)���o�����R��Ή�
 *  2008/04/28   1.3   Yuko Kawano      �����ύX�v��#62,76
 *  2008/04/30   1.4   Tatsuya Kurata   �����ύX�v��#76
 *  2008/07/02   1.5   Satoshi Yunba    �֑������Ή�
 *  2009/03/23   1.6   Hajime Iida      �{�ԏ�Q#1334�Ή�
 *  2009/04/14   1.7   �g�� ����        �{�ԏ�Q#1409�Ή�
 *  2009/04/20   1.8   �Ŗ� ���\        �{�ԏ�Q#1409�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���^
  -- ==================================================
  -- ���͂o�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
      year             VARCHAR2(4)    -- �N�x
     ,prod_div         VARCHAR2(2)    -- ���i�敪
     ,gen              VARCHAR2(2)    -- ����
     ,output_unit      VARCHAR2(4)    -- �o�͒P��
--2008.04.28 Y.Kawano modify start
--     ,output_type      VARCHAR2(6)    -- �o�͎��
     ,output_type      VARCHAR2(8)    -- �o�͎��
--2008.04.28 Y.Kawano modify end
     ,base_01          VARCHAR2(4)    -- ���_�P
     ,base_02          VARCHAR2(4)    -- ���_�Q
     ,base_03          VARCHAR2(4)    -- ���_�R
     ,base_04          VARCHAR2(4)    -- ���_�S
     ,base_05          VARCHAR2(4)    -- ���_�T
     ,base_06          VARCHAR2(4)    -- ���_�U
     ,base_07          VARCHAR2(4)    -- ���_�V
     ,base_08          VARCHAR2(4)    -- ���_�W
     ,base_09          VARCHAR2(4)    -- ���_�X
     ,base_10          VARCHAR2(4)    -- ���_�P�O
     ,crowd_code_01    VARCHAR2(4)    -- �Q�R�[�h�P
     ,crowd_code_02    VARCHAR2(4)    -- �Q�R�[�h�Q
     ,crowd_code_03    VARCHAR2(4)    -- �Q�R�[�h�R
     ,crowd_code_04    VARCHAR2(4)    -- �Q�R�[�h�S
     ,crowd_code_05    VARCHAR2(4)    -- �Q�R�[�h�T
     ,crowd_code_06    VARCHAR2(4)    -- �Q�R�[�h�U
     ,crowd_code_07    VARCHAR2(4)    -- �Q�R�[�h�V
     ,crowd_code_08    VARCHAR2(4)    -- �Q�R�[�h�W
     ,crowd_code_09    VARCHAR2(4)    -- �Q�R�[�h�X
     ,crowd_code_10    VARCHAR2(4)    -- �Q�R�[�h�P�O
    );
--
  -- �̔��v��\���擾�f�[�^�i�[�p���R�[�h�ϐ�(�S���_�p)
  TYPE rec_sale_plan IS RECORD 
    (
       skbn              xxcmn_item_categories2_v.segment1%TYPE      -- ���i�敪
      ,gun               xxcmn_item_categories2_v.segment1%TYPE      -- �Q�R�[�h
      ,item_no           xxcmn_item_mst2_v.item_no%TYPE              -- �i�ځi�R�[�h�j
      ,item_short_name   xxcmn_item_mst2_v.item_short_name%TYPE      -- �i�ځi���́j
      ,case_quant        xxcmn_item_mst2_v.num_of_cases%TYPE         -- ����
      ,quant             mrp_forecast_dates.attribute4%TYPE          -- ����
      ,amount            mrp_forecast_dates.attribute2%TYPE          -- ���z
      ,total_amount      xxpo_price_headers.total_amount%TYPE        -- ���󍇌v
      ,o_amount          xxcmn_item_mst2_v.old_price%TYPE            -- ���E�艿
      ,n_amount          xxcmn_item_mst2_v.new_price%TYPE            -- �V�E�艿
      ,price_st          xxcmn_item_mst2_v.price_start_date%TYPE     -- �艿�K�p�J�n��
    );
  TYPE tab_data_sale_plan IS TABLE OF rec_sale_plan INDEX BY BINARY_INTEGER;
--
  -- �̔��v��\���擾�f�[�^�i�[�p���R�[�h�ϐ�(���_�p)
  TYPE rec_sale_plan_1 IS RECORD 
    (
       skbn              xxcmn_item_categories2_v.segment1%TYPE      -- ���i�敪
      ,gun               xxcmn_item_categories2_v.segment1%TYPE      -- �Q�R�[�h
      ,item_no           xxcmn_item_mst2_v.item_no%TYPE              -- �i�ځi�R�[�h�j
      ,item_short_name   xxcmn_item_mst2_v.item_short_name%TYPE      -- �i�ځi���́j
      ,case_quant        xxcmn_item_mst2_v.num_of_cases%TYPE         -- ����
      ,quant             mrp_forecast_dates.attribute4%TYPE          -- ����
      ,amount            mrp_forecast_dates.attribute2%TYPE          -- ���z
      ,ktn_code          mrp_forecast_dates.attribute5%TYPE          -- ���_�R�[�h
      ,party_short_name  xxcmn_parties_v.party_short_name%TYPE       -- ���_����
      ,total_amount      xxpo_price_headers.total_amount%TYPE        -- ���󍇌v
      ,o_amount          xxcmn_item_mst2_v.old_price%TYPE            -- ���E�艿
      ,n_amount          xxcmn_item_mst2_v.new_price%TYPE            -- �V�E�艿
      ,price_st          xxcmn_item_mst2_v.price_start_date%TYPE     -- �艿�K�p�J�n��
    );
  TYPE tab_data_sale_plan_1 IS TABLE OF rec_sale_plan_1 INDEX BY BINARY_INTEGER;
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���萔
  -- ==================================================
  gv_pkg_name         CONSTANT VARCHAR2(20)  := 'XXINV100002C';           -- �p�b�P�[�W��
  gv_prf_start_day    CONSTANT VARCHAR2(30)  := 'XXCMN_PERIOD_START_DAY'; -- XXCMN:�N�x�J�n����
  gv_prf_prod         CONSTANT VARCHAR2(100) := 'XXCMN_ITEM_DIV';         -- XXCMN:���i�敪
  gv_prf_crowd        CONSTANT VARCHAR2(100) := 'XXCMN_CATEGORY_NAME_OTGUN';
                                                             -- XXCMN:�J�e�S���Z�b�g���i�Q�R�[�h�j
--2008.04.28 Y.Kawano add start
  gv_master_org_id    CONSTANT VARCHAR2(30)  := 'XXCMN_MASTER_ORG_ID';    --XXCMN:�}�X�^�g�DID
--2008.04.28 Y.Kawano add end
  gv_name_sale_plan   CONSTANT VARCHAR2(2)   := '05';        -- '�̔��v��'
  gv_output_unit_0    CONSTANT VARCHAR2(10)  := '�{��';      -- �o�͒P�� '0'
  gv_output_unit_1    CONSTANT VARCHAR2(10)  := '�P�[�X';    -- �o�͒P�� '1'
  gv_prod_div_leaf    CONSTANT VARCHAR2(1)   := '1';         -- '���[�t'
  gv_prod_div_drink   CONSTANT VARCHAR2(1)   := '2';         -- '�h�����N'
  gv_output_unit      CONSTANT VARCHAR2(1)   := '0';         -- '�{��'
  -- �r�p�k�쐬�p
  gv_sql_dot          CONSTANT VARCHAR2(3)   := ' , ';             -- �J���}','
  gv_sql_l_block      CONSTANT VARCHAR2(2)   := ' (';              -- ������'('
  gv_sql_r_block      CONSTANT VARCHAR2(2)   := ') ';              -- �E����')'
  -- ���[�\���p
  gv_report_id        CONSTANT VARCHAR2(12)  := 'XXINV100002T';    -- ���[ID
  gv_name_ktn         CONSTANT VARCHAR2(10)  := '�S���_';
  gv_name_year        CONSTANT VARCHAR2(10)  := '�N�x';
  gv_name_kotei       CONSTANT VARCHAR2(10)  := '70.00';           -- �Œ�l�i�|�����j
  -- �G���[�R�[�h
  gv_application      CONSTANT VARCHAR2(5)   := 'XXCMN';           -- �A�v���P�[�V����
  gv_err_code_no_data CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10122'; -- ���[�O�����b�Z�[�W
  gv_err_pro          CONSTANT VARCHAR2(20)  := 'APP-XXCMN-10002'; 
                                                     -- �v���t�@�C���擾�G���[���b�Z�[�W
--
  gv_tkn_pro          CONSTANT VARCHAR2(15)  := 'PROFILE';         -- �v���t�@�C����
--
  gn_0                NUMBER                 := 0;                 -- 0
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_start_day          DATE;              -- �N�x�J�n����
  gv_name_prod          VARCHAR2(10);      -- ���i�敪
  gv_name_crowd         VARCHAR2(10);      -- �Q�R�[�h
--2008.04.28 Y.Kawano add start
  gn_org_id             NUMBER;            -- �}�X�^�g�DID
--2008.04.28 Y.Kawano add end
-- �r�p�k�쐬�p
-- 2009/04/13 v1.7 T.Yoshimoto Mod Start �C�����̃R�����g�����ɂ��o�b�t�@�I�[�o�[����
  --gv_sql_sel            VARCHAR2(9000);    -- SQL�g�����p
  gv_sql_sel            VARCHAR2(20000);    -- SQL�g�����p
  --gv_sql_select         VARCHAR2(2000);    -- SELECT��
  gv_sql_select         VARCHAR2(5000);    -- SELECT��
-- 2009/04/13 v1.7 T.Yoshimoto Mod End �C�����̃R�����g�����ɂ��o�b�t�@�I�[�o�[����
  gv_sql_from           VARCHAR2(1000);    -- FROM��
  gv_sql_where          VARCHAR2(6000);    -- WHERE��
  gv_sql_order_by       VARCHAR2(1000);    -- ORDER BY��
--2008.04.28 Y.Kawano add start
  gv_sql_group_by       VARCHAR2(1000);    -- GROUP BY��
--2008.04.28 Y.Kawano add end
  gv_sql_prod_div       VARCHAR2(1000);    -- ���i�敪(���͂o�L)
  gv_sql_prod_div_n     VARCHAR2(1000);    -- ���i�敪(���͂o��)
  gv_sql_crowd_code     VARCHAR2(5000);    -- �Q�R�[�h(���͂o�L)
-- �Q�R�[�h���͂o�p
  gv_sql_crowd_code_01  VARCHAR2(50);      -- �Q�R�[�h�P
  gv_sql_crowd_code_02  VARCHAR2(50);      -- �Q�R�[�h�Q
  gv_sql_crowd_code_03  VARCHAR2(50);      -- �Q�R�[�h�R
  gv_sql_crowd_code_04  VARCHAR2(50);      -- �Q�R�[�h�S
  gv_sql_crowd_code_05  VARCHAR2(50);      -- �Q�R�[�h�T
  gv_sql_crowd_code_06  VARCHAR2(50);      -- �Q�R�[�h�U
  gv_sql_crowd_code_07  VARCHAR2(50);      -- �Q�R�[�h�V
  gv_sql_crowd_code_08  VARCHAR2(50);      -- �Q�R�[�h�W
  gv_sql_crowd_code_09  VARCHAR2(50);      -- �Q�R�[�h�X
  gv_sql_crowd_code_10  VARCHAR2(50);      -- �Q�R�[�h�P�O
--
  gl_xml_idx            NUMBER;               -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
  gt_xml_data_table     XML_DATA;             -- �w�l�k�f�[�^�^�O�\
  gr_param              rec_param_data ;      -- ���̓p�����[�^
  gr_sale_plan          tab_data_sale_plan;   -- �̔��v��\����̃p�����[�^(�S���_)
  gr_sale_plan_1        tab_data_sale_plan_1; -- �̔��v��\����̃p�����[�^(���_)
  -- 2008/04/28 add
  gv_price_type       CONSTANT VARCHAR2(1)   := '2';                      -- �}�X�^�敪 2:�W��
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
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
--###########################  �Œ蕔 END   ############################
--
  /**********************************************************************************
   * Procedure Name   : pro_get_cus_option
   * Description      : �J�X�^���I�v�V�����擾  (B-1-0)
   ***********************************************************************************/
  PROCEDURE pro_get_cus_option
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_cus_option'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_start_day    VARCHAR2(10);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �v���t�@�C������N�x�J�n�����擾
    lv_start_day := SUBSTRB(FND_PROFILE.VALUE(gv_prf_start_day),1,5);
    -- �擾�G���[��
    IF (lv_start_day IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXCMN'
                                                    ,gv_err_pro         -- �v���t�@�C���擾�G���[
                                                    ,gv_tkn_pro         -- �g�[�N��'PROFILE'
                                                    ,gv_prf_start_day)  -- XXCMN:�N�x�J�n����
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- ���͂o�u�N�x�v�{�v���t�@�C������擾�����N�x�J�n���� �쐬
    lv_start_day := gr_param.year ||'/'|| lv_start_day;
--
    gd_start_day := FND_DATE.STRING_TO_DATE(lv_start_day,'YYYY/MM/DD');
--
    -- �v���t�@�C�����珤�i�敪�擾
    gv_name_prod := SUBSTRB(FND_PROFILE.VALUE(gv_prf_prod),1,10);
    -- �擾�G���[��
    IF (gv_name_prod IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application   -- 'XXCMN'
                                                    ,gv_err_pro       -- �v���t�@�C���擾�G���[
                                                    ,gv_tkn_pro       -- �g�[�N��'PROFILE'
                                                    ,gv_prf_prod)     -- XXCMN:���i�敪
                                                  ,1
                                                  ,5000);
      RAISE global_api_expt;
    END IF;
    -- �v���t�@�C������Q�R�[�h�擾
    gv_name_crowd := SUBSTRB(FND_PROFILE.VALUE(gv_prf_crowd),1,10);
    -- �擾�G���[��
    IF (gv_name_crowd IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application    -- 'XXCMN'
                                                    ,gv_err_pro        -- �v���t�@�C���擾�G���[
                                                    ,gv_tkn_pro        -- �g�[�N��'PROFILE'
                                                    ,gv_prf_crowd)
                                                           -- XXCMN:�J�e�S���Z�b�g���i�Q�R�[�h�j
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
--2008.04.28 Y.Kawano add start
    -- �v���t�@�C������XXCMN:�}�X�^�g�DID�擾
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(gv_master_org_id));
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application    -- 'XXCMN'
                                                    ,gv_err_pro        -- �v���t�@�C���擾�G���[
                                                    ,gv_tkn_pro        -- �g�[�N��'PROFILE'
                                                    ,gv_master_org_id) -- XXCMN:�}�X�^�g�DID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--2008.04.28 Y.Kawano add end
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_get_cus_option;
--
  /**********************************************************************************
   * Procedure Name   : prc_sale_plan
   * Description      : �f�[�^���o - �̔��v��\��񒊏o(�S���_��) (B-1-1-1)
   ***********************************************************************************/
  PROCEDURE prc_sale_plan
    (
      ot_sale_plan  OUT NOCOPY tab_data_sale_plan  --  �擾���R�[�h�Q
     ,ov_errbuf     OUT VARCHAR2                   --  �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                   --  ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                   --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_sale_plan'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- SELECT��
    gv_sql_select := 'SELECT xicv1.segment1         AS skbn         -- ���i�敪
                            ,xicv.segment1          AS gun          -- �Q�R�[�h
                            ,ximv.item_no                           -- �i�ځi�R�[�h�j
                            ,ximv.item_short_name                   -- �i�ځi���́j
--2008.04.28 Y.Kawano modify start
--                            ,ximv.num_of_cases      AS case_quant   -- ����
--                            ,mfd.attribute4         AS quant        -- ����
--                            ,mfd.attribute2         AS amount       -- ���z
--                            ,xph.total_amount                       -- ���󍇌v
--                            ,ximv.old_price         AS o_amount     -- ���E�艿
--                            ,ximv.new_price         AS n_amount     -- �V�E�艿
-- 2009/03/23 v1.6 H.Iida Mod Start �����e�X�g�w�E311
--                            ,SUM(ximv.num_of_cases) AS case_quant   -- ����
                            ,ximv.num_of_cases      AS case_quant   -- ����
-- 2009/03/23 v1.6 H.Iida Mod End
                            ,SUM(mfd.attribute4)    AS quant        -- ����
                            ,SUM(mfd.attribute2)    AS amount       -- ���z
-- 2009/04/13 v1.7 T.Yoshimoto Mod Start �{��#1409
                            --,SUM(xph.total_amount)                  -- ���󍇌v
                            --,SUM(ximv.old_price)    AS o_amount     -- ���E�艿
                            --,SUM(ximv.new_price)    AS n_amount     -- �V�E�艿
                            ,xph.total_amount                       -- ���󍇌v
                            ,ximv.old_price         AS o_amount     -- ���E�艿
                            ,ximv.new_price         AS n_amount     -- �V�E�艿
-- 2009/04/13 v1.7 T.Yoshimoto Mod End �{��#1409
--2008.04.28 Y.Kawano modify end
                            ,ximv.price_start_date  AS price_st     -- �艿�K�p�J�n��
                            ';
--
    -- FROM��
    gv_sql_from := ' FROM mrp_forecast_designators  mfds    -- Forecast��
                         ,mrp_forecast_dates        mfd     -- Forecast���t
                         ,xxpo_price_headers        xph     -- �d��/�W���P���w�b�_(�A�h�I��)
                         ,xxcmn_item_categories2_v  xicv    -- OPM�i�ڃJ�e�S���������VIEW
                         ,xxcmn_item_categories2_v  xicv1   -- OPM�i�ڃJ�e�S���������VIEW(���i�敪)
                         ,xxcmn_item_mst2_v         ximv    -- OPM�i�ڏ��VIEW
                         ';
--
    -- WHERE��
    gv_sql_where := ' WHERE mfds.attribute1          = :para_name_sale_plan      -- �̔��v��
                      AND   mfds.attribute5          = :para_gen                 -- ���͂o ����
                      AND   mfds.attribute6          = :param_year               -- ���͂o �N�x
                      AND   mfds.forecast_designator = mfd.forecast_designator   -- Forecast��
--2008.04.28 Y.Kawano add start
                      AND   mfds.organization_id     = mfd.organization_id
                      AND   mfds.organization_id     = ''' || gn_org_id || '''   -- �g�DID
                      AND   mfd.organization_id      = ''' || gn_org_id || '''   -- �g�DID
--2008.04.28 Y.Kawano add start
                      AND   xicv1.category_set_name  = :para_name_prod           -- ���i�敪
                      AND   mfd.inventory_item_id    = ximv.inventory_item_id    -- �i��ID
                      AND   ximv.item_no             = xicv1.item_no
                      AND   ximv.start_date_active  <= :para_start_day           -- �K�p�J�n��  
                      AND   ximv.end_date_active    >= :para_start_day           -- �K�p�I����
                      AND   xicv.item_no             = ximv.item_no
                      AND   xicv.category_set_name   = :para_name_crowd          -- �Q�R�[�h
                      AND   xph.item_id              = ximv.item_id
                      -- 2008/04/28 add start
                      AND   xph.price_type           = :para_price_type          -- �}�X�^�敪
                      -- 2008/04/28 add end 
                      AND   xph.start_date_active   <= :para_start_day           -- �K�p�J�n��
                      AND   xph.end_date_active     >= :para_start_day           -- �K�p�I����
                      ';
--
    -- ���i�敪���o���� (���͂o ���͗L)
    gv_sql_prod_div   := ' AND xicv1.segment1 = ''' || gr_param.prod_div || '''
                         ';
    -- ���i�敪���o���� (���͂o NULL)
    gv_sql_prod_div_n := ' AND xicv1.segment1 IN (''' || gv_prod_div_leaf  || '''
                                                    ' || gv_sql_dot        || '
                                                  ''' || gv_prod_div_drink || ''') -- 1,2�̗������o
                         ';
--
    -- �Q�R�[�h���o���� (1���10�̓��̓p�����[�^)
    gv_sql_crowd_code    := ' AND xicv.segment1 IN ';
    gv_sql_crowd_code_01 := '''' || gr_param.crowd_code_01 || '''';
    gv_sql_crowd_code_02 := '''' || gr_param.crowd_code_02 || '''';
    gv_sql_crowd_code_03 := '''' || gr_param.crowd_code_03 || '''';
    gv_sql_crowd_code_04 := '''' || gr_param.crowd_code_04 || '''';
    gv_sql_crowd_code_05 := '''' || gr_param.crowd_code_05 || '''';
    gv_sql_crowd_code_06 := '''' || gr_param.crowd_code_06 || '''';
    gv_sql_crowd_code_07 := '''' || gr_param.crowd_code_07 || '''';
    gv_sql_crowd_code_08 := '''' || gr_param.crowd_code_08 || '''';
    gv_sql_crowd_code_09 := '''' || gr_param.crowd_code_09 || '''';
    gv_sql_crowd_code_10 := '''' || gr_param.crowd_code_10 || '''';
--
--2008.04.28 Y.Kawano add start
    -- GROUP BY��
    gv_sql_group_by      := ' GROUP BY xicv1.segment1     -- ���i�敪
                                      ,xicv.segment1      -- �Q�R�[�h
                                      ,ximv.item_no       -- �i��
-- 2009/03/23 v1.6 H.Iida Add Start �����e�X�g�w�E311
                                      ,ximv.num_of_cases  -- ����
-- 2009/03/23 v1.6 H.Iida Add End
-- 2009/04/13 v1.7 T.Yoshimoto Mod Start �{��#1409
                                      ,xph.total_amount   -- ���󍇌v
                                      ,ximv.old_price     -- ���E�艿
                                      ,ximv.new_price     -- �V�E�艿
-- 2009/04/13 v1.7 T.Yoshimoto Mod End �{��#1409
                                      ,ximv.item_short_name
                                      ,ximv.price_start_date';

--2008.04.28 Y.Kawano add end
--
    -- ORDER BY��
    gv_sql_order_by      := ' ORDER BY xicv1.segment1   -- ���i�敪
                                      ,xicv.segment1    -- �Q�R�[�h
                                      ,ximv.item_no';   -- �i��
--
    -------------------------------------------------------------
    -- �f�[�^���o�pSQL�쐬
    -------------------------------------------------------------
    gv_sql_sel := '';
    gv_sql_sel := gv_sql_sel || gv_sql_select;  -- SELECT�匋��
    gv_sql_sel := gv_sql_sel || gv_sql_from;    -- FROM�匋��
    gv_sql_sel := gv_sql_sel || gv_sql_where;   -- WHERE�匋��
--
    -- ���͂o�u���i�敪�vNULL����
    IF (gr_param.prod_div IS NOT NULL) THEN
      -- �쐬�r�p�k���ɏ��i�敪���o���� (���͂o ���͗L)����
      gv_sql_sel := gv_sql_sel || gv_sql_prod_div;
    ELSE
      -- �쐬�r�p�k���ɏ��i�敪���o���� (���͂o NULL)����
      gv_sql_sel := gv_sql_sel || gv_sql_prod_div_n;
    END IF;
--
    -- ���͂o�u�Q�R�[�h�P����P�O�v�ɓ��͗L�̏ꍇ
    IF (gr_param.crowd_code_01 IS NOT NULL)
      OR (gr_param.crowd_code_02 IS NOT NULL)
        OR (gr_param.crowd_code_03 IS NOT NULL)
          OR (gr_param.crowd_code_04 IS NOT NULL)
            OR (gr_param.crowd_code_05 IS NOT NULL)
              OR (gr_param.crowd_code_06 IS NOT NULL)
                OR (gr_param.crowd_code_07 IS NOT NULL)
                  OR (gr_param.crowd_code_08 IS NOT NULL)
                    OR (gr_param.crowd_code_09 IS NOT NULL)
                      OR (gr_param.crowd_code_10 IS NOT NULL)THEN
      -- �Q�R�[�h���o���� + ������
      gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_l_block;
      -- ���͂o �Q�R�[�h�P�ɓ��͗L
      IF (gr_param.crowd_code_01 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_01;
      END IF;
      -- ���͂o �Q�R�[�h�Q�ɓ��͗L
      IF (gr_param.crowd_code_02 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_02;
      ELSIF (gr_param.crowd_code_02 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_02;
      END IF;
      -- ���͂o �Q�R�[�h�R�ɓ��͗L
      IF (gr_param.crowd_code_03 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_03;
      ELSIF (gr_param.crowd_code_03 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_03;
      END IF;
      -- ���͂o �Q�R�[�h�S�ɓ��͗L
      IF (gr_param.crowd_code_04 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_04;
      ELSIF (gr_param.crowd_code_04 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_04;
      END IF;
      -- ���͂o �Q�R�[�h�T�ɓ��͗L
      IF (gr_param.crowd_code_05 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_05;
      ELSIF (gr_param.crowd_code_05 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_05;
      END IF;
      -- ���͂o �Q�R�[�h�U�ɓ��͗L
      IF (gr_param.crowd_code_06 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_06;
      ELSIF (gr_param.crowd_code_06 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_06;
      END IF;
      -- ���͂o �Q�R�[�h�V�ɓ��͗L
      IF (gr_param.crowd_code_07 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_07;
      ELSIF (gr_param.crowd_code_07 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_07;
      END IF;
      -- ���͂o �Q�R�[�h�W�ɓ��͗L
      IF (gr_param.crowd_code_08 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)
                    AND (gr_param.crowd_code_07 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_08;
      ELSIF (gr_param.crowd_code_08 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_08;
      END IF;
      -- ���͂o �Q�R�[�h�X�ɓ��͗L
      IF (gr_param.crowd_code_09 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)
                    AND (gr_param.crowd_code_07 IS NULL)
                      AND (gr_param.crowd_code_08 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_09;
      ELSIF (gr_param.crowd_code_09 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_09;
      END IF;
      -- ���͂o �Q�R�[�h�P�O�ɓ��͗L
      IF (gr_param.crowd_code_10 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)
                    AND (gr_param.crowd_code_07 IS NULL)
                      AND (gr_param.crowd_code_08 IS NULL)
                        AND (gr_param.crowd_code_09 IS NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_10;
      ELSIF (gr_param.crowd_code_10 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_10;
      END IF;
      --  �Q�R�[�h���o���� + �E����
      gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_r_block;
      -- �쐬�r�p�k���ɌQ�R�[�h���o��������
      gv_sql_sel        := gv_sql_sel || gv_sql_crowd_code;
    END IF;
--
--2008.04.28 Y.Kawano modify start
    -- GROUP BY�匋��
    gv_sql_sel := gv_sql_sel || gv_sql_group_by;
--2008.04.28 Y.Kawano add end
--
    -- ORDER BY�匋��
    gv_sql_sel := gv_sql_sel || gv_sql_order_by;
--
    -- �쐬�r�p�k�����s
    EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO ot_sale_plan USING gv_name_sale_plan
                                                                      ,gr_param.gen
                                                                      ,gr_param.year
                                                                      ,gv_name_prod
                                                                      ,gd_start_day
                                                                      ,gd_start_day
                                                                      ,gv_name_crowd
                                                                      ,gv_price_type  -- add 2008/04/28
                                                                      ,gd_start_day
                                                                      ,gd_start_day 
                                                                      ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_sale_plan;
--
  /**********************************************************************************
   * Procedure Name   : prc_sale_plan_1
   * Description      : �f�[�^���o - �̔��v��\��񒊏o(���_��) (B-1-1-2)
   ***********************************************************************************/
  PROCEDURE prc_sale_plan_1
    (
      ot_sale_plan_1  OUT NOCOPY tab_data_sale_plan_1  --  �擾���R�[�h�Q
     ,ov_errbuf       OUT VARCHAR2                     --  �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      OUT VARCHAR2                     --  ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       OUT VARCHAR2                     --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_sale_plan_1'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    -- �r�p�k�쐬�p
    lv_sql_base       VARCHAR2(5000);    -- ���_(���͂o�L)
    -- ���_���͂o�p
    lv_sql_base_01    VARCHAR2(100);     -- ���_�P
    lv_sql_base_02    VARCHAR2(100);     -- ���_�Q
    lv_sql_base_03    VARCHAR2(100);     -- ���_�R
    lv_sql_base_04    VARCHAR2(100);     -- ���_�S
    lv_sql_base_05    VARCHAR2(100);     -- ���_�T
    lv_sql_base_06    VARCHAR2(100);     -- ���_�U
    lv_sql_base_07    VARCHAR2(100);     -- ���_�V
    lv_sql_base_08    VARCHAR2(100);     -- ���_�W
    lv_sql_base_09    VARCHAR2(100);     -- ���_�X
    lv_sql_base_10    VARCHAR2(100);     -- ���_�P�O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- SELECT��
    gv_sql_select := 'SELECT xicv1.segment1         AS skbn         -- ���i�敪
                            ,xicv.segment1          AS gun          -- �Q�R�[�h
                            ,ximv.item_no                           -- �i�ځi�R�[�h�j
                            ,ximv.item_short_name                   -- �i�ځi���́j
--2008.04.28 Y.Kawano modify start
--                            ,ximv.num_of_cases      AS case_quant   -- ����
--                            ,mfd.attribute4         AS quant        -- ����
--                            ,mfd.attribute2         AS amount       -- ���z
-- 2009/03/23 v1.6 H.Iida Mod Start �����e�X�g�w�E311
--                            ,SUM(ximv.num_of_cases) AS case_quant   -- ����
                            ,ximv.num_of_cases      AS case_quant   -- ����
-- 2009/03/23 v1.6 H.Iida Mod End
                            ,SUM(mfd.attribute4)    AS quant        -- ����
                            ,SUM(mfd.attribute2)    AS amount       -- ���z
--2008.04.28 Y.Kawano modify end
                            ,mfd.attribute5         AS ktn_code     -- ���_�R�[�h
                            ,xpv.party_short_name                   -- ���_��
--2008.04.28 Y.Kawano modify start
--                            ,xph.total_amount                       -- ���󍇌v
--                            ,ximv.old_price         AS o_amount     -- ���E�艿
--                            ,ximv.new_price         AS n_amount     -- �V�E�艿
-- 2009/04/13 v1.7 T.Yoshimoto Mod Start �{��#1409
                            --,SUM(xph.total_amount)                  -- ���󍇌v
                            --,SUM(ximv.old_price)    AS o_amount     -- ���E�艿
                            --,SUM(ximv.new_price)    AS n_amount     -- �V�E�艿
                            ,xph.total_amount                       -- ���󍇌v
                            ,ximv.old_price         AS o_amount     -- ���E�艿
                            ,ximv.new_price         AS n_amount     -- �V�E�艿
-- 2009/04/13 v1.7 T.Yoshimoto Mod End �{��#1409
--2008.04.28 Y.Kawano modify end
                            ,ximv.price_start_date  AS price_st     -- �艿�K�p�J�n��
                            ';
--
    -- FROM��
    gv_sql_from := ' FROM mrp_forecast_designators  mfds    -- Forecast��
                         ,mrp_forecast_dates        mfd     -- Forecast���t
                         ,xxpo_price_headers        xph     -- �d��/�W���P���w�b�_(�A�h�I��)
                         ,xxcmn_item_categories2_v  xicv    -- OPM�i�ڃJ�e�S���������VIEW
                         ,xxcmn_item_categories2_v  xicv1   -- OPM�i�ڃJ�e�S���������VIEW(���i�敪)
                         ,xxcmn_item_mst2_v         ximv    -- OPM�i�ڏ��VIEW
                         ,xxcmn_parties_v           xpv     -- �p�[�e�B���VIEW
                         ';
--
    -- WHERE��
    gv_sql_where := ' WHERE mfds.attribute1          = :para_name_sale_plan      -- �̔��v��
                      AND   mfds.attribute5          = :para_gen                 -- ���͂o ����
                      AND   mfds.attribute6          = :param_year               -- ���͂o �N�x
                      AND   mfds.forecast_designator = mfd.forecast_designator   -- Forecast��
--2008.04.28 Y.Kawano add start
                      AND   mfds.organization_id     = mfd.organization_id
                      AND   mfds.organization_id     = ''' || gn_org_id || '''   -- �g�DID
                      AND   mfd.organization_id      = ''' || gn_org_id || '''   -- �g�DID
--2008.04.28 Y.Kawano add start
                      AND   xicv1.category_set_name  = :para_name_prod           -- ���i�敪
                      AND   mfd.inventory_item_id    = ximv.inventory_item_id    -- �i��ID
                      AND   ximv.item_no             = xicv1.item_no
                      AND   ximv.start_date_active  <= :para_start_day           -- �K�p�J�n��  
                      AND   ximv.end_date_active    >= :para_start_day           -- �K�p�I����
                      AND   xicv.item_no             = ximv.item_no
                      AND   xicv.category_set_name   = :para_name_crowd          -- �Q�R�[�h
                      AND   xph.item_id              = ximv.item_id
                      -- 2008/04/28 add start
                      AND   xph.price_type           = :para_price_type          -- �}�X�^�敪
                      -- 2008/04/28 add end 
                      AND   xph.start_date_active   <= :para_start_day           -- �K�p�J�n��
                      AND   xph.end_date_active     >= :para_start_day           -- �K�p�I����
                      AND   mfd.attribute5           = xpv.account_number        -- �ڋq�ԍ�
                      ';
--
    -- ���i�敪���o���� (���͂o ���͗L)
    gv_sql_prod_div   := ' AND xicv1.segment1 =''' || gr_param.prod_div || '''
                         ';
    -- ���i�敪���o���� (���͂o NULL)
    gv_sql_prod_div_n := ' AND xicv1.segment1 IN (''' || gv_prod_div_leaf  || '''
                                                    ' || gv_sql_dot        || '
                                                  ''' || gv_prod_div_drink || ''') -- 1,2�̗������o
                         ';
--
    -- ���_���o���� (1���10�̓��̓p�����[�^)
    lv_sql_base    := ' AND mfd.attribute5 IN ';
    lv_sql_base_01 := '''' || gr_param.base_01 || '''';
    lv_sql_base_02 := '''' || gr_param.base_02 || '''';
    lv_sql_base_03 := '''' || gr_param.base_03 || '''';
    lv_sql_base_04 := '''' || gr_param.base_04 || '''';
    lv_sql_base_05 := '''' || gr_param.base_05 || '''';
    lv_sql_base_06 := '''' || gr_param.base_06 || '''';
    lv_sql_base_07 := '''' || gr_param.base_07 || '''';
    lv_sql_base_08 := '''' || gr_param.base_08 || '''';
    lv_sql_base_09 := '''' || gr_param.base_09 || '''';
    lv_sql_base_10 := '''' || gr_param.base_10 || '''';
--
    -- �Q�R�[�h���o���� (1���10�̓��̓p�����[�^)
    gv_sql_crowd_code    := ' AND xicv.segment1 IN ';
    gv_sql_crowd_code_01 := '''' || gr_param.crowd_code_01 || '''';
    gv_sql_crowd_code_02 := '''' || gr_param.crowd_code_02 || '''';
    gv_sql_crowd_code_03 := '''' || gr_param.crowd_code_03 || '''';
    gv_sql_crowd_code_04 := '''' || gr_param.crowd_code_04 || '''';
    gv_sql_crowd_code_05 := '''' || gr_param.crowd_code_05 || '''';
    gv_sql_crowd_code_06 := '''' || gr_param.crowd_code_06 || '''';
    gv_sql_crowd_code_07 := '''' || gr_param.crowd_code_07 || '''';
    gv_sql_crowd_code_08 := '''' || gr_param.crowd_code_08 || '''';
    gv_sql_crowd_code_09 := '''' || gr_param.crowd_code_09 || '''';
    gv_sql_crowd_code_10 := '''' || gr_param.crowd_code_10 || '''';
--
--2008.04.28 Y.Kawano add start
    -- GROUP BY��
    gv_sql_group_by      := ' GROUP BY xicv1.segment1     -- ���i�敪
                                      ,mfd.attribute5
                                      ,xicv.segment1      -- �Q�R�[�h
                                      ,ximv.item_no       -- �i��
-- 2009/03/23 v1.6 H.Iida Add Start �����e�X�g�w�E311
                                      ,ximv.num_of_cases  -- ����
-- 2009/03/23 v1.6 H.Iida Add End
-- 2009/04/13 v1.7 T.Yoshimoto Mod Start �{��#1409
                                      ,xph.total_amount   -- ���󍇌v
                                      ,ximv.old_price     -- ���E�艿
                                      ,ximv.new_price     -- �V�E�艿
-- 2009/04/13 v1.7 T.Yoshimoto Mod End �{��#1409
                                      ,xpv.party_short_name 
                                      ,ximv.item_short_name
                                      ,ximv.price_start_date';

--2008.04.28 Y.Kawano add end
--
    -- ORDER BY��
    gv_sql_order_by      := ' ORDER BY xicv1.segment1   -- ���i�敪
                                      ,mfd.attribute5   -- ���_
                                      ,xicv.segment1    -- �Q�R�[�h
                                      ,ximv.item_no';   -- �i��
--
    -------------------------------------------------------------
    -- �f�[�^���o�pSQL�쐬
    -------------------------------------------------------------
    gv_sql_sel := '';
    gv_sql_sel := gv_sql_sel || gv_sql_select;  -- SELECT�匋��
    gv_sql_sel := gv_sql_sel || gv_sql_from;    -- FROM�匋��
    gv_sql_sel := gv_sql_sel || gv_sql_where;   -- WHERE�匋��
--
    -- ���͂o�u���i�敪�vNULL����
    IF (gr_param.prod_div IS NOT NULL) THEN
      -- �쐬�r�p�k���ɏ��i�敪���o���� (���͂o ���͗L)����
      gv_sql_sel := gv_sql_sel || gv_sql_prod_div;
    ELSE
      -- �쐬�r�p�k���ɏ��i�敪���o���� (���͂o NULL)����
      gv_sql_sel := gv_sql_sel || gv_sql_prod_div_n;
    END IF;
--
    -- ���͂o�u���_�P����P�O�v�ɓ��͗L�̏ꍇ
    IF (gr_param.base_01 IS NOT NULL)
      OR (gr_param.base_02 IS NOT NULL)
        OR (gr_param.base_03 IS NOT NULL)
          OR (gr_param.base_04 IS NOT NULL)
            OR (gr_param.base_05 IS NOT NULL)
              OR (gr_param.base_06 IS NOT NULL)
                OR (gr_param.base_07 IS NOT NULL)
                  OR (gr_param.base_08 IS NOT NULL)
                    OR (gr_param.base_09 IS NOT NULL)
                      OR (gr_param.base_10 IS NOT NULL)THEN
      -- ���_���o���� + ������
      lv_sql_base   := lv_sql_base || gv_sql_l_block;
      -- ���͂o ���_�P�ɓ��͗L
      IF (gr_param.base_01 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_01;
      END IF;
      -- ���͂o ���_�Q�ɓ��͗L
      IF (gr_param.base_02 IS NOT NULL)
        AND (gr_param.base_01 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_02;
      ELSIF (gr_param.base_02 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_02;
      END IF;
      -- ���͂o ���_�R�ɓ��͗L
      IF (gr_param.base_03 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_03;
      ELSIF (gr_param.base_03 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_03;
      END IF;
      -- ���͂o ���_�S�ɓ��͗L
      IF (gr_param.base_04 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_04;
      ELSIF (gr_param.base_04 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_04;
      END IF;
      -- ���͂o ���_�T�ɓ��͗L
      IF (gr_param.base_05 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_05;
      ELSIF (gr_param.base_05 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_05;
      END IF;
      -- ���͂o ���_�U�ɓ��͗L
      IF (gr_param.base_06 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_06;
      ELSIF (gr_param.base_06 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_06;
      END IF;
      -- ���͂o ���_�V�ɓ��͗L
      IF (gr_param.base_07 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_07;
      ELSIF (gr_param.base_07 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_07;
      END IF;
      -- ���͂o ���_�W�ɓ��͗L
      IF (gr_param.base_08 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)
                    AND (gr_param.base_07 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_08;
      ELSIF (gr_param.base_08 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_08;
      END IF;
      -- ���͂o ���_�X�ɓ��͗L
      IF (gr_param.base_09 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)
                    AND (gr_param.base_07 IS NULL)
                      AND (gr_param.base_08 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_09;
      ELSIF (gr_param.base_09 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_09;
      END IF;
      -- ���͂o ���_�P�O�ɓ��͗L
      IF (gr_param.base_10 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)
                    AND (gr_param.base_07 IS NULL)
                      AND (gr_param.base_08 IS NULL)
                        AND (gr_param.base_09 IS NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_10;
      ELSIF (gr_param.base_10 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_10;
      END IF;
      --  ���_���o���� + �E����
      lv_sql_base   := lv_sql_base || gv_sql_r_block;
      -- �쐬�r�p�k���ɋ��_���o��������
      gv_sql_sel    := gv_sql_sel || lv_sql_base;
--
      -- ���͂o�u�Q�R�[�h�P����P�O�v�ɓ��͗L�̏ꍇ
      IF (gr_param.crowd_code_01 IS NOT NULL)
        OR (gr_param.crowd_code_02 IS NOT NULL)
          OR (gr_param.crowd_code_03 IS NOT NULL)
            OR (gr_param.crowd_code_04 IS NOT NULL)
              OR (gr_param.crowd_code_05 IS NOT NULL)
                OR (gr_param.crowd_code_06 IS NOT NULL)
                  OR (gr_param.crowd_code_07 IS NOT NULL)
                    OR (gr_param.crowd_code_08 IS NOT NULL)
                      OR (gr_param.crowd_code_09 IS NOT NULL)
                        OR (gr_param.crowd_code_10 IS NOT NULL)THEN
        -- �Q�R�[�h���o���� + ������
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_l_block;
        -- ���͂o �Q�R�[�h�P�ɓ��͗L
        IF (gr_param.crowd_code_01 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_01;
        END IF;
        -- ���͂o �Q�R�[�h�Q�ɓ��͗L
        IF (gr_param.crowd_code_02 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_02;
        ELSIF (gr_param.crowd_code_02 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_02;
        END IF;
        -- ���͂o �Q�R�[�h�R�ɓ��͗L
        IF (gr_param.crowd_code_03 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_03;
        ELSIF (gr_param.crowd_code_03 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_03;
        END IF;
        -- ���͂o �Q�R�[�h�S�ɓ��͗L
        IF (gr_param.crowd_code_04 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_04;
        ELSIF (gr_param.crowd_code_04 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_04;
        END IF;
        -- ���͂o �Q�R�[�h�T�ɓ��͗L
        IF (gr_param.crowd_code_05 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_05;
        ELSIF (gr_param.crowd_code_05 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_05;
        END IF;
        -- ���͂o �Q�R�[�h�U�ɓ��͗L
        IF (gr_param.crowd_code_06 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_06;
        ELSIF (gr_param.crowd_code_06 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_06;
        END IF;
        -- ���͂o �Q�R�[�h�V�ɓ��͗L
        IF (gr_param.crowd_code_07 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_07;
        ELSIF (gr_param.crowd_code_07 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_07;
        END IF;
        -- ���͂o �Q�R�[�h�W�ɓ��͗L
        IF (gr_param.crowd_code_08 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_08;
        ELSIF (gr_param.crowd_code_08 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_08;
        END IF;
        -- ���͂o �Q�R�[�h�X�ɓ��͗L
        IF (gr_param.crowd_code_09 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_09;
        ELSIF (gr_param.crowd_code_09 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_09;
        END IF;
        -- ���͂o �Q�R�[�h�P�O�ɓ��͗L
        IF (gr_param.crowd_code_10 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL)
                          AND (gr_param.crowd_code_09 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_10;
        ELSIF (gr_param.crowd_code_10 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_10;
        END IF;
        --  �Q�R�[�h���o���� + �E����
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_r_block;
        -- �쐬�r�p�k���ɌQ�R�[�h���o��������
        gv_sql_sel        := gv_sql_sel || gv_sql_crowd_code;
      END IF;
    ELSE
    -- ���͂o�u���_�P����P�O�v�ɓ��͖��̏ꍇ
--
      -- ���͂o�u�Q�R�[�h�P����P�O�v�ɓ��͗L�̏ꍇ
      IF (gr_param.crowd_code_01 IS NOT NULL)
        OR (gr_param.crowd_code_02 IS NOT NULL)
          OR (gr_param.crowd_code_03 IS NOT NULL)
            OR (gr_param.crowd_code_04 IS NOT NULL)
              OR (gr_param.crowd_code_05 IS NOT NULL)
                OR (gr_param.crowd_code_06 IS NOT NULL)
                  OR (gr_param.crowd_code_07 IS NOT NULL)
                    OR (gr_param.crowd_code_08 IS NOT NULL)
                      OR (gr_param.crowd_code_09 IS NOT NULL)
                        OR (gr_param.crowd_code_10 IS NOT NULL)THEN
        -- �Q�R�[�h���o���� + ������
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_l_block;
        -- ���͂o �Q�R�[�h�P�ɓ��͗L
        IF (gr_param.crowd_code_01 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_01;
        END IF;
        -- ���͂o �Q�R�[�h�Q�ɓ��͗L
        IF (gr_param.crowd_code_02 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_02;
        ELSIF (gr_param.crowd_code_02 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_02;
        END IF;
        -- ���͂o �Q�R�[�h�R�ɓ��͗L
        IF (gr_param.crowd_code_03 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_03;
        ELSIF (gr_param.crowd_code_03 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_03;
        END IF;
        -- ���͂o �Q�R�[�h�S�ɓ��͗L
        IF (gr_param.crowd_code_04 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_04;
        ELSIF (gr_param.crowd_code_04 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_04;
        END IF;
        -- ���͂o �Q�R�[�h�T�ɓ��͗L
        IF (gr_param.crowd_code_05 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_05;
        ELSIF (gr_param.crowd_code_05 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_05;
        END IF;
        -- ���͂o �Q�R�[�h�U�ɓ��͗L
        IF (gr_param.crowd_code_06 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_06;
        ELSIF (gr_param.crowd_code_06 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_06;
        END IF;
        -- ���͂o �Q�R�[�h�V�ɓ��͗L
        IF (gr_param.crowd_code_07 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_07;
        ELSIF (gr_param.crowd_code_07 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_07;
        END IF;
        -- ���͂o �Q�R�[�h�W�ɓ��͗L
        IF (gr_param.crowd_code_08 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_08;
        ELSIF (gr_param.crowd_code_08 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_08;
        END IF;
        -- ���͂o �Q�R�[�h�X�ɓ��͗L
        IF (gr_param.crowd_code_09 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_09;
        ELSIF (gr_param.crowd_code_09 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_09;
        END IF;
        -- ���͂o �Q�R�[�h�P�O�ɓ��͗L
        IF (gr_param.crowd_code_10 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL)
                          AND (gr_param.crowd_code_09 IS NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_10;
        ELSIF (gr_param.crowd_code_10 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_10;
        END IF;
        --  �Q�R�[�h���o���� + �E����
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_r_block;
        -- �쐬�r�p�k���ɌQ�R�[�h���o��������
        gv_sql_sel        := gv_sql_sel || gv_sql_crowd_code;
      END IF;
    END IF;
--
--2008.04.28 Y.Kawano modify start
    -- GROUP BY�匋��
    gv_sql_sel := gv_sql_sel || gv_sql_group_by;
--2008.04.28 Y.Kawano add end
--
    -- ORDER BY�匋��
    gv_sql_sel := gv_sql_sel || gv_sql_order_by;
--
    -- �쐬�r�p�k�����s
    EXECUTE IMMEDIATE gv_sql_sel BULK COLLECT INTO ot_sale_plan_1 USING gv_name_sale_plan
                                                                       ,gr_param.gen
                                                                       ,gr_param.year
                                                                       ,gv_name_prod
                                                                       ,gd_start_day
                                                                       ,gd_start_day
                                                                       ,gv_name_crowd
                                                                       ,gv_price_type   -- add 2008/04/28
                                                                       ,gd_start_day
                                                                       ,gd_start_day 
                                                                       ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_sale_plan_1;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_user
   * Description      : XML�f�[�^�ϊ� - ���[�U�[��񕔕�(user_info)
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_user
    (
      ov_errbuf             OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_user'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- -----------------------------------------------------
    -- ���[�g�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'root';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- ====================================================
    -- �J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- ====================================================
    -- �f�[�^�^�O
    -- ====================================================
    -- ���[�h�c
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id;
--
    -- ���s��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(SYSDATE, 'YYYY/MM/DD HH24:MI:SS');
--
    -- ���O�C�����[�U�[�F��������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID);
--
    -- ���O�C�����[�U�[�F���[�U�[��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID);
--
    -- ====================================================
    -- �I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
  EXCEPTION
--###################################  �Œ��O������ START   #####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#######################################  �Œ蕔 END   ###########################################
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_param
   * Description      : XML�f�[�^�ϊ� - �p�����[�^��񕔕�(param_info)
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_param
    (
      ov_errbuf             OUT VARCHAR2        --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2        --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2        --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_param'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- ====================================================
    -- �f�[�^�^�O
    -- ====================================================
    -- �N�x
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'year';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.year || gv_name_year;
--
    -- ����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sdi_num';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.gen;
--
    -- �o�͒P��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'out_unit';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- ���̓p�����[�^����
    -- [0]�̏ꍇ
    IF (gr_param.output_unit = gv_output_unit) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := gv_output_unit_0;
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := gv_output_unit_1;
    END IF;
--
    -- ====================================================
    -- �I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/param_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
  EXCEPTION
--###################################  �Œ��O������ START   #####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#######################################  �Œ蕔 END   ###########################################
  END prc_create_xml_data_param ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : XML�f�[�^�쐬 - ���[�f�[�^�o��
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf    OUT          VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   OUT          VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    OUT          VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �L�[�u���C�N���f�p�萔
    lc_break_init        VARCHAR2(5)           := '*****';
--
    lc_name_leaf         CONSTANT VARCHAR2(10) := '���[�t';
    lc_name_drink        CONSTANT VARCHAR2(10) := '�h�����N';
--
    -- *** ���[�J���ϐ� ***
    lv_skbn_name         VARCHAR2(10);
--
    -- �u���C�N�L�[���f�p�ϐ�
    lv_skbn_break        mtl_categories_b.segment1%TYPE; -- ���i�敪����p
    lv_ktn_break         VARCHAR2(20);                   -- ���_���f�p
    lv_gun_break         VARCHAR2(10);                   -- �Q�R�[�h���f�p
    lv_dtl_break         VARCHAR2(10);                   -- �i�ڔ��f�p
    lv_sttl_break        VARCHAR2(10);                   -- ���Q�v���f�p
    lv_mttl_break        VARCHAR2(10);                   -- ���S�v���f�p
    lv_lttl_break        VARCHAR2(10);                   -- ��Q�v���f�p
--
    -- �v����p
    lv_gun_s             VARCHAR2(5);                    -- ���Q�v�p�i�Q�R�[�h��R���j
    lv_gun_m             VARCHAR2(5);                    -- ���Q�v�p�i�Q�R�[�h��Q���j
    lv_gun_l             VARCHAR2(5);                    -- ��Q�v�p�i�Q�R�[�h��P���j
--
    -- �O���Z����p
    ln_chk_0             NUMBER;                         -- �O���Z���荀��
--
    -- �v�Z�p�ϐ�
    ln_output_unit       NUMBER;                         -- ���ʌv�Z�i�o�͒P�� = �P�[�X�j
    ln_s_u_price         NUMBER;                         -- �W�������v�Z�p
    ln_arari             NUMBER;                         -- �e���v�Z�p
    ln_price             NUMBER;                         -- �i�ڒ艿
    ln_arari_par         NUMBER(8,2);                    -- �e�����p
    ln_kake_par          NUMBER(8,2);                    -- �|��
    ln_syo_arari_par     NUMBER(8,2);                    -- �׌Q�v(�e����)
    ln_syo_kake_par      NUMBER(8,2);                    -- �׌Q�v(�|��)
    ln_syo_s_unit_price  NUMBER;                         -- �׌Q�v(�W������)
    ln_sttl_arari_par    NUMBER(8,2);                    -- ���Q�v(�e����)
    ln_sttl_kake_par     NUMBER(8,2);                    -- ���Q�v(�|��)
    ln_sttl_s_unit_price NUMBER;                         -- ���Q�v(�W������)
    ln_mttl_arari_par    NUMBER(8,2);                    -- ���Q�v(�e����)
    ln_mttl_kake_par     NUMBER(8,2);                    -- ���Q�v(�|��)
    ln_mttl_s_unit_price NUMBER;                         -- ���Q�v(�W������)
    ln_lttl_arari_par    NUMBER(8,2);                    -- ��Q�v(�e����)
    ln_lttl_kake_par     NUMBER(8,2);                    -- ��Q�v(�|��)
    ln_lttl_s_unit_price NUMBER;                         -- ��Q�v(�W������)
    ln_ktn_arari_par     NUMBER(8,2);                    -- ���_�v(�e����)
    ln_ktn_kake_par      NUMBER(8,2);                    -- ���_�v(�|��)
    ln_ktn_s_unit_price  NUMBER;                         -- ���_�v(�W������)
    ln_skbn_arari_par    NUMBER(8,2);                    -- ���i�敪�v(�e����)
    ln_skbn_kake_par     NUMBER(8,2);                    -- ���i�敪�v(�|��)
    ln_skbn_s_unit_price NUMBER;                         -- ���i�敪�v(�W������)
    ln_to_arari_par      NUMBER(8,2);                    -- �����v(�e����)
    ln_to_kake_par       NUMBER(8,2);                    -- �����v(�|��)
    ln_to_s_unit_price   NUMBER;                         -- �����v(�W������)
--
    -- �׌Q�v�v�Z�p���ڕϐ�
    ln_arari_sum         NUMBER := 0;                    -- �e��
    ln_s_am_sum          NUMBER := 0;                    -- ���㍂
    ln_nuit_sum          NUMBER := 0;                    -- �{��
    ln_price_sum         NUMBER := 0;                    -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
--    ln_to_am_sum         NUMBER := 0;                    -- ���󍇌v
    ln_s_unit_price_sum  NUMBER := 0;                    -- �W������
    ln_ara_sum           NUMBER := 0;                    -- �e��(�W�v�p)
    ln_chk_0_sum         NUMBER := 0;                    -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
    ln_quant_sum         NUMBER := 0;                    -- ����
--
    -- ���Q�v�v�Z�p���ڕϐ�
    ln_st_quant_sum      NUMBER := 0;                    -- ����
-- 2009/04/20 v1.8 UPDATE START
--    ln_st_s_u_price_sum  NUMBER := 0;                    -- ���󍇌v
    ln_st_s_unit_price_sum  NUMBER := 0;                 -- �W������
    ln_st_ara_sum           NUMBER := 0;                 -- �e��(�W�v�p)
    ln_st_chk_0_sum         NUMBER := 0;                 -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
    ln_st_arari_sum      NUMBER := 0;                    -- �e��
    ln_st_s_am_sum       NUMBER := 0;                    -- ���㍂
    ln_st_nuit_sum       NUMBER := 0;                    -- �{��
    ln_st_price_sum      NUMBER := 0;                    -- �i�ڒ艿
--
    -- ���Q�v�v�Z�p���ڕϐ�
    ln_mt_quant_sum      NUMBER := 0;                    -- ����
-- 2009/04/20 v1.8 UPDATE START
--    ln_mt_s_u_price_sum  NUMBER := 0;                    -- ���󍇌v
    ln_mt_s_unit_price_sum  NUMBER := 0;                 -- �W������
    ln_mt_ara_sum           NUMBER := 0;                 -- �e��(�W�v�p)
    ln_mt_chk_0_sum         NUMBER := 0;                 -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
    ln_mt_arari_sum      NUMBER := 0;                    -- �e��
    ln_mt_s_am_sum       NUMBER := 0;                    -- ���㍂
    ln_mt_nuit_sum       NUMBER := 0;                    -- �{��
    ln_mt_price_sum      NUMBER := 0;                    -- �i�ڒ艿
--
    -- ��Q�v�v�Z�p���ڕϐ�
    ln_lt_quant_sum      NUMBER := 0;                    -- ����
-- 2009/04/20 v1.8 UPDATE START
--    ln_lt_s_u_price_sum  NUMBER := 0;                    -- ���󍇌v
    ln_lt_s_unit_price_sum  NUMBER := 0;                 -- �W������
    ln_lt_ara_sum           NUMBER := 0;                 -- �e��(�W�v�p)
    ln_lt_chk_0_sum         NUMBER := 0;                 -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
    ln_lt_arari_sum      NUMBER := 0;                    -- �e��
    ln_lt_s_am_sum       NUMBER := 0;                    -- ���㍂
    ln_lt_nuit_sum       NUMBER := 0;                    -- �{��
    ln_lt_price_sum      NUMBER := 0;                    -- �i�ڒ艿
--
    -- ���_�v�v�Z�p���ڕϐ�
    ln_ktn_arari_sum     NUMBER := 0;                    -- �e��
    ln_ktn_s_am_sum      NUMBER := 0;                    -- ���㍂
    ln_ktn_nuit_sum      NUMBER := 0;                    -- �{��
    ln_ktn_price_sum     NUMBER := 0;                    -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
--    ln_ktn_to_am_sum     NUMBER := 0;                    -- ���󍇌v
    ln_ktn_s_unit_price_sum  NUMBER := 0;                -- �W������
    ln_ktn_ara_sum           NUMBER := 0;                -- �e��(�W�v�p)
    ln_ktn_chk_0_sum         NUMBER := 0;                -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
    ln_ktn_quant_sum     NUMBER := 0;                    -- ����
--
    -- ���i�敪�v�v�Z�p���ڕϐ�
    ln_skbn_arari_sum    NUMBER := 0;                    -- �e��
    ln_skbn_s_am_sum     NUMBER := 0;                    -- ���㍂
    ln_skbn_nuit_sum     NUMBER := 0;                    -- �{��
    ln_skbn_price_sum    NUMBER := 0;                    -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
--    ln_skbn_to_am_sum    NUMBER := 0;                    -- ���󍇌v
    ln_skbn_s_unit_price_sum  NUMBER := 0;               -- �W������
    ln_skbn_ara_sum           NUMBER := 0;               -- �e��(�W�v�p)
    ln_skbn_chk_0_sum         NUMBER := 0;               -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
    ln_skbn_quant_sum    NUMBER := 0;                    -- ����
--
    -- �����v�v�Z�p���ڕϐ�
    ln_to_arari_sum      NUMBER := 0;                    -- �e��
    ln_to_s_am_sum       NUMBER := 0;                    -- ���㍂
    ln_to_nuit_sum       NUMBER := 0;                    -- �{��
    ln_to_price_sum      NUMBER := 0;                    -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
--    ln_to_to_am_sum      NUMBER := 0;                    -- ���󍇌v
    ln_to_s_unit_price_sum  NUMBER := 0;                 -- �W������
    ln_to_ara_sum           NUMBER := 0;                 -- �e��(�W�v�p)
    ln_to_chk_0_sum         NUMBER := 0;                 -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
    ln_to_quant_sum      NUMBER := 0;                    -- ����
--
    -- *** ���[�J���E��O���� ***
    no_data_expt         EXCEPTION;                      -- �擾���R�[�h�O����
--
  BEGIN
--
    -- =====================================================
    -- �u���C�N�L�[������
    -- =====================================================
    lv_skbn_break  := lc_break_init;   -- ���i�敪����pBK
    lv_ktn_break   := lc_break_init;   -- ���_�敪����pBK
    lv_gun_break   := lc_break_init;   -- �Q�R�[�h����pBK
    lv_sttl_break  := lc_break_init;   -- ���Q�v����pBK
    lv_mttl_break  := lc_break_init;   -- ���Q�v����pBK
    lv_lttl_break  := lc_break_init;   -- ��Q�v����pBK
--
    -- �o�͎�ʂ��u�S���_�v�̏ꍇ
    IF (gr_param.output_type = gv_name_ktn) THEN
      -- =====================================================
      -- �f�[�^���o - �̔��v��\��񒊏o (B-1-1-1)
      -- =====================================================
      prc_sale_plan
        (
          ot_sale_plan      => gr_sale_plan       -- �擾���R�[�h�Q
         ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        ) ;
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      -- �擾�f�[�^���O���̏ꍇ
      ELSIF (gr_sale_plan.COUNT = 0) THEN
        RAISE no_data_expt;
--
      END IF;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- �f�[�^�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
    -- -----------------------------------------------------
    -- ���i�敪�J�n�k�f�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_skbn_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gr_sale_plan.COUNT LOOP
      -- ====================================================
      --  ���i�敪�u���C�N
      -- ====================================================
      -- ���i�敪���؂�ւ�����Ƃ�
      IF (gr_sale_plan(i).skbn <> lv_skbn_break) THEN
        -- ====================================================
        --  ���i�敪�I���f�^�O�o�͔���
        -- ====================================================
        -- �ŏ��̃��R�[�h�̎��͏o�͂���
        IF (lv_skbn_break <> lc_break_init) THEN
          -- -----------------------------------------------------
          --  �i�ڏI���k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- �׌Q�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
          ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
          ----------------------------------------------------------------
          -- �׌Q�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
          ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
          ----------------------------------------------------------------
          -- �׌Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          -- �O���Z��𔻒�
          IF (ln_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_syo_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
          ----------------------------------------------------------------
          -- �׌Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_price_sum * ln_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_syo_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_syo_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_price_sum = 0) 
            OR (ln_syo_kake_par < 0)THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
          -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
          END IF;
--
          ----------------------------------------------------------------
          -- ���Q�v(����)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(���㍂)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
          ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- ���Q�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
          ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          -- �O���Z��𔻒�
          IF (ln_st_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_sttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
          ----------------------------------------------------------------
          -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_sttl_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_st_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_sttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_st_price_sum = 0)
            OR (ln_sttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
            -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
          END IF;
--
          ----------------------------------------------------------------
          -- ���Q�v(����)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(���㍂)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
          ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- ���Q�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
          ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          --  �O���Z��𔻒�
          IF (ln_mt_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_mttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
          ----------------------------------------------------------------
          -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_mttl_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_mt_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_mttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_mt_price_sum = 0)
            OR (ln_mttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
          -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
          END IF;
--
          ----------------------------------------------------------------
          -- ��Q�v(����)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
          ----------------------------------------------------------------
          -- ��Q�v(���㍂)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
          ----------------------------------------------------------------
          -- ��Q�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
          ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- ��Q�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
          ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
          ----------------------------------------------------------------
          -- ��Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          -- �O���Z��𔻒�
          IF (ln_lt_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_lttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
          ----------------------------------------------------------------
          -- ��Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_lttl_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_lt_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_lttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_lt_price_sum = 0)
            OR (ln_lttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei);  -- �Œ�l:70.00
          -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
          END IF;
--
          -- -----------------------------------------------------
          --  �Q�R�[�h�I���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  �Q�R�[�h�I���k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- ���_�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_ktn_s_unit_price := ln_ktn_to_am_sum * ln_ktn_quant_sum;
          ln_ktn_s_unit_price := ln_ktn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_s_unit_price;
--
          ----------------------------------------------------------------
          -- ���_�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_ktn_arari_sum := ln_ktn_s_am_sum - ln_ktn_s_unit_price;
          ln_ktn_arari_sum := ln_ktn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_sum;
--
          ----------------------------------------------------------------
          -- ���_�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          -- �O���Z��𔻒�
          IF (ln_ktn_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_ktn_arari_par := ROUND((ln_ktn_arari_sum / ln_ktn_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_ktn_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_par;
--
          ----------------------------------------------------------------
          -- ���_�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_ktn_price_sum * ln_ktn_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_ktn_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_ktn_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_ktn_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_ktn_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_ktn_price_sum = 0)
            OR (ln_ktn_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
          -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_kake_par;
          END IF;
--
          -- -----------------------------------------------------
          --  ���_�I���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  ���_�I���k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- ���i�敪�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_skbn_s_unit_price := ln_skbn_to_am_sum * ln_skbn_quant_sum;
          ln_skbn_s_unit_price := ln_skbn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_s_unit_price;
--
          ----------------------------------------------------------------
          -- ���i�敪�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_skbn_arari_sum := ln_skbn_s_am_sum - ln_skbn_s_unit_price;
          ln_skbn_arari_sum := ln_skbn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_sum;
--
          ----------------------------------------------------------------
          -- ���i�敪�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          -- �O���Z��𔻒�
          IF (ln_skbn_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_skbn_arari_par := ROUND((ln_skbn_arari_sum / ln_skbn_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_skbn_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_par;
--
          ----------------------------------------------------------------
          -- ���i�敪�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_skbn_price_sum * ln_skbn_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_skbn_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_skbn_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_skbn_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_skbn_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_skbn_price_sum = 0)
            OR (ln_skbn_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
          -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_kake_par;
          END IF;
--
          -- -----------------------------------------------------
          --  ���i�敪�I���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        END IF;
--
        -- -----------------------------------------------------
        --  ���i�敪�J�n�f�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_skbn';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- ���i�敪(����)����
        -- ���͂o��'1' or ���͂o��NULL�Œ��o�f�[�^��'1'�̏ꍇ
        IF (gr_param.prod_div = gv_prod_div_leaf)
          OR (gr_param.prod_div IS NULL
            AND gr_sale_plan(i).skbn = gv_prod_div_leaf) THEN
          lv_skbn_name := lc_name_leaf;        -- ���i�敪(����)�Ɂu���[�t�v���o��
        -- ���͂o��'2' or ���͂o��NULL�Œ��o�f�[�^��'2'�̏ꍇ
        ELSIF (gr_param.prod_div = gv_prod_div_drink)
          OR (gr_param.prod_div IS NULL
            AND gr_sale_plan(i).skbn = gv_prod_div_drink) THEN
          lv_skbn_name := lc_name_drink;   -- ���i�敪(����)�Ɂu�h�����N�v���o��
        END IF;
--
        ----------------------------------------------------------------
        -- ���i�敪(�R�[�h) �^�O
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).skbn;
--
        ----------------------------------------------------------------
        -- ���i�敪(����) �^�O
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := lv_skbn_name;
--
        -- -----------------------------------------------------
        --  ���_�敪�J�n�k�f�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ktn_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  ���_�敪�J�n�f�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ktn';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        ----------------------------------------------------------------
        -- ���_�敪(���_�R�[�h) �^�O
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := '';          -- �S���_�̏ꍇ�ANULL�\��
--
        ----------------------------------------------------------------
        -- ���_�敪(���_����) �^�O
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gv_name_ktn; -- '�S���_'
--
        -- -----------------------------------------------------
        --  �Q�R�[�h�J�nL�f�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  �Q�R�[�h�J�n�f�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  �i�ڊJ�n�k�f�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- �e�u���C�N�L�[�X�V
        lv_skbn_break := gr_sale_plan(i).skbn;               -- ���i�敪
        lv_gun_break  := gr_sale_plan(i).gun;                -- �Q�R�[�h
        lv_sttl_break := SUBSTRB(gr_sale_plan(i).gun,1,3);   -- ���Q�v
        lv_mttl_break := SUBSTRB(gr_sale_plan(i).gun,1,2);   -- ���Q�v
        lv_lttl_break := SUBSTRB(gr_sale_plan(i).gun,1,1);   -- ��Q�v
--
        -- ���Q�v�W�v�p���ڏ�����
        ln_st_quant_sum     := 0;          -- ����
-- 2009/04/20 v1.8 UPDATE START
--        ln_st_s_u_price_sum := 0;          -- ���󍇌v
        ln_st_s_unit_price_sum := 0;       -- �W������
        ln_st_ara_sum          := 0;       -- �e��(�W�v�p)
        ln_st_chk_0_sum        := 0;       -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
        ln_st_arari_sum     := 0;          -- �e��
        ln_st_s_am_sum      := 0;          -- ���㍂
        ln_st_nuit_sum      := 0;          -- �{��
        ln_st_price_sum     := 0;          -- �i�ڒ艿
        -- ���Q�v�W�v�p���ڏ�����
        ln_mt_quant_sum     := 0;          -- ����
-- 2009/04/20 v1.8 UPDATE START
--        ln_mt_s_u_price_sum := 0;          -- ���󍇌v
        ln_mt_s_unit_price_sum := 0;       -- �W������
        ln_mt_ara_sum          := 0;       -- �e��(�W�v�p)
        ln_mt_chk_0_sum        := 0;       -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
        ln_mt_arari_sum     := 0;          -- �e��
        ln_mt_s_am_sum      := 0;          -- ���㍂
        ln_mt_nuit_sum      := 0;          -- �{��
        ln_mt_price_sum     := 0;          -- �i�ڒ艿
        -- ��Q�v�W�v�p���ڏ�����
        ln_lt_quant_sum     := 0;          -- ����
-- 2009/04/20 v1.8 UPDATE START
--        ln_lt_s_u_price_sum := 0;          -- ���󍇌v
        ln_lt_s_unit_price_sum := 0;       -- �W������
        ln_lt_ara_sum          := 0;       -- �e��(�W�v�p)
        ln_lt_chk_0_sum        := 0;       -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
        ln_lt_arari_sum     := 0;          -- �e��
        ln_lt_s_am_sum      := 0;          -- ���㍂
        ln_lt_nuit_sum      := 0;          -- �{��
        ln_lt_price_sum     := 0;          -- �i�ڒ艿
        -- ���_�v�v�Z�p���ڏ�����
        ln_ktn_arari_sum    := 0;          -- �e��
        ln_ktn_s_am_sum     := 0;          -- ���㍂
        ln_ktn_nuit_sum     := 0;          -- �{��
        ln_ktn_price_sum    := 0;          -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
--        ln_ktn_to_am_sum    := 0;          -- ���󍇌v
        ln_ktn_s_unit_price_sum := 0;      -- �W������
        ln_ktn_ara_sum          := 0;      -- �e��(�W�v�p)
        ln_ktn_chk_0_sum        := 0;      -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
        ln_ktn_quant_sum    := 0;          -- ����
        -- ���i�敪�v�W�v�p���ڏ�����
        ln_skbn_arari_sum   := 0;          -- �e��
        ln_skbn_s_am_sum    := 0;          -- ���㍂
        ln_skbn_nuit_sum    := 0;          -- �{��
        ln_skbn_price_sum   := 0;          -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
--        ln_skbn_to_am_sum   := 0;          -- ���󍇌v
        ln_skbn_s_unit_price_sum := 0;     -- �W������
        ln_skbn_ara_sum          := 0;     -- �e��(�W�v�p)
        ln_skbn_chk_0_sum        := 0;     -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
        ln_skbn_quant_sum   := 0;          -- ����
      END IF;
--
      -- ====================================================
      --  �Q�R�[�h�u���C�N
      -- ====================================================
      -- �Q�R�[�h���؂�ւ�����Ƃ�
      IF (gr_sale_plan(i).gun <> lv_gun_break) THEN
        -- -----------------------------------------------------
        --  �i�ڏI���k�f�^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        ----------------------------------------------------------------
        -- �׌Q�v(�W������)�f�[�^
        ----------------------------------------------------------------
        -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--        ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
        ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
        ----------------------------------------------------------------
        -- �׌Q�v(�e��)�f�[�^
        ----------------------------------------------------------------
        -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--        ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
        ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
        ----------------------------------------------------------------
        -- �׌Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
        ----------------------------------------------------------------
        -- �O���Z��𔻒�
        IF (ln_s_am_sum <> 0) THEN
          -- �l��[0]�o�Ȃ���Όv�Z
          ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
        ELSE
          -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
          ln_syo_arari_par := gn_0;
        END IF;
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
        ----------------------------------------------------------------
        -- �׌Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
        ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
        -- �O���Z���荀�ڂ֔���l��}��
        ln_chk_0 := ln_price_sum * ln_nuit_sum;
        -- �O���Z��𔻒�
        IF (ln_chk_0 <> 0) THEN
          -- �l��[0]�o�Ȃ���Όv�Z
          ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
        ELSE
          -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
          ln_syo_kake_par := gn_0;
        END IF;
*/
        -- �O���Z��𔻒�
        IF (ln_chk_0_sum <> 0) THEN
          -- �l��[0]�o�Ȃ���Όv�Z
          ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
        ELSE
          -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
          ln_syo_kake_par := gn_0;
        END IF;
-- 2009/04/20 v1.8 UPDATE END
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
        IF (ln_price_sum = 0) 
          OR (ln_syo_kake_par < 0)THEN
          gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
        -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
        END IF;
--
        -- ====================================================
        --  ���Q�v�u���C�N
        -- ====================================================
        IF (SUBSTRB(gr_sale_plan(i).gun,1,3) <> lv_sttl_break) THEN
          ----------------------------------------------------------------
          -- ���Q�v(����)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(���㍂)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
          ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- ���Q�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
          ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          -- �O���Z��𔻒�
          IF (ln_st_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_sttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
          ----------------------------------------------------------------
          -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_sttl_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_st_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_sttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_st_price_sum = 0)
            OR (ln_sttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
          -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
          END IF;
          -- ���Q�v�u���C�N�L�[�X�V
          lv_sttl_break := SUBSTRB(gr_sale_plan(i).gun,1,3);
--
          -- ���Q�v�W�v�p���ڏ�����
          ln_st_quant_sum     := 0;              -- ����
-- 2009/04/20 v1.8 UPDATE START
--          ln_st_s_u_price_sum := 0;              -- ���󍇌v
          ln_st_s_unit_price_sum := 0;           -- �W������
          ln_st_ara_sum          := 0;           -- �e��(�W�v�p)
          ln_st_chk_0_sum        := 0;           -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_st_arari_sum     := 0;              -- �e��
          ln_st_s_am_sum      := 0;              -- ���㍂
          ln_st_nuit_sum      := 0;              -- �{��
          ln_st_price_sum     := 0;              -- �i�ڒ艿
        END IF;
--
        -- ====================================================
        --  ���Q�v�u���C�N
        -- ====================================================
        IF (SUBSTRB(gr_sale_plan(i).gun,1,2) <> lv_mttl_break) THEN
          ----------------------------------------------------------------
          -- ���Q�v(����)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(���㍂)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
          ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- ���Q�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
          ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          --  �O���Z��𔻒�
          IF (ln_mt_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_mttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
          ----------------------------------------------------------------
          -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_mttl_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_mt_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_mttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_mt_price_sum = 0)
            OR (ln_mttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
          -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
          END IF;
--
          --  ���Q�v�u���C�N�L�[�X�V
          lv_mttl_break := SUBSTRB(gr_sale_plan(i).gun,1,2);
--
          -- ���Q�v�W�v�p���ڏ�����
          ln_mt_quant_sum     := 0;              -- ����
-- 2009/04/20 v1.8 UPDATE START
--          ln_mt_s_u_price_sum := 0;              -- ���󍇌v
          ln_mt_s_unit_price_sum := 0;           -- �W������
          ln_mt_ara_sum          := 0;           -- �e��(�W�v�p)
          ln_mt_chk_0_sum        := 0;           -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_mt_arari_sum     := 0;              -- �e��
          ln_mt_s_am_sum      := 0;              -- ���㍂
          ln_mt_nuit_sum      := 0;              -- �{��
          ln_mt_price_sum     := 0;              -- �i�ڒ艿
        END IF;
--
        -- ====================================================
        --  ��Q�v�u���C�N
        -- ====================================================
        IF (SUBSTRB(gr_sale_plan(i).gun,1,1) <> lv_lttl_break) THEN
          ----------------------------------------------------------------
          -- ��Q�v(����)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
          ----------------------------------------------------------------
          -- ��Q�v(���㍂)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
          ----------------------------------------------------------------
          -- ��Q�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
          ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- ��Q�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
          ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
          ----------------------------------------------------------------
          -- ��Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          -- �O���Z��𔻒�
          IF (ln_lt_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_lttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
          ----------------------------------------------------------------
          -- ��Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_lttl_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_lt_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_lttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_lt_price_sum = 0)
            OR (ln_lttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
          -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
          END IF;
--
          --  ��Q�v�u���C�N�L�[�X�V
          lv_lttl_break := SUBSTRB(gr_sale_plan(i).gun,1,1);
--
          -- ��Q�v�W�v�p���ڏ�����
          ln_lt_quant_sum     := 0;              -- ����
-- 2009/04/20 v1.8 UPDATE START
--          ln_lt_s_u_price_sum := 0;              -- ���󍇌v
          ln_lt_s_unit_price_sum := 0;           -- �W������
          ln_lt_ara_sum          := 0;           -- �e��(�W�v�p)
          ln_lt_chk_0_sum        := 0;           -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_lt_arari_sum     := 0;              -- �e��
          ln_lt_s_am_sum      := 0;              -- ���㍂
          ln_lt_nuit_sum      := 0;              -- �{��
          ln_lt_price_sum     := 0;              -- �i�ڒ艿
        END IF;
--
        -- -----------------------------------------------------
        --  �Q�R�[�h�I���f�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  �Q�R�[�h�I��L�f�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  �Q�R�[�h�J�nL�f�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  �Q�R�[�h�J�n�f�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- -----------------------------------------------------
        --  �i�ڊJ�n�k�f�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        --  �Q�R�[�h�u���C�N�L�[�X�V
        lv_gun_break  := gr_sale_plan(i).gun;
--
        -- �׌Q�v�W�v�p���ڏ�����
        ln_nuit_sum   := 0;         -- �{��
        ln_price_sum  := 0;         -- �i�ڒ艿
        ln_arari_sum  := 0;         -- �e��
        ln_s_am_sum   := 0;         -- ���㍂
-- 2009/04/20 v1.8 UPDATE START
--        ln_to_am_sum  := 0;         -- ���󍇌v
        ln_s_unit_price_sum := 0;   -- �W������
        ln_ara_sum          := 0;   -- �e��(�W�v�p)
        ln_chk_0_sum        := 0;   -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE START
        ln_quant_sum  := 0;         -- ����
      END IF;
--
      -- -----------------------------------------------------
      --  �i�ڊJ�n�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      ----------------------------------------------------------------
      -- �Q�R�[�h�f�[�^
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'gun_code';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).gun;
--
      ----------------------------------------------------------------
      -- �i��(�R�[�h)�f�[�^
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).item_no;
--
      ----------------------------------------------------------------
      -- �i��(����)�f�[�^
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).item_short_name;
--
      ----------------------------------------------------------------
      -- �����f�[�^
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'case_quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gr_sale_plan(i).case_quant);
--
      ----------------------------------------------------------------
      -- ���ʃf�[�^
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- �o�͒P�ʂ��u�{���v�̏ꍇ
      IF (gr_param.output_unit = gv_output_unit) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gr_sale_plan(i).quant);
      -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
      ELSE
        -- �O���Z��𔻒�
        IF (TO_NUMBER(gr_sale_plan(i).case_quant) <> 0) THEN
          -- �l��[0]�o�Ȃ���΁A���ʌv�Z  (���� / ����)
          ln_output_unit 
                 := TO_NUMBER(gr_sale_plan(i).quant) / TO_NUMBER(gr_sale_plan(i).case_quant);
          -- �����ȉ�1�ʐ؏�
          ln_output_unit := CEIL(ln_output_unit);
        ELSE
          -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
          ln_output_unit := gn_0;
        END IF;
        gt_xml_data_table(gl_xml_idx).tag_value := ln_output_unit;
      END IF;
--
      ----------------------------------------------------------------
      -- ���㍂�f�[�^
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sales_amount';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gr_sale_plan(i).amount);
--
      ----------------------------------------------------------------
      -- �W�������f�[�^ (���󍇌v * ����)
      ----------------------------------------------------------------
      ln_s_u_price := TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant);
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 's_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_s_u_price;
--
      ----------------------------------------------------------------
      -- �e���f�[�^ (���z - ���󍇌v * ����)
      ----------------------------------------------------------------
      ln_arari := TO_NUMBER(gr_sale_plan(i).amount) - ln_s_u_price;
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_arari;
--
      ----------------------------------------------------------------
      -- �e����(%)�f�[�^  ((���z - ���󍇌v * ����) / ���z * 100)
      ----------------------------------------------------------------
      -- �O���Z��𔻒�
      IF (TO_NUMBER(gr_sale_plan(i).amount) <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_arari_par := ROUND((ln_arari / TO_NUMBER(gr_sale_plan(i).amount) * 100),2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_par;
--
      ----------------------------------------------------------------
      -- �|��(%)�f�[�^ ((���z * 100) / (�i�ڒ艿 * ����))
      ----------------------------------------------------------------
      -- �艿�K�p�J�n���ɂċ��艿�E�V�艿�̎g�p���f
      -- �N�x�J�n������OPM�i�ڃ}�X�^�艿�K�p�J�n���ȏ�̏ꍇ
      IF (FND_DATE.STRING_TO_DATE(gr_sale_plan(i).price_st,'YYYY/MM/DD')   <= gd_start_day) THEN
        -- �V�艿���g�p
        ln_price := TO_NUMBER(gr_sale_plan(i).n_amount);
      -- �N�x�J�n������OPM�i�ڃ}�X�^�艿�K�p�J�n�������̏ꍇ
      ELSIF (FND_DATE.STRING_TO_DATE(gr_sale_plan(i).price_st,'YYYY/MM/DD') > gd_start_day) THEN
        -- ���艿���g�p
        ln_price := TO_NUMBER(gr_sale_plan(i).o_amount);
      END IF;
--
      -- �O���Z���荀�ڂ֔���l��}��
--2008.04.30 Y.Kawano modify start
--      ln_chk_0 := ln_price * TO_NUMBER(gr_sale_plan(i).quant) * 100;
      ln_chk_0 := ln_price * TO_NUMBER(gr_sale_plan(i).quant);
--2008.04.30 Y.Kawano modify end
      -- �O���Z��𔻒�
      IF (ln_chk_0 <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
--2008.04.30 Y.Kawano modify start
--        ln_kake_par := ROUND(TO_NUMBER(gr_sale_plan(i).amount) / ln_chk_0,2);
        ln_kake_par := ROUND((TO_NUMBER(gr_sale_plan(i).amount) * 100) / ln_chk_0,2);
--2008.04.30 Y.Kawano modify end
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_kake_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
      IF (ln_price = 0)
        OR (ln_kake_par < 0) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
      -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
      END IF;
--
      -- -----------------------------------------------------
      --  �i�ڏI���f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- �׌Q�v�Ɏg�p���鍀�ڂ�SUM
      ln_s_am_sum   := ln_s_am_sum   + TO_NUMBER(gr_sale_plan(i).amount);              -- ���㍂
      ln_nuit_sum   := ln_nuit_sum   + TO_NUMBER(gr_sale_plan(i).quant);               -- �{��
      ln_price_sum  := ln_price_sum  + ln_price;                                       -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
--      ln_to_am_sum  := ln_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);        -- ���󍇌v
      -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
      ln_s_unit_price_sum := ln_s_unit_price_sum + ln_s_u_price;                       -- �W������
      ln_ara_sum          := ln_ara_sum + ln_arari;                                    -- �e��(�W�v�p)
      ln_chk_0_sum        := ln_chk_0_sum + ln_chk_0;                                  -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
      -- �o�͒P�ʂ��u�{���v�̏ꍇ
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_quant_sum      := ln_quant_sum        + TO_NUMBER(gr_sale_plan(i).quant);   -- ����
      -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
      ELSE
        ln_quant_sum      := ln_quant_sum        + ln_output_unit;                     -- ����
      END IF;
--
      -- ���Q�v�Ɏg�p���鍀�ڂ�SUM
      -- �o�͒P�ʂ��u�{���v�̏ꍇ
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_st_quant_sum   := ln_st_quant_sum     + TO_NUMBER(gr_sale_plan(i).quant);   -- ����
      -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
      ELSE
        ln_st_quant_sum   := ln_st_quant_sum     + ln_output_unit;                     -- ����
      END IF;
-- 2009/04/20 v1.8 UPDATE START
/*
      ln_st_s_u_price_sum := ln_st_s_u_price_sum + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                                       -- ���󍇌v
*/
      -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
      ln_st_s_unit_price_sum  := ln_st_s_unit_price_sum + ln_s_u_price;                -- �W������
      ln_st_ara_sum           := ln_st_ara_sum + ln_arari;                             -- �e��(�W�v�p)
      ln_st_chk_0_sum         := ln_st_chk_0_sum + ln_chk_0;                           -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
      ln_st_s_am_sum      := ln_st_s_am_sum      + TO_NUMBER(gr_sale_plan(i).amount);  -- ���㍂
      ln_st_nuit_sum      := ln_st_nuit_sum      + TO_NUMBER(gr_sale_plan(i).quant);   -- �{��
      ln_st_price_sum     := ln_st_price_sum     + ln_price;                           -- �i�ڒ艿
--
      -- ���Q�v�Ɏg�p���鍀�ڂ�SUM
      -- �o�͒P�ʂ��u�{���v�̏ꍇ
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_mt_quant_sum   := ln_mt_quant_sum     + TO_NUMBER(gr_sale_plan(i).quant);   -- ����
      -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
      ELSE
        ln_mt_quant_sum   := ln_mt_quant_sum     + ln_output_unit;                     -- ����
      END IF;
-- 2009/04/20 v1.8 UPDATE START
/*
      ln_mt_s_u_price_sum := ln_mt_s_u_price_sum + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                                       -- ���󍇌v
*/
      -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
      ln_mt_s_unit_price_sum  := ln_mt_s_unit_price_sum + ln_s_u_price;                -- �W������
      ln_mt_ara_sum           := ln_mt_ara_sum + ln_arari;                             -- �e��(�W�v�p)
      ln_mt_chk_0_sum         := ln_mt_chk_0_sum + ln_chk_0;                           -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
      ln_mt_s_am_sum      := ln_mt_s_am_sum      + TO_NUMBER(gr_sale_plan(i).amount);  -- ���㍂
      ln_mt_nuit_sum      := ln_mt_nuit_sum      + TO_NUMBER(gr_sale_plan(i).quant);   -- �{��
      ln_mt_price_sum     := ln_mt_price_sum     + ln_price;                           -- �i�ڒ艿
--
      -- ��Q�v�Ɏg�p���鍀�ڂ�SUM
      -- �o�͒P�ʂ��u�{���v�̏ꍇ
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_lt_quant_sum   := ln_lt_quant_sum     + TO_NUMBER(gr_sale_plan(i).quant);   -- ����
      -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
      ELSE
        ln_lt_quant_sum   := ln_lt_quant_sum     + ln_output_unit;                     -- ����
      END IF;
-- 2009/04/20 v1.8 UPDATE START
/*
      ln_lt_s_u_price_sum := ln_lt_s_u_price_sum + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                                       -- ���󍇌v
*/
      -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
      ln_lt_s_unit_price_sum  := ln_lt_s_unit_price_sum + ln_s_u_price;                -- �W������
      ln_lt_ara_sum           := ln_lt_ara_sum + ln_arari;                             -- �e��(�W�v�p)
      ln_lt_chk_0_sum         := ln_lt_chk_0_sum + ln_chk_0;                           -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
      ln_lt_s_am_sum      := ln_lt_s_am_sum      + TO_NUMBER(gr_sale_plan(i).amount);  -- ���㍂
      ln_lt_nuit_sum      := ln_lt_nuit_sum      + TO_NUMBER(gr_sale_plan(i).quant);   -- �{��
      ln_lt_price_sum     := ln_lt_price_sum     + ln_price;                           -- �i�ڒ艿
--
      -- ���_�v�Ɏg�p���鍀�ڂ�SUM
      ln_ktn_s_am_sum     := ln_ktn_s_am_sum     + TO_NUMBER(gr_sale_plan(i).amount);  -- ���㍂
      ln_ktn_nuit_sum     := ln_ktn_nuit_sum     + TO_NUMBER(gr_sale_plan(i).quant);   -- �{��
      ln_ktn_price_sum    := ln_ktn_price_sum    + ln_price;                           -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
/*
      ln_ktn_to_am_sum    := ln_ktn_to_am_sum    + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                                       -- ���󍇌v
*/
      -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
      ln_ktn_s_unit_price_sum  := ln_ktn_s_unit_price_sum + ln_s_u_price;              -- �W������
      ln_ktn_ara_sum           := ln_ktn_ara_sum + ln_arari;                           -- �e��
      ln_ktn_chk_0_sum         := ln_ktn_chk_0_sum + ln_chk_0;                         -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
      -- �o�͒P�ʂ��u�{���v�̏ꍇ
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_ktn_quant_sum   := ln_ktn_quant_sum   + TO_NUMBER(gr_sale_plan(i).quant);   -- ����
      -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
      ELSE
        ln_ktn_quant_sum   := ln_ktn_quant_sum   + ln_output_unit;                     -- ����
      END IF;
--
      -- ���i�敪�v�Ɏg�p���鍀�ڂ�SUM
      ln_skbn_s_am_sum    := ln_skbn_s_am_sum    + TO_NUMBER(gr_sale_plan(i).amount);  -- ���㍂
      ln_skbn_nuit_sum    := ln_skbn_nuit_sum    + TO_NUMBER(gr_sale_plan(i).quant);   -- �{��
      ln_skbn_price_sum   := ln_skbn_price_sum   + ln_price;                           -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
/*
      ln_skbn_to_am_sum   := ln_skbn_to_am_sum   + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                                       -- ���󍇌v
*/
      -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
      ln_skbn_s_unit_price_sum  := ln_skbn_s_unit_price_sum + ln_s_u_price;            -- �W������
      ln_skbn_ara_sum           := ln_skbn_ara_sum + ln_arari;                         -- �e��(�W�v�p)
      ln_skbn_chk_0_sum         := ln_skbn_chk_0_sum + ln_chk_0;                       -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
      -- �o�͒P�ʂ��u�{���v�̏ꍇ
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_skbn_quant_sum   := ln_skbn_quant_sum + TO_NUMBER(gr_sale_plan(i).quant);   -- ����
      -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
      ELSE
        ln_skbn_quant_sum   := ln_skbn_quant_sum + ln_output_unit;                     -- ����
      END IF;
--
      -- �����v�Ɏg�p���鍀�ڂ�SUM
      ln_to_s_am_sum      := ln_to_s_am_sum      + TO_NUMBER(gr_sale_plan(i).amount);  -- ���㍂
      ln_to_nuit_sum      := ln_to_nuit_sum      + TO_NUMBER(gr_sale_plan(i).quant);   -- �{��
      ln_to_price_sum     := ln_to_price_sum     + ln_price;                           -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
/*
      ln_to_to_am_sum     := ln_to_to_am_sum     + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                                       -- ���󍇌v
*/
      -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
      ln_to_s_unit_price_sum  := ln_to_s_unit_price_sum + ln_s_u_price;                -- �W������
      ln_to_ara_sum           := ln_to_ara_sum + ln_arari;                             -- �e��(�W�v�p)
      ln_to_chk_0_sum         := ln_to_chk_0_sum + ln_chk_0;                           -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
      -- �o�͒P�ʂ��u�{���v�̏ꍇ
      IF (gr_param.output_unit = gv_output_unit) THEN
        ln_to_quant_sum   := ln_to_quant_sum     + TO_NUMBER(gr_sale_plan(i).quant);   -- ����
      -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
      ELSE
        ln_to_quant_sum   := ln_to_quant_sum     + ln_output_unit;                     -- ����
      END IF;
--
    END LOOP main_data_loop;
    -- =====================================================
    --    �I������
    -- =====================================================
    -- -----------------------------------------------------
    --  �i�ڏI���k�f�^�O�o��
    -- ----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ----------------------------------------------------------------
    -- �׌Q�v(�W������)�f�[�^
    ----------------------------------------------------------------
    -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
    ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
    ----------------------------------------------------------------
    -- �׌Q�v(�e��)�f�[�^
    ----------------------------------------------------------------
    -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
    ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--

    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
    ----------------------------------------------------------------
    -- �׌Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
    ----------------------------------------------------------------
    -- �O���Z��𔻒�
    IF (ln_s_am_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_syo_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
    ----------------------------------------------------------------
    -- �׌Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- �O���Z���荀�ڂ֔���l��}��
    ln_chk_0 := ln_price_sum * ln_nuit_sum;
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_syo_kake_par := gn_0;
    END IF;
*/
    -- �O���Z��𔻒�
    IF (ln_chk_0_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_syo_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
    IF (ln_price_sum = 0) 
      OR (ln_syo_kake_par < 0)THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
    -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
    END IF;
--
    ----------------------------------------------------------------
    -- ���Q�v(����)�f�[�^
    ----------------------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
    ----------------------------------------------------------------
    -- ���Q�v(���㍂)�f�[�^
    ----------------------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
    ----------------------------------------------------------------
    -- ���Q�v(�W������)�f�[�^
    ----------------------------------------------------------------
    -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
    ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
    ----------------------------------------------------------------
    -- ���Q�v(�e��)�f�[�^
    ----------------------------------------------------------------
    -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
    ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
    ----------------------------------------------------------------
    -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
    ----------------------------------------------------------------
    -- �O���Z��𔻒�
    IF (ln_st_s_am_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_sttl_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
    ----------------------------------------------------------------
    -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- �O���Z���荀�ڂ֔���l��}��
    ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_sttl_kake_par := gn_0;
    END IF;
*/
    -- �O���Z��𔻒�
    IF (ln_st_chk_0_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_sttl_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
    IF (ln_st_price_sum = 0)
      OR (ln_sttl_kake_par < 0) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
      -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
    END IF;
--
    ----------------------------------------------------------------
    -- ���Q�v(����)�f�[�^
    ----------------------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
    ----------------------------------------------------------------
    -- ���Q�v(���㍂)�f�[�^
    ----------------------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
    ----------------------------------------------------------------
    -- ���Q�v(�W������)�f�[�^
    ----------------------------------------------------------------
    -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
    ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
    ----------------------------------------------------------------
    -- ���Q�v(�e��)�f�[�^
    ----------------------------------------------------------------
    -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
    ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
    ----------------------------------------------------------------
    -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
    ----------------------------------------------------------------
    --  �O���Z��𔻒�
    IF (ln_mt_s_am_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_mttl_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
    ----------------------------------------------------------------
    -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- �O���Z���荀�ڂ֔���l��}��
    ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_mttl_kake_par := gn_0;
    END IF;
*/
    -- �O���Z��𔻒�
    IF (ln_mt_chk_0_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_mttl_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
    IF (ln_mt_price_sum = 0)
      OR (ln_mttl_kake_par < 0) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
    -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
    END IF;
--
    ----------------------------------------------------------------
    -- ��Q�v(����)�f�[�^
    ----------------------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
    ----------------------------------------------------------------
    -- ��Q�v(���㍂)�f�[�^
    ----------------------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
    ----------------------------------------------------------------
    -- ��Q�v(�W������)�f�[�^
    ----------------------------------------------------------------
    -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
    ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
--
    ----------------------------------------------------------------
    -- ��Q�v(�e��)�f�[�^
    ----------------------------------------------------------------
    -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
    ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
    ----------------------------------------------------------------
    -- ��Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
    ----------------------------------------------------------------
    -- �O���Z��𔻒�
    IF (ln_lt_s_am_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_lttl_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
    ----------------------------------------------------------------
    -- ��Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- �O���Z���荀�ڂ֔���l��}��
    ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_lttl_kake_par := gn_0;
    END IF;
*/
    -- �O���Z��𔻒�
    IF (ln_lt_chk_0_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_lttl_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
    IF (ln_lt_price_sum = 0)
      OR (ln_lttl_kake_par < 0) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
    -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
    END IF;
--
    -- -----------------------------------------------------
    --  �Q�R�[�h�I���f�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- -----------------------------------------------------
    --  �Q�R�[�h�I���k�f�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ----------------------------------------------------------------
    -- ���_�v(�W������)�f�[�^
    ----------------------------------------------------------------
    -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_ktn_s_unit_price := ln_ktn_to_am_sum * ln_ktn_quant_sum;
    ln_ktn_s_unit_price := ln_ktn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_s_unit_price;
--
    ----------------------------------------------------------------
    -- ���_�v(�e��)�f�[�^
    ----------------------------------------------------------------
    -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_ktn_arari_sum := ln_ktn_s_am_sum - ln_ktn_s_unit_price;
    ln_ktn_arari_sum := ln_ktn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_sum;
--
    ----------------------------------------------------------------
    -- ���_�v(�e����)�f�[�^  ((�e��/���㍂)*100)
    ----------------------------------------------------------------
    -- �O���Z��𔻒�
    IF (ln_ktn_s_am_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_ktn_arari_par := ROUND((ln_ktn_arari_sum / ln_ktn_s_am_sum) * 100,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_ktn_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_par;
--
    ----------------------------------------------------------------
    -- ���_�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- �O���Z���荀�ڂ֔���l��}��
    ln_chk_0 := ln_ktn_price_sum * ln_ktn_nuit_sum;
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_ktn_kake_par := gn_0;
    END IF;
*/
    -- �O���Z��𔻒�
    IF (ln_ktn_chk_0_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_ktn_chk_0_sum, 2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_ktn_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
    IF (ln_ktn_price_sum = 0)
      OR (ln_ktn_kake_par < 0) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
    -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_kake_par;
    END IF;
--
    -- -----------------------------------------------------
    --  ���_�I���f�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- -----------------------------------------------------
    --  ���_�I���k�f�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ----------------------------------------------------------------
    -- ���i�敪�v(�W������)�f�[�^
    ----------------------------------------------------------------
    -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_skbn_s_unit_price := ln_skbn_to_am_sum * ln_skbn_quant_sum;
    ln_skbn_s_unit_price := ln_skbn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_s_unit_price;
--
    ----------------------------------------------------------------
    -- ���i�敪�v(�e��)�f�[�^
    ----------------------------------------------------------------
    -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_skbn_arari_sum := ln_skbn_s_am_sum - ln_skbn_s_unit_price;
    ln_skbn_arari_sum := ln_skbn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_sum;
--
    ----------------------------------------------------------------
    -- ���i�敪�v(�e����)�f�[�^  ((�e��/���㍂)*100)
    ----------------------------------------------------------------
    -- �O���Z��𔻒�
    IF (ln_skbn_s_am_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_skbn_arari_par := ROUND((ln_skbn_arari_sum / ln_skbn_s_am_sum) * 100,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_skbn_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_par;
--
    ----------------------------------------------------------------
    -- ���i�敪�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- �O���Z���荀�ڂ֔���l��}��
    ln_chk_0 := ln_skbn_price_sum * ln_skbn_nuit_sum;
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_skbn_kake_par := gn_0;
    END IF;
*/
    -- �O���Z��𔻒�
    IF (ln_skbn_chk_0_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_skbn_chk_0_sum, 2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_skbn_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
    IF (ln_skbn_price_sum = 0)
      OR (ln_skbn_kake_par < 0) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
    -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_kake_par;
    END IF;
--
    ----------------------------------------------------------------
    -- �����v(�W������)�f�[�^
    ----------------------------------------------------------------
    -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_to_s_unit_price := ln_to_to_am_sum * ln_to_quant_sum;
    ln_to_s_unit_price := ln_to_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_s_unit_price';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_to_s_unit_price;
--
    ----------------------------------------------------------------
    -- �����v(�e��)�f�[�^
    ----------------------------------------------------------------
    -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--    ln_to_arari_sum := ln_to_s_am_sum - ln_to_s_unit_price;
    ln_to_arari_sum := ln_to_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_arari';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_to_arari_sum;
--
    ----------------------------------------------------------------
    -- �����v(�e����)�f�[�^  ((�e��/���㍂)*100)
    ----------------------------------------------------------------
    -- �O���Z��𔻒�
    IF (ln_to_s_am_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_to_arari_par := ROUND((ln_to_arari_sum / ln_to_s_am_sum) * 100,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_to_arari_par := gn_0;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_to_arari_par;
--
    ----------------------------------------------------------------
    -- �����v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
    ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
    -- �O���Z���荀�ڂ֔���l��}��
    ln_chk_0 := ln_to_price_sum * ln_to_nuit_sum;
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_to_kake_par := ROUND((ln_to_s_am_sum * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_to_kake_par := gn_0;
    END IF;
*/
    -- �O���Z��𔻒�
    IF (ln_to_chk_0_sum <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_to_kake_par := ROUND((ln_to_s_am_sum * 100) / ln_to_chk_0_sum, 2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_to_kake_par := gn_0;
    END IF;
-- 2009/04/20 v1.8 UPDATE END
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
    IF (ln_to_price_sum = 0)
      OR (ln_to_kake_par < 0) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
    -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := ln_to_kake_par;
    END IF;
--
    -- -----------------------------------------------------
    --  ���i�敪�I���f�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- -----------------------------------------------------
    --  ���i�敪�I���k�f�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_skbn_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- -----------------------------------------------------
    -- �f�[�^�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- -----------------------------------------------------
    -- ���[�g�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/root';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- �o�͎�ʂ��u���_�v�̏ꍇ
    ELSE
      -- =====================================================
      -- �f�[�^���o - �̔��v��\��񒊏o (B-1-1-2)
      -- =====================================================
      prc_sale_plan_1
        (
          ot_sale_plan_1    => gr_sale_plan_1     -- �擾���R�[�h�Q
         ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
--
      -- �擾�f�[�^���O���̏ꍇ
      ELSIF (gr_sale_plan_1.COUNT = 0) THEN
        RAISE no_data_expt;
--
      END IF;
--
      -- =====================================================
      -- ���ڃf�[�^���o�E�o�͏���
      -- =====================================================
      -- -----------------------------------------------------
      -- �f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- ���i�敪�J�n�k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_skbn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- =====================================================
      -- ���ڃf�[�^���o�E�o�͏���
      -- =====================================================
      <<main_data_loop_1>>
      FOR i IN 1..gr_sale_plan_1.COUNT LOOP
        -- ====================================================
        --  ���i�敪�u���C�N
        -- ====================================================
        -- ���i�敪���؂�ւ�����Ƃ�
        IF (gr_sale_plan_1(i).skbn <> lv_skbn_break) THEN
          -- ====================================================
          --  ���i�敪�I���f�^�O�o�͔���
          -- ====================================================
          -- �ŏ��̃��R�[�h�̎��͏o�͂���
          IF (lv_skbn_break <> lc_break_init) THEN
            -- -----------------------------------------------------
            --  �i�ڏI���k�f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            ----------------------------------------------------------------
            -- �׌Q�v(�W������)�f�[�^
            ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
            ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
            ----------------------------------------------------------------
            -- �׌Q�v(�e��)�f�[�^
            ----------------------------------------------------------------
            -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
            ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
            ----------------------------------------------------------------
            -- �׌Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
            ----------------------------------------------------------------
            -- �O���Z��𔻒�
            IF (ln_s_am_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_syo_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
            ----------------------------------------------------------------
            -- �׌Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- �O���Z���荀�ڂ֔���l��}��
            ln_chk_0 := ln_price_sum * ln_nuit_sum;
            -- �O���Z��𔻒�
            IF (ln_chk_0 <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_syo_kake_par := gn_0;
            END IF;
*/
            -- �O���Z��𔻒�
            IF (ln_chk_0_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_syo_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
            IF (ln_price_sum = 0) 
              OR (ln_syo_kake_par < 0)THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
            -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
            END IF;
--
            ----------------------------------------------------------------
            -- ���Q�v(����)�f�[�^
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
            ----------------------------------------------------------------
            -- ���Q�v(���㍂)�f�[�^
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
            ----------------------------------------------------------------
            -- ���Q�v(�W������)�f�[�^
            ----------------------------------------------------------------
            -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
            ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
            ----------------------------------------------------------------
            -- ���Q�v(�e��)�f�[�^
            ----------------------------------------------------------------
            -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
            ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
            ----------------------------------------------------------------
            -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
            ----------------------------------------------------------------
            -- �O���Z��𔻒�
            IF (ln_st_s_am_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_sttl_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
            ----------------------------------------------------------------
            -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- �O���Z���荀�ڂ֔���l��}��
            ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
            -- �O���Z��𔻒�
            IF (ln_chk_0 <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_sttl_kake_par := gn_0;
            END IF;
*/
            -- �O���Z��𔻒�
            IF (ln_st_chk_0_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_sttl_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
            IF (ln_st_price_sum = 0)
              OR (ln_sttl_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
              -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
            END IF;
--
            ----------------------------------------------------------------
            -- ���Q�v(����)�f�[�^
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
            ----------------------------------------------------------------
            -- ���Q�v(���㍂)�f�[�^
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
            ----------------------------------------------------------------
            -- ���Q�v(�W������)�f�[�^
            ----------------------------------------------------------------
            -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
            ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
            ----------------------------------------------------------------
            -- ���Q�v(�e��)�f�[�^
            ----------------------------------------------------------------
            -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
            ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
            ----------------------------------------------------------------
            -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
            ----------------------------------------------------------------
            --  �O���Z��𔻒�
            IF (ln_mt_s_am_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_mttl_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
            ----------------------------------------------------------------
            -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- �O���Z���荀�ڂ֔���l��}��
            ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
            -- �O���Z��𔻒�
            IF (ln_chk_0 <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_mttl_kake_par := gn_0;
            END IF;
*/
            -- �O���Z��𔻒�
            IF (ln_mt_chk_0_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_mttl_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
            IF (ln_mt_price_sum = 0)
              OR (ln_mttl_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
            -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
            END IF;
--
            ----------------------------------------------------------------
            -- ��Q�v(����)�f�[�^
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
            ----------------------------------------------------------------
            -- ��Q�v(���㍂)�f�[�^
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
            ----------------------------------------------------------------
            -- ��Q�v(�W������)�f�[�^
            ----------------------------------------------------------------
            -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
            ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
--
            ----------------------------------------------------------------
            -- ��Q�v(�e��)�f�[�^
            ----------------------------------------------------------------
            -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
            ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
            ----------------------------------------------------------------
            -- ��Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
            ----------------------------------------------------------------
            -- �O���Z��𔻒�
            IF (ln_lt_s_am_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_lttl_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
            ----------------------------------------------------------------
            -- ��Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- �O���Z���荀�ڂ֔���l��}��
            ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
            -- �O���Z��𔻒�
            IF (ln_chk_0 <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_lttl_kake_par := gn_0;
            END IF;
*/
            -- �O���Z��𔻒�
            IF (ln_lt_chk_0_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_lttl_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
            IF (ln_lt_price_sum = 0)
              OR (ln_lttl_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
            -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
            END IF;
--
            -- -----------------------------------------------------
            --  �Q�R�[�h�I���f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  �Q�R�[�h�I���k�f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            ----------------------------------------------------------------
            -- ���_�v(�W������)�f�[�^
            ----------------------------------------------------------------
            -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_ktn_s_unit_price := ln_ktn_to_am_sum * ln_ktn_quant_sum;
            ln_ktn_s_unit_price := ln_ktn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_s_unit_price;
--
            ----------------------------------------------------------------
            -- ���_�v(�e��)�f�[�^
            ----------------------------------------------------------------
            -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_ktn_arari_sum := ln_ktn_s_am_sum - ln_ktn_s_unit_price;
            ln_ktn_arari_sum := ln_ktn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_sum;
--
            ----------------------------------------------------------------
            -- ���_�v(�e����)�f�[�^  ((�e��/���㍂)*100)
            ----------------------------------------------------------------
            -- �O���Z��𔻒�
            IF (ln_ktn_s_am_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_ktn_arari_par := ROUND((ln_ktn_arari_sum / ln_ktn_s_am_sum) * 100,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_ktn_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_par;
--
            ----------------------------------------------------------------
            -- ���_�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- �O���Z���荀�ڂ֔���l��}��
            ln_chk_0 := ln_ktn_price_sum * ln_ktn_nuit_sum;
            -- �O���Z��𔻒�
            IF (ln_chk_0 <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_ktn_kake_par := gn_0;
            END IF;
*/
            -- �O���Z��𔻒�
            IF (ln_ktn_chk_0_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_ktn_chk_0_sum, 2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_ktn_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
            IF (ln_ktn_price_sum = 0)
              OR (ln_ktn_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
            -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_kake_par;
            END IF;
--
            -- -----------------------------------------------------
            --  ���_�I���f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  ���_�I���k�f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            ----------------------------------------------------------------
            -- ���i�敪�v(�W������)�f�[�^
            ----------------------------------------------------------------
            -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_skbn_s_unit_price := ln_skbn_to_am_sum * ln_skbn_quant_sum;
            ln_skbn_s_unit_price := ln_skbn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_s_unit_price;
--
            ----------------------------------------------------------------
            -- ���i�敪�v(�e��)�f�[�^
            ----------------------------------------------------------------
            -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_skbn_arari_sum := ln_skbn_s_am_sum - ln_skbn_s_unit_price;
            ln_skbn_arari_sum := ln_skbn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_sum;
--
            ----------------------------------------------------------------
            -- ���i�敪�v(�e����)�f�[�^  ((�e��/���㍂)*100)
            ----------------------------------------------------------------
            -- �O���Z��𔻒�
            IF (ln_skbn_s_am_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_skbn_arari_par := ROUND((ln_skbn_arari_sum / ln_skbn_s_am_sum) * 100,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_skbn_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_par;
--
            ----------------------------------------------------------------
            -- ���i�敪�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- �O���Z���荀�ڂ֔���l��}��
            ln_chk_0 := ln_skbn_price_sum * ln_skbn_nuit_sum;
            -- �O���Z��𔻒�
            IF (ln_chk_0 <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_skbn_kake_par := gn_0;
            END IF;
*/
            -- �O���Z��𔻒�
            IF (ln_skbn_chk_0_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_skbn_chk_0_sum, 2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_skbn_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
            IF (ln_skbn_price_sum = 0)
              OR (ln_skbn_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
            -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_kake_par;
            END IF;
--
            -- -----------------------------------------------------
            --  ���i�敪�I���f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
          END IF;
--
          -- -----------------------------------------------------
          --  ���i�敪�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_skbn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- ���i�敪(����)����
          -- ���͂o��'1' or ���͂o��NULL�Œ��o�f�[�^��'1'�̏ꍇ
          IF (gr_param.prod_div = gv_prod_div_leaf)
            OR (gr_param.prod_div IS NULL
              AND gr_sale_plan_1(i).skbn = gv_prod_div_leaf) THEN
            lv_skbn_name := lc_name_leaf;        -- ���i�敪(����)�Ɂu���[�t�v���o��
          -- ���͂o��'2' or ���͂o��NULL�Œ��o�f�[�^��'2'�̏ꍇ
          ELSIF (gr_param.prod_div = gv_prod_div_drink)
            OR (gr_param.prod_div IS NULL
              AND gr_sale_plan_1(i).skbn = gv_prod_div_drink) THEN
            lv_skbn_name := lc_name_drink;   -- ���i�敪(����)�Ɂu�h�����N�v���o��
          END IF;
--
          ----------------------------------------------------------------
          -- ���i�敪(�R�[�h) �^�O
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).skbn;
--
          ----------------------------------------------------------------
          -- ���i�敪(����) �^�O
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := lv_skbn_name;
--
          -- -----------------------------------------------------
          --  ���_�敪�J�n�k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ktn_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  ���_�敪�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- ���_�敪(���_�R�[�h) �^�O
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).ktn_code;
--
          ----------------------------------------------------------------
          -- ���_�敪(���_����) �^�O
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).party_short_name;
--
          -- -----------------------------------------------------
          --  �Q�R�[�h�J�nL�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  �Q�R�[�h�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  �i�ڊJ�n�k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- �e�u���C�N�L�[�X�V
          lv_skbn_break := gr_sale_plan_1(i).skbn;               -- ���i�敪
          lv_ktn_break  := gr_sale_plan_1(i).ktn_code;           -- ���_
          lv_gun_break  := gr_sale_plan_1(i).gun;                -- �Q�R�[�h
          lv_sttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,3);   -- ���Q�v
          lv_mttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,2);   -- ���Q�v
          lv_lttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,1);   -- ��Q�v
--
          -- ���Q�v�W�v�p���ڏ�����
          ln_st_quant_sum     := 0;          -- ����
-- 2009/04/20 v1.8 UPDATE START
--          ln_st_s_u_price_sum := 0;          -- ���󍇌v
          ln_st_s_unit_price_sum := 0;       -- �W������
          ln_st_ara_sum          := 0;       -- �e��(�W�v�p)
          ln_st_chk_0_sum        := 0;       -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_st_arari_sum     := 0;          -- �e��
          ln_st_s_am_sum      := 0;          -- ���㍂
          ln_st_nuit_sum      := 0;          -- �{��
          ln_st_price_sum     := 0;          -- �i�ڒ艿
          -- ���Q�v�W�v�p���ڏ�����
          ln_mt_quant_sum     := 0;          -- ����
-- 2009/04/20 v1.8 UPDATE START
--          ln_mt_s_u_price_sum := 0;          -- ���󍇌v
          ln_mt_s_unit_price_sum := 0;       -- �W������
          ln_mt_ara_sum          := 0;       -- �e��(�W�v�p)
          ln_mt_chk_0_sum        := 0;       -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_mt_arari_sum     := 0;          -- �e��
          ln_mt_s_am_sum      := 0;          -- ���㍂
          ln_mt_nuit_sum      := 0;          -- �{��
          ln_mt_price_sum     := 0;          -- �i�ڒ艿
          -- ��Q�v�W�v�p���ڏ�����
          ln_lt_quant_sum     := 0;          -- ����
-- 2009/04/20 v1.8 UPDATE START
--          ln_lt_s_u_price_sum := 0;          -- ���󍇌v
          ln_lt_s_unit_price_sum := 0;       -- �W������
          ln_lt_ara_sum          := 0;       -- �e��(�W�v�p)
          ln_lt_chk_0_sum        := 0;       -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_lt_arari_sum     := 0;          -- �e��
          ln_lt_s_am_sum      := 0;          -- ���㍂
          ln_lt_nuit_sum      := 0;          -- �{��
          ln_lt_price_sum     := 0;          -- �i�ڒ艿
          -- ���_�v�v�Z�p���ڏ�����
          ln_ktn_arari_sum    := 0;          -- �e��
          ln_ktn_s_am_sum     := 0;          -- ���㍂
          ln_ktn_nuit_sum     := 0;          -- �{��
          ln_ktn_price_sum    := 0;          -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
--          ln_ktn_to_am_sum    := 0;          -- ���󍇌v
          ln_ktn_s_unit_price_sum := 0;      -- �W������
          ln_ktn_ara_sum          := 0;      -- �e��(�W�v�p)
          ln_ktn_chk_0_sum        := 0;      -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_ktn_quant_sum    := 0;          -- ����
          -- ���i�敪�v�W�v�p���ڏ�����
          ln_skbn_arari_sum   := 0;          -- �e��
          ln_skbn_s_am_sum    := 0;          -- ���㍂
          ln_skbn_nuit_sum    := 0;          -- �{��
          ln_skbn_price_sum   := 0;          -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
--          ln_skbn_to_am_sum   := 0;          -- ���󍇌v
          ln_skbn_s_unit_price_sum := 0;     -- �W������
          ln_skbn_ara_sum          := 0;     -- �e��(�W�v�p)
          ln_skbn_chk_0_sum        := 0;     -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_skbn_quant_sum   := 0;          -- ����
        END IF;
--
        -- ====================================================
        --  ���_�u���C�N
        -- ====================================================
        -- ���_���؂�ւ�����Ƃ�
        IF (gr_sale_plan_1(i).ktn_code <> lv_ktn_break) THEN
          -- -----------------------------------------------------
          --  �i�ڏI���k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- �׌Q�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
          ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
          ----------------------------------------------------------------
          -- �׌Q�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
          ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
          ----------------------------------------------------------------
          -- �׌Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          -- �O���Z��𔻒�
          IF (ln_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_syo_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
          ----------------------------------------------------------------
          -- �׌Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_price_sum * ln_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_syo_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_syo_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_price_sum = 0) 
            OR (ln_syo_kake_par < 0)THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
          -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
          END IF;
--
          ----------------------------------------------------------------
          -- ���Q�v(����)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(���㍂)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
          ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- ���Q�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
          ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          -- �O���Z��𔻒�
          IF (ln_st_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_sttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
          ----------------------------------------------------------------
          -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_sttl_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_st_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_sttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_st_price_sum = 0)
            OR (ln_sttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
            -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
          END IF;
--
          ----------------------------------------------------------------
          -- ���Q�v(����)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(���㍂)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
          ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
          ----------------------------------------------------------------
          -- ���Q�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
          ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
          ----------------------------------------------------------------
          -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          --  �O���Z��𔻒�
          IF (ln_mt_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_mttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
          ----------------------------------------------------------------
          -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_mttl_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_mt_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_mttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_mt_price_sum = 0)
            OR (ln_mttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
          -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
          END IF;
--
          ----------------------------------------------------------------
          -- ��Q�v(����)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
          ----------------------------------------------------------------
          -- ��Q�v(���㍂)�f�[�^
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
          ----------------------------------------------------------------
          -- ��Q�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
          ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/04/20 v1.8 UPDATE START
--          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_u_price_sum;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
-- 2009/04/20 v1.8 UPDATE END
--
          ----------------------------------------------------------------
          -- ��Q�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
          ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
          ----------------------------------------------------------------
          -- ��Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          -- �O���Z��𔻒�
          IF (ln_lt_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_lttl_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
          ----------------------------------------------------------------
          -- ��Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_lttl_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_lt_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_lttl_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_lt_price_sum = 0)
            OR (ln_lttl_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
          -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
          END IF;
--
          -- -----------------------------------------------------
          --  �Q�R�[�h�I���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  �Q�R�[�h�I��L�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- ���_�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_ktn_s_unit_price := ln_ktn_to_am_sum * ln_ktn_quant_sum;
          ln_ktn_s_unit_price := ln_ktn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_s_unit_price;
--
          ----------------------------------------------------------------
          -- ���_�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_ktn_arari_sum := ln_ktn_s_am_sum - ln_ktn_s_unit_price;
          ln_ktn_arari_sum := ln_ktn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_sum;
--
          ----------------------------------------------------------------
          -- ���_�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          -- �O���Z��𔻒�
          IF (ln_ktn_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_ktn_arari_par := ROUND((ln_ktn_arari_sum / ln_ktn_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_ktn_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_par;
--
          ----------------------------------------------------------------
          -- ���_�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_ktn_price_sum * ln_ktn_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_ktn_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_ktn_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_ktn_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_ktn_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_ktn_price_sum = 0)
            OR (ln_ktn_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
          -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_kake_par;
          END IF;
--
          -- -----------------------------------------------------
          --  ���_�I���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  ���_�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- ���_�敪(���_�R�[�h) �^�O
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).ktn_code;
--
          ----------------------------------------------------------------
          -- ���_�敪(���_����) �^�O
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).party_short_name;
--
          -- -----------------------------------------------------
          --  �Q�R�[�h�J�nL�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  �Q�R�[�h�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  �i�ڊJ�n�k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- �e�u���C�N�L�[�X�V
          lv_ktn_break  := gr_sale_plan_1(i).ktn_code;           -- ���_
          lv_gun_break  := gr_sale_plan_1(i).gun;                -- �Q�R�[�h
          lv_sttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,3);   -- ���Q�v
          lv_mttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,2);   -- ���Q�v
          lv_lttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,1);   -- ��Q�v
--
          -- �׌Q�v�W�v�p���ڏ�����
          ln_nuit_sum         := 0;          -- �{��
          ln_price_sum        := 0;          -- �i�ڒ艿
          ln_arari_sum        := 0;          -- �e��
          ln_s_am_sum         := 0;          -- ���㍂
-- 2009/04/20 v1.8 UPDATE START
--          ln_to_am_sum        := 0;          -- ���󍇌v
          ln_s_unit_price_sum := 0;          -- �W������
          ln_ara_sum          := 0;          -- �e��(�W�v�p)
          ln_chk_0_sum        := 0;          -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_quant_sum        := 0;          -- ����
          -- ���Q�v�W�v�p���ڏ�����
          ln_st_quant_sum     := 0;          -- ����
-- 2009/04/20 v1.8 UPDATE START
--          ln_st_s_u_price_sum := 0;          -- ���󍇌v
          ln_st_s_unit_price_sum := 0;       -- �W������
          ln_st_ara_sum          := 0;       -- �e��(�W�v�p)
          ln_st_chk_0_sum        := 0;       -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_st_arari_sum     := 0;          -- �e��
          ln_st_s_am_sum      := 0;          -- ���㍂
          ln_st_nuit_sum      := 0;          -- �{��
          ln_st_price_sum     := 0;          -- �i�ڒ艿
          -- ���Q�v�W�v�p���ڏ�����
          ln_mt_quant_sum     := 0;          -- ����
-- 2009/04/20 v1.8 UPDATE START
--          ln_mt_s_u_price_sum := 0;          -- ���󍇌v
          ln_mt_s_unit_price_sum := 0;       -- �W������
          ln_mt_ara_sum          := 0;       -- �e��(�W�v�p)
          ln_mt_chk_0_sum        := 0;       -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_mt_arari_sum     := 0;          -- �e��
          ln_mt_s_am_sum      := 0;          -- ���㍂
          ln_mt_nuit_sum      := 0;          -- �{��
          ln_mt_price_sum     := 0;          -- �i�ڒ艿
          -- ��Q�v�W�v�p���ڏ�����
          ln_lt_quant_sum     := 0;          -- ����
-- 2009/04/20 v1.8 UPDATE START
--          ln_lt_s_u_price_sum := 0;          -- ���󍇌v
          ln_lt_s_unit_price_sum := 0;       -- �W������
          ln_lt_ara_sum          := 0;       -- �e��(�W�v�p)
          ln_lt_chk_0_sum        := 0;       -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_lt_arari_sum     := 0;          -- �e��
          ln_lt_s_am_sum      := 0;          -- ���㍂
          ln_lt_nuit_sum      := 0;          -- �{��
          ln_lt_price_sum     := 0;          -- �i�ڒ艿
          -- ���_�v�v�Z�p���ڏ�����
          ln_ktn_arari_sum    := 0;          -- �e��
          ln_ktn_s_am_sum     := 0;          -- ���㍂
          ln_ktn_nuit_sum     := 0;          -- �{��
          ln_ktn_price_sum    := 0;          -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
--          ln_ktn_to_am_sum    := 0;          -- ���󍇌v
          ln_ktn_s_unit_price_sum := 0;      -- �W������
          ln_ktn_ara_sum          := 0;      -- �e��(�W�v�p)
          ln_ktn_chk_0_sum        := 0;      -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_ktn_quant_sum    := 0;          -- ����
        END IF;
--
        -- ====================================================
        --  �Q�R�[�h�u���C�N
        -- ====================================================
        -- �Q�R�[�h���؂�ւ�����Ƃ�
        IF (gr_sale_plan_1(i).gun <> lv_gun_break) THEN
          -- -----------------------------------------------------
          --  �i�ڏI���k�f�^�O�o��
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- �׌Q�v(�W������)�f�[�^
          ----------------------------------------------------------------
          -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
          ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
          ----------------------------------------------------------------
          -- �׌Q�v(�e��)�f�[�^
          ----------------------------------------------------------------
          -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--          ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
          ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
          ----------------------------------------------------------------
          -- �׌Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
          ----------------------------------------------------------------
          -- �O���Z��𔻒�
          IF (ln_s_am_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_syo_arari_par := gn_0;
          END IF;
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
          ----------------------------------------------------------------
          -- �׌Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
          ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
          -- �O���Z���荀�ڂ֔���l��}��
          ln_chk_0 := ln_price_sum * ln_nuit_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_syo_kake_par := gn_0;
          END IF;
*/
          -- �O���Z��𔻒�
          IF (ln_chk_0_sum <> 0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_syo_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
          IF (ln_price_sum = 0)
            OR (ln_syo_kake_par < 0) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
          -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
          END IF;
--
          -- ====================================================
          --  ���Q�v�u���C�N
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan_1(i).gun,1,3) <> lv_sttl_break) THEN
            ----------------------------------------------------------------
            -- ���Q�v(����)�f�[�^
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
            ----------------------------------------------------------------
            -- ���Q�v(���㍂)�f�[�^
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
            ----------------------------------------------------------------
            -- ���Q�v(�W������)�f�[�^
            ----------------------------------------------------------------
            -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
            ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
            ----------------------------------------------------------------
            -- ���Q�v(�e��)�f�[�^
            ----------------------------------------------------------------
            -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
            ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
            ----------------------------------------------------------------
            -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
            ----------------------------------------------------------------
            -- �O���Z��𔻒�
            IF (ln_st_s_am_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_sttl_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
            ----------------------------------------------------------------
            -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- �O���Z���荀�ڂ֔���l��}��
            ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
            -- �O���Z��𔻒�
            IF (ln_chk_0 <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / (ln_chk_0),2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_sttl_kake_par := gn_0;
            END IF;
*/
            -- �O���Z��𔻒�
            IF (ln_st_chk_0_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_sttl_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
            IF (ln_st_price_sum = 0)
              OR (ln_sttl_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
            -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
            END IF;
--
            --  ���Q�v�u���C�N�L�[�X�V
            lv_sttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,3);
--
            -- ���Q�v�W�v�p���ڏ�����
            ln_st_quant_sum     := 0;          -- ����
-- 2009/04/20 v1.8 UPDATE START
--            ln_st_s_u_price_sum := 0;          -- ���󍇌v
            ln_st_s_unit_price_sum := 0;       -- �W������
            ln_st_ara_sum          := 0;       -- �e��(�W�v�p)
            ln_st_chk_0_sum        := 0;       -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
            ln_st_arari_sum     := 0;          -- �e��
            ln_st_s_am_sum      := 0;          -- ���㍂
            ln_st_nuit_sum      := 0;          -- �{��
            ln_st_price_sum     := 0;          -- �i�ڒ艿
          END IF;
--
          -- ====================================================
          --  ���Q�v�u���C�N
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan_1(i).gun,1,2) <> lv_mttl_break) THEN
            ----------------------------------------------------------------
            -- ���Q�v(����)�f�[�^
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
            ----------------------------------------------------------------
            -- ���Q�v(���㍂)�f�[�^
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
            ----------------------------------------------------------------
            -- ���Q�v(�W������)�f�[�^
            ----------------------------------------------------------------
            -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
            ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
            ----------------------------------------------------------------
            -- ���Q�v(�e��)�f�[�^
            ----------------------------------------------------------------
            -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
            ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
            ----------------------------------------------------------------
            -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
            ----------------------------------------------------------------
            -- �O���Z��𔻒�
            IF (ln_mt_s_am_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_mttl_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
            ----------------------------------------------------------------
            -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- �O���Z���荀�ڂ֔���l��}��
            ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
            -- �O���Z��𔻒�
            IF (ln_chk_0 <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_mttl_kake_par := gn_0;
            END IF;
*/
            -- �O���Z��𔻒�
            IF (ln_mt_chk_0_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_mttl_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
            IF (ln_mt_price_sum = 0)
              OR (ln_mttl_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
            -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
            END IF;
--
            --  ���Q�v�u���C�N�L�[�X�V
            lv_mttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,2);
--
            -- ���Q�v�W�v�p���ڏ�����
            ln_mt_quant_sum     := 0;              -- ����
-- 2009/04/20 v1.8 UPDATE START
--            ln_mt_s_u_price_sum := 0;              -- ���󍇌v
            ln_mt_s_unit_price_sum := 0;           -- �W������
            ln_mt_ara_sum          := 0;           -- �e��(�W�v�p)
            ln_mt_chk_0_sum        := 0;           -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
            ln_mt_arari_sum     := 0;              -- �e��
            ln_mt_s_am_sum      := 0;              -- ���㍂
            ln_mt_nuit_sum      := 0;              -- �{��
            ln_mt_price_sum     := 0;              -- �i�ڒ艿
          END IF;
--
          -- ====================================================
          --  ��Q�v�u���C�N
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan_1(i).gun,1,1) <> lv_lttl_break) THEN
            ----------------------------------------------------------------
            -- ��Q�v(����)�f�[�^
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
            ----------------------------------------------------------------
            -- ��Q�v(���㍂)�f�[�^
            ----------------------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
            ----------------------------------------------------------------
            -- ��Q�v(�W������)�f�[�^
            ----------------------------------------------------------------
            -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
            ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
--
            ----------------------------------------------------------------
            -- ��Q�v(�e��)�f�[�^
            ----------------------------------------------------------------
            -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--            ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
            ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
            ----------------------------------------------------------------
            -- ��Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
            ----------------------------------------------------------------
            -- �O���Z��𔻒�
            IF (ln_lt_s_am_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_lttl_arari_par := gn_0;
            END IF;
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
            ----------------------------------------------------------------
            -- ��Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
            ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
            -- �O���Z���荀�ڂ֔���l��}��
            ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
            -- �O���Z��𔻒�
            IF (ln_chk_0 <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_lttl_kake_par
                  := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_lttl_kake_par := gn_0;
            END IF;
*/
            -- �O���Z��𔻒�
            IF (ln_lt_chk_0_sum <> 0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_lttl_kake_par := gn_0;
            END IF;
-- 2009/04/20 v1.8 UPDATE END
--
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
            IF (ln_lt_price_sum = 0)
              OR (ln_lttl_kake_par < 0) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
            -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
            ELSE
              gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
            END IF;
--
            --  ��Q�v�u���C�N�L�[�X�V
            lv_lttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,1);
--
            -- ��Q�v�W�v�p���ڏ�����
            ln_lt_quant_sum     := 0;              -- ����
-- 2009/04/20 v1.8 UPDATE START
--            ln_lt_s_u_price_sum := 0;              -- ���󍇌v
            ln_lt_s_unit_price_sum := 0;           -- �W������
            ln_lt_ara_sum          := 0;           -- �e��(�W�v�p)
            ln_lt_chk_0_sum        := 0;           -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
            ln_lt_arari_sum     := 0;              -- �e��
            ln_lt_s_am_sum      := 0;              -- ���㍂
            ln_lt_nuit_sum      := 0;              -- �{��
            ln_lt_price_sum     := 0;              -- �i�ڒ艿
          END IF;
--
          -- -----------------------------------------------------
          --  �Q�R�[�h�I���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  �Q�R�[�h�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  �i�ڊJ�n�k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          --  �Q�R�[�h�u���C�N�L�[�X�V
          lv_gun_break  := gr_sale_plan_1(i).gun;
--
          -- �׌Q�v�W�v�p���ڏ�����
          ln_nuit_sum   := 0;         -- �{��
          ln_price_sum  := 0;         -- �i�ڒ艿
          ln_arari_sum  := 0;         -- �e��
          ln_s_am_sum   := 0;         -- ���㍂
-- 2009/04/20 v1.8 UPDATE START
--          ln_to_am_sum  := 0;         -- ���󍇌v
          ln_s_unit_price_sum := 0;   -- �W������
          ln_ara_sum          := 0;   -- �e��(�W�v�p)
          ln_chk_0_sum        := 0;   -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
          ln_quant_sum  := 0;         -- ����
        END IF;
--
        -- -----------------------------------------------------
        --  �i�ڊJ�n�f�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        ----------------------------------------------------------------
        -- �Q�R�[�h�f�[�^
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'gun_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).gun;
--
        ----------------------------------------------------------------
        -- �i��(�R�[�h)�f�[�^
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).item_no;
--
        ----------------------------------------------------------------
        -- �i��(����)�f�[�^
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).item_short_name;
--
        ----------------------------------------------------------------
        -- �����f�[�^
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'case_quant';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gr_sale_plan_1(i).case_quant);
--
        ----------------------------------------------------------------
        -- ���ʃf�[�^
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quant';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        -- �o�͒P�ʂ��u�{���v�̏ꍇ
        IF (gr_param.output_unit = gv_output_unit) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gr_sale_plan_1(i).quant);
        -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
        ELSE
          -- �O���Z��𔻒�
          IF (TO_NUMBER(gr_sale_plan_1(i).case_quant) <> 0) THEN
            -- �l��[0]�o�Ȃ���΁A���ʌv�Z  (���� / ����)
            ln_output_unit 
                   := TO_NUMBER(gr_sale_plan_1(i).quant) / TO_NUMBER(gr_sale_plan_1(i).case_quant);
            ln_output_unit := CEIL(ln_output_unit);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_output_unit := gn_0;
          END IF;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_output_unit;
        END IF;
--
        ----------------------------------------------------------------
        -- ���㍂�f�[�^
        ----------------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sales_amount';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gr_sale_plan_1(i).amount);
--
        ----------------------------------------------------------------
        -- �W�������f�[�^ (���󍇌v * ����)
        ----------------------------------------------------------------
        ln_s_u_price 
            := TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant);
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_unit_price';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := ln_s_u_price;
--
        ----------------------------------------------------------------
        -- �e���f�[�^ (���z - ���󍇌v * ����)
        ----------------------------------------------------------------
        ln_arari := TO_NUMBER(gr_sale_plan_1(i).amount) - ln_s_u_price;
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arari';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := ln_arari;
--
        ----------------------------------------------------------------
        -- �e����(%)�f�[�^  ((���z - ���󍇌v * ����) / ���z * 100)
        ----------------------------------------------------------------
        -- �O���Z��𔻒�
        IF (TO_NUMBER(gr_sale_plan_1(i).amount) <> 0) THEN
          -- �l��[0]�o�Ȃ���Όv�Z
          ln_arari_par := ROUND((ln_arari / TO_NUMBER(gr_sale_plan_1(i).amount) * 100),2);
        ELSE
          -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
          ln_skbn_arari_par := gn_0;
        END IF;
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arari_par';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_par;
--
        ----------------------------------------------------------------
        -- �|��(%)�f�[�^ ((���z * 100) / (�i�ڒ艿 * ����))
        ----------------------------------------------------------------
        -- �艿�K�p�J�n���ɂċ��艿�E�V�艿�̎g�p���f
        -- �N�x�J�n������OPM�i�ڃ}�X�^�艿�K�p�J�n���ȏ�̏ꍇ
        IF (FND_DATE.STRING_TO_DATE(gr_sale_plan_1(i).price_st,'YYYY/MM/DD')   <= gd_start_day) THEN
          -- �V�艿���g�p
          ln_price := TO_NUMBER(gr_sale_plan_1(i).n_amount);
        -- �N�x�J�n������OPM�i�ڃ}�X�^�艿�K�p�J�n�������̏ꍇ
        ELSIF (FND_DATE.STRING_TO_DATE(gr_sale_plan_1(i).price_st,'YYYY/MM/DD') > gd_start_day) THEN
          -- ���艿���g�p
          ln_price := TO_NUMBER(gr_sale_plan_1(i).o_amount);
        END IF;
--
        -- �O���Z���荀�ڂ֔���l��}��
--2008.04.30 Y.Kawano modify start
--        ln_chk_0 := ln_price * TO_NUMBER(gr_sale_plan_1(i).quant) * 100;
        ln_chk_0 := ln_price * TO_NUMBER(gr_sale_plan_1(i).quant);
--2008.04.30 Y.Kawano modify end
        -- �O���Z��𔻒�
        IF (ln_chk_0 <> 0) THEN
          -- �l��[0]�o�Ȃ���Όv�Z
--2008.04.30 Y.Kawano modify start
--          ln_kake_par := ROUND(TO_NUMBER(gr_sale_plan_1(i).amount) / ln_chk_0,2);
          ln_kake_par := ROUND((TO_NUMBER(gr_sale_plan_1(i).amount) * 100) / ln_chk_0,2);
--2008.04.30 Y.Kawano modify end
        ELSE
          -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
          ln_kake_par := gn_0;
        END IF;
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kake_par';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
        IF (ln_price = 0)
          OR (ln_kake_par < 0) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
        -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
        END IF;
--
        -- -----------------------------------------------------
        --  �i�ڏI���f�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- �׌Q�v�Ɏg�p���鍀�ڂ�SUM
        ln_s_am_sum   := ln_s_am_sum  + TO_NUMBER(gr_sale_plan_1(i).amount);   -- ���㍂
        ln_nuit_sum   := ln_nuit_sum  + TO_NUMBER(gr_sale_plan_1(i).quant);    -- �{��
        ln_price_sum  := ln_price_sum + ln_price;                              -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_to_am_sum  := ln_to_am_sum + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- ���󍇌v
*/
        -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
        ln_s_unit_price_sum := ln_s_unit_price_sum + ln_s_u_price;             -- �W������
        ln_ara_sum          := ln_ara_sum + ln_arari;                          -- �e��(�W�v�p)
        ln_chk_0_sum        := ln_chk_0_sum + ln_chk_0;                        -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
        -- �o�͒P�ʂ��u�{���v�̏ꍇ
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_quant_sum    := ln_quant_sum    + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- ����
        -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
        ELSE
          ln_quant_sum    := ln_quant_sum    + ln_output_unit;                 -- ����
        END IF;
--
        -- ���Q�v�Ɏg�p���鍀�ڂ�SUM
        -- �o�͒P�ʂ��u�{���v�̏ꍇ
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_st_quant_sum   := ln_st_quant_sum     + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- ����
        -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
        ELSE
          ln_st_quant_sum   := ln_st_quant_sum     + ln_output_unit;           -- ����
        END IF;
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_st_s_u_price_sum := ln_st_s_u_price_sum + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- ���󍇌v
*/
        -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
        ln_st_s_unit_price_sum  := ln_st_s_unit_price_sum + ln_s_u_price;      -- �W������
        ln_st_ara_sum           := ln_st_ara_sum + ln_arari;                   -- �e��(�W�v�p)
        ln_st_chk_0_sum         := ln_st_chk_0_sum + ln_chk_0;                 -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
        ln_st_s_am_sum      := ln_st_s_am_sum      + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                               -- ���㍂
        ln_st_nuit_sum      := ln_st_nuit_sum      + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- �{��
        ln_st_price_sum     := ln_st_price_sum     + ln_price;                 -- �i�ڒ艿
--
        -- ���Q�v�Ɏg�p���鍀�ڂ�SUM
        -- �o�͒P�ʂ��u�{���v�̏ꍇ
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_mt_quant_sum   := ln_mt_quant_sum     + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- ����
        -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
        ELSE
          ln_mt_quant_sum   := ln_mt_quant_sum     + ln_output_unit;           -- ����
        END IF;
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_mt_s_u_price_sum := ln_mt_s_u_price_sum + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- ���󍇌v
*/
        -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
        ln_mt_s_unit_price_sum  := ln_mt_s_unit_price_sum + ln_s_u_price;      -- �W������
        ln_mt_ara_sum           := ln_mt_ara_sum + ln_arari;                   -- �e��(�W�v�p)
        ln_mt_chk_0_sum         := ln_mt_chk_0_sum + ln_chk_0;                 -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
        ln_mt_s_am_sum      := ln_mt_s_am_sum      + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                               -- ���㍂
        ln_mt_nuit_sum      := ln_mt_nuit_sum      + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- �{��
        ln_mt_price_sum     := ln_mt_price_sum     + ln_price;                 -- �i�ڒ艿
--
        -- ��Q�v�Ɏg�p���鍀�ڂ�SUM
        -- �o�͒P�ʂ��u�{���v�̏ꍇ
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_lt_quant_sum   := ln_lt_quant_sum     + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- ����
        -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
        ELSE
          ln_lt_quant_sum   := ln_lt_quant_sum     + ln_output_unit;           -- ����
        END IF;
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_lt_s_u_price_sum := ln_lt_s_u_price_sum + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- ���󍇌v
*/
        -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
        ln_lt_s_unit_price_sum  := ln_lt_s_unit_price_sum + ln_s_u_price;      -- �W������
        ln_lt_ara_sum           := ln_lt_ara_sum + ln_arari;                   -- �e��(�W�v�p)
        ln_lt_chk_0_sum         := ln_lt_chk_0_sum + ln_chk_0;                 -- �|��(�W�v�p)-- 2009/04/20 v1.8 UPDATE END
-- 2009/04/20 v1.8 UPDATE END
        ln_lt_s_am_sum      := ln_lt_s_am_sum      + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                               -- ���㍂
        ln_lt_nuit_sum      := ln_lt_nuit_sum      + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- �{��
        ln_lt_price_sum     := ln_lt_price_sum     + ln_price;                 -- �i�ڒ艿
--
        -- ���i�敪�v�Ɏg�p���鍀�ڂ�SUM
        ln_skbn_s_am_sum    := ln_skbn_s_am_sum    + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                               -- ���㍂
        ln_skbn_nuit_sum    := ln_skbn_nuit_sum    + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- �{��
        ln_skbn_price_sum   := ln_skbn_price_sum   + ln_price;                 -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_ktn_to_am_sum    := ln_ktn_to_am_sum    + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- ���󍇌v
*/
        -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
        ln_skbn_s_unit_price_sum  := ln_skbn_s_unit_price_sum + ln_s_u_price;  -- �W������
        ln_skbn_ara_sum           := ln_skbn_ara_sum + ln_arari;               -- �e��(�W�v�p)
        ln_skbn_chk_0_sum         := ln_skbn_chk_0_sum + ln_chk_0;             -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
        -- �o�͒P�ʂ��u�{���v�̏ꍇ
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_ktn_quant_sum   := ln_ktn_quant_sum   + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- ����
        -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
        ELSE
          ln_ktn_quant_sum   := ln_ktn_quant_sum   + ln_output_unit;           -- ����
        END IF;
--
        -- ���_�v�Ɏg�p���鍀�ڂ�SUM
        ln_ktn_s_am_sum     := ln_ktn_s_am_sum     + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                               -- ���㍂
        ln_ktn_nuit_sum     := ln_ktn_nuit_sum     + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- �{��
        ln_ktn_price_sum    := ln_ktn_price_sum    + ln_price;                 -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_skbn_to_am_sum   := ln_skbn_to_am_sum   + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- ���󍇌v
*/
        -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
        ln_ktn_s_unit_price_sum := ln_ktn_s_unit_price_sum + ln_s_u_price;    -- �W������
        ln_ktn_ara_sum          := ln_ktn_ara_sum + ln_arari;                 -- �e��
        ln_ktn_chk_0_sum        := ln_ktn_chk_0_sum + ln_chk_0;               -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
        -- �o�͒P�ʂ��u�{���v�̏ꍇ
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_skbn_quant_sum   := ln_skbn_quant_sum + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- ����
        -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
        ELSE
          ln_skbn_quant_sum   := ln_skbn_quant_sum + ln_output_unit;           -- ����
        END IF;
--
        -- �����v�Ɏg�p���鍀�ڂ�SUM
        ln_to_s_am_sum      := ln_to_s_am_sum      + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                               -- ���㍂
        ln_to_nuit_sum      := ln_to_nuit_sum      + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- �{��
        ln_to_price_sum     := ln_to_price_sum     + ln_price;                 -- �i�ڒ艿
-- 2009/04/20 v1.8 UPDATE START
/*
        ln_to_to_am_sum     := ln_to_to_am_sum     + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                               -- ���󍇌v
*/
        -- ���ׂ��Ƃ̌v�Z���ʂ𑫂�����
        ln_to_s_unit_price_sum  := ln_to_s_unit_price_sum + ln_s_u_price;      -- �W������
        ln_to_ara_sum           := ln_to_ara_sum + ln_arari;                   -- �e��(�W�v�p)
        ln_to_chk_0_sum         := ln_to_chk_0_sum + ln_chk_0;                 -- �|��(�W�v�p)
-- 2009/04/20 v1.8 UPDATE END
        -- �o�͒P�ʂ��u�{���v�̏ꍇ
        IF (gr_param.output_unit = gv_output_unit) THEN
          ln_to_quant_sum   := ln_to_quant_sum     + TO_NUMBER(gr_sale_plan_1(i).quant);
                                                                               -- ����
        -- �o�͒P�ʂ��u�P�[�X�v�̏ꍇ
        ELSE
          ln_to_quant_sum   := ln_to_quant_sum     + ln_output_unit;           -- ����
        END IF;
--
      END LOOP main_data_loop_1;
--
      -- =====================================================
      --    �I������
      -- =====================================================
      -- -----------------------------------------------------
      --  �i�ڏI���k�f�^�O�o��
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      ----------------------------------------------------------------
      -- �׌Q�v(�W������)�f�[�^
      ----------------------------------------------------------------
      -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_syo_s_unit_price := ln_to_am_sum * ln_quant_sum;
      ln_syo_s_unit_price := ln_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_s_unit_price;
--
      ----------------------------------------------------------------
      -- �׌Q�v(�e��)�f�[�^
      ----------------------------------------------------------------
      -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
      ln_arari_sum := ln_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_arari_sum;
--
      ----------------------------------------------------------------
      -- �׌Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
      ----------------------------------------------------------------
      -- �O���Z��𔻒�
      IF (ln_s_am_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_syo_arari_par := ROUND((ln_arari_sum / ln_s_am_sum) * 100,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_syo_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_arari_par;
--
      ----------------------------------------------------------------
      -- �׌Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- �O���Z���荀�ڂ֔���l��}��
      ln_chk_0 := ln_price_sum * ln_nuit_sum;
      -- �O���Z��𔻒�
      IF (ln_chk_0 <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_syo_arari_par := gn_0;
      END IF;
*/
      -- �O���Z��𔻒�
      IF (ln_chk_0_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_syo_kake_par := ROUND((ln_s_am_sum * 100) / ln_chk_0_sum, 2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_syo_kake_par := gn_0;
      END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'syo_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
      IF (ln_price_sum = 0) 
        OR (ln_syo_kake_par < 0)THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
      -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_syo_kake_par;
      END IF;
--
      ----------------------------------------------------------------
      -- ���Q�v(����)�f�[�^
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_st_quant_sum;
--
      ----------------------------------------------------------------
      -- ���Q�v(���㍂)�f�[�^
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_sales_amount';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_st_s_am_sum;
--
      ----------------------------------------------------------------
      -- ���Q�v(�W������)�f�[�^
      ----------------------------------------------------------------
      -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_sttl_s_unit_price := ln_st_s_u_price_sum * ln_st_quant_sum;
      ln_sttl_s_unit_price := ln_st_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_s_unit_price;
--
      ----------------------------------------------------------------
      -- ���Q�v(�e��)�f�[�^
      ----------------------------------------------------------------
      -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_st_arari_sum := ln_s_am_sum - ln_syo_s_unit_price;
      ln_st_arari_sum := ln_st_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_st_arari_sum;
--
      ----------------------------------------------------------------
      -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
      ----------------------------------------------------------------
      -- �O���Z��𔻒�
      IF (ln_st_s_am_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_sttl_arari_par := ROUND((ln_st_arari_sum / ln_st_s_am_sum) * 100,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_sttl_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_arari_par;
--
      ----------------------------------------------------------------
      -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- �O���Z���荀�ڂ֔���l��}��
      ln_chk_0 := ln_st_price_sum * ln_st_nuit_sum;
      -- �O���Z��𔻒�
      IF (ln_chk_0 <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_sttl_kake_par := gn_0;
      END IF;
*/
      -- �O���Z��𔻒�
      IF (ln_st_chk_0_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_sttl_kake_par := ROUND((ln_st_s_am_sum * 100) / ln_st_chk_0_sum, 2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_sttl_kake_par := gn_0;
      END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sttl_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
      IF (ln_st_price_sum = 0)
        OR (ln_sttl_kake_par < 0) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
        -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_sttl_kake_par;
      END IF;
--
      ----------------------------------------------------------------
      -- ���Q�v(����)�f�[�^
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_quant_sum;
--
      ----------------------------------------------------------------
      -- ���Q�v(���㍂)�f�[�^
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_sales_amount';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_s_am_sum;
--
      ----------------------------------------------------------------
      -- ���Q�v(�W������)�f�[�^
      ----------------------------------------------------------------
      -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_mttl_s_unit_price := ln_mt_s_u_price_sum * ln_mt_quant_sum;
      ln_mttl_s_unit_price := ln_mt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_s_unit_price;
--
      ----------------------------------------------------------------
      -- ���Q�v(�e��)�f�[�^
      ----------------------------------------------------------------
      -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_mt_arari_sum := ln_mt_s_am_sum - ln_mttl_s_unit_price;
      ln_mt_arari_sum := ln_mt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_mt_arari_sum;
--
      ----------------------------------------------------------------
      -- ���Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
      ----------------------------------------------------------------
      --  �O���Z��𔻒�
      IF (ln_mt_s_am_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_mttl_arari_par := ROUND((ln_mt_arari_sum / ln_mt_s_am_sum) * 100,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_mttl_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_arari_par;
--
      ----------------------------------------------------------------
      -- ���Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- �O���Z���荀�ڂ֔���l��}��
      ln_chk_0 := ln_mt_price_sum * ln_mt_nuit_sum;
      -- �O���Z��𔻒�
      IF (ln_chk_0 <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_mttl_kake_par := gn_0;
      END IF;
*/
      -- �O���Z��𔻒�
      IF (ln_mt_chk_0_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_mttl_kake_par := ROUND((ln_mt_s_am_sum * 100) / ln_mt_chk_0_sum, 2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_mttl_kake_par := gn_0;
      END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'mttl_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
      IF (ln_mt_price_sum = 0)
        OR (ln_mttl_kake_par < 0) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
      -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_mttl_kake_par;
      END IF;
--
      ----------------------------------------------------------------
      -- ��Q�v(����)�f�[�^
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_quant_sum;
--
      ----------------------------------------------------------------
      -- ��Q�v(���㍂)�f�[�^
      ----------------------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_sales_amount';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_s_am_sum;
--
      ----------------------------------------------------------------
      -- ��Q�v(�W������)�f�[�^
      ----------------------------------------------------------------
      -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_lttl_s_unit_price := ln_lt_s_u_price_sum * ln_lt_quant_sum;
      ln_lttl_s_unit_price := ln_lt_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_s_unit_price;
--
      ----------------------------------------------------------------
      -- ��Q�v(�e��)�f�[�^
      ----------------------------------------------------------------
      -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_lt_arari_sum := ln_lt_s_am_sum - ln_lttl_s_unit_price;
      ln_lt_arari_sum := ln_lt_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_lt_arari_sum;
--
      ----------------------------------------------------------------
      -- ��Q�v(�e����)�f�[�^  ((�e��/���㍂)*100)
      ----------------------------------------------------------------
      -- �O���Z��𔻒�
      IF (ln_lt_s_am_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_lttl_arari_par := ROUND((ln_lt_arari_sum / ln_lt_s_am_sum) * 100,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_lttl_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_arari_par;
--
      ----------------------------------------------------------------
      -- ��Q�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- �O���Z���荀�ڂ֔���l��}��
      ln_chk_0 := ln_lt_price_sum * ln_lt_nuit_sum;
      -- �O���Z��𔻒�
      IF (ln_chk_0 <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_lttl_kake_par := gn_0;
      END IF;
*/
      -- �O���Z��𔻒�
      IF (ln_lt_chk_0_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_lttl_kake_par := ROUND((ln_lt_s_am_sum * 100) / ln_lt_chk_0_sum, 2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_lttl_kake_par := gn_0;
      END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lttl_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
      IF (ln_lt_price_sum = 0)
        OR (ln_lttl_kake_par < 0) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
      -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_lttl_kake_par;
      END IF;
--
      -- -----------------------------------------------------
      --  �Q�R�[�h�I���f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  �Q�R�[�h�I���k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      ----------------------------------------------------------------
      -- ���_�v(�W������)�f�[�^
      ----------------------------------------------------------------
      -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_ktn_s_unit_price := ln_ktn_to_am_sum * ln_ktn_quant_sum;
      ln_ktn_s_unit_price := ln_ktn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_s_unit_price;
--
      ----------------------------------------------------------------
      -- ���_�v(�e��)�f�[�^
      ----------------------------------------------------------------
      -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_ktn_arari_sum := ln_ktn_s_am_sum - ln_ktn_s_unit_price;
      ln_ktn_arari_sum := ln_ktn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_sum;
--
      ----------------------------------------------------------------
      -- ���_�v(�e����)�f�[�^  ((�e��/���㍂)*100)
      ----------------------------------------------------------------
      -- �O���Z��𔻒�
      IF (ln_ktn_s_am_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_ktn_arari_par := ROUND((ln_ktn_arari_sum / ln_ktn_s_am_sum) * 100,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_ktn_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_arari_par;
--
      ----------------------------------------------------------------
      -- ���_�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- �O���Z���荀�ڂ֔���l��}��
      ln_chk_0 := ln_ktn_price_sum * ln_ktn_nuit_sum;
      -- �O���Z��𔻒�
      IF (ln_chk_0 <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_ktn_kake_par := gn_0;
      END IF;
*/
      -- �O���Z��𔻒�
      IF (ln_ktn_chk_0_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_ktn_kake_par := ROUND((ln_ktn_s_am_sum * 100) / ln_ktn_chk_0_sum, 2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_ktn_kake_par := gn_0;
      END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
      IF (ln_ktn_price_sum = 0)
        OR (ln_ktn_kake_par < 0) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
      -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_ktn_kake_par;
      END IF;
--
      -- -----------------------------------------------------
      --  ���_�I���f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  ���_�I���k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      ----------------------------------------------------------------
      -- ���i�敪�v(�W������)�f�[�^
      ----------------------------------------------------------------
      -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_skbn_s_unit_price := ln_skbn_to_am_sum * ln_skbn_quant_sum;
      ln_skbn_s_unit_price := ln_skbn_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_s_unit_price;
--
      ----------------------------------------------------------------
      -- ���i�敪�v(�e��)�f�[�^
      ----------------------------------------------------------------
      -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_skbn_arari_sum := ln_skbn_s_am_sum - ln_skbn_s_unit_price;
      ln_skbn_arari_sum := ln_skbn_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_sum;
--
      ----------------------------------------------------------------
      -- ���i�敪�v(�e����)�f�[�^  ((�e��/���㍂)*100)
      ----------------------------------------------------------------
      -- �O���Z��𔻒�
      IF (ln_skbn_s_am_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_skbn_arari_par := ROUND((ln_skbn_arari_sum / ln_skbn_s_am_sum) * 100,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_skbn_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_arari_par;
--
      ----------------------------------------------------------------
      -- ���i�敪�v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- �O���Z���荀�ڂ֔���l��}��
      ln_chk_0 := ln_skbn_price_sum * ln_skbn_nuit_sum;
      -- �O���Z��𔻒�
      IF (ln_chk_0 <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_skbn_kake_par := gn_0;
      END IF;
*/
      -- �O���Z��𔻒�
      IF (ln_skbn_chk_0_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_skbn_kake_par := ROUND((ln_skbn_s_am_sum * 100) / ln_skbn_chk_0_sum, 2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_skbn_kake_par := gn_0;
          END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
      IF (ln_skbn_price_sum = 0)
        OR (ln_skbn_kake_par < 0) THEN
        gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
      -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_skbn_kake_par;
      END IF;
--
      ----------------------------------------------------------------
      -- �����v(�W������)�f�[�^
      ----------------------------------------------------------------
      -- �W�������Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_to_s_unit_price := ln_to_to_am_sum * ln_to_quant_sum;
      ln_to_s_unit_price := ln_to_s_unit_price_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'to_s_unit_price';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_to_s_unit_price;
--
      ----------------------------------------------------------------
      -- �����v(�e��)�f�[�^
      ----------------------------------------------------------------
      -- �e���Z�o
-- 2009/04/20 v1.8 UPDATE START
--      ln_to_arari_sum := ln_to_s_am_sum - ln_to_s_unit_price;
      ln_to_arari_sum := ln_to_ara_sum;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'to_arari';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_to_arari_sum;
--
      ----------------------------------------------------------------
      -- �����v(�e����)�f�[�^  ((�e��/���㍂)*100)
      ----------------------------------------------------------------
      -- �O���Z��𔻒�
      IF (ln_to_s_am_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_to_arari_par := ROUND((ln_to_arari_sum / ln_to_s_am_sum) * 100,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_to_arari_par := gn_0;
      END IF;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'to_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_to_arari_par;
--
      ----------------------------------------------------------------
      -- �����v(�|��)�f�[�^  ((���㍂*100)/(�i�ڒ艿*�{��))
      ----------------------------------------------------------------
-- 2009/04/20 v1.8 UPDATE START
/*
      -- �O���Z���荀�ڂ֔���l��}��
      ln_chk_0 := ln_to_price_sum * ln_to_nuit_sum;
      -- �O���Z��𔻒�
      IF (ln_chk_0 <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_to_kake_par := ROUND((ln_to_s_am_sum * 100) / ln_chk_0,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_to_kake_par := gn_0;
      END IF;
*/
      -- �O���Z��𔻒�
      IF (ln_to_chk_0_sum <> 0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_to_kake_par := ROUND((ln_to_s_am_sum * 100) / ln_to_chk_0_sum, 2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_to_kake_par := gn_0;
      END IF;
-- 2009/04/20 v1.8 UPDATE END
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'to_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l��o�^
      IF (ln_to_price_sum = 0)
        OR (ln_to_kake_par < 0) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := TO_NUMBER(gv_name_kotei); -- �Œ�l:70.00
      -- �i�ڒ艿 <> �O�A�v�Z���ʂ��}�C�i�X�ł͂Ȃ��ꍇ�A�v�Z���ʂ�o�^
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_value := ln_to_kake_par;
      END IF;
--
      -- -----------------------------------------------------
      --  ���i�敪�I���f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  ���i�敪�I���k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_skbn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- �f�[�^�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- ���[�g�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/root';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
    END IF;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gv_application
                                             ,gv_err_code_no_data
                                            );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_create_xml_data;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : XML�f�[�^�ϊ�
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name    IN   VARCHAR2
     ,iv_value   IN   VARCHAR2
     ,ic_type    IN   CHAR
    ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'convert_into_xml'; -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_convert_data   VARCHAR2(2000);
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
  END convert_into_xml;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_year           IN    VARCHAR2     --   01.�N�x
     ,iv_prod_div       IN    VARCHAR2     --   02.���i�敪
     ,iv_gen            IN    VARCHAR2     --   03.����
     ,iv_output_unit    IN    VARCHAR2     --   04.�o�͒P��
     ,iv_output_type    IN    VARCHAR2     --   05.�o�͎��
     ,iv_base_01        IN    VARCHAR2     --   06.���_�P
     ,iv_base_02        IN    VARCHAR2     --   07.���_�Q
     ,iv_base_03        IN    VARCHAR2     --   08.���_�R
     ,iv_base_04        IN    VARCHAR2     --   09.���_�S
     ,iv_base_05        IN    VARCHAR2     --   10.���_�T
     ,iv_base_06        IN    VARCHAR2     --   11.���_�U
     ,iv_base_07        IN    VARCHAR2     --   12.���_�V
     ,iv_base_08        IN    VARCHAR2     --   13.���_�W
     ,iv_base_09        IN    VARCHAR2     --   14.���_�X
     ,iv_base_10        IN    VARCHAR2     --   15.���_�P�O
     ,iv_crowd_code_01  IN    VARCHAR2     --   16.�Q�R�[�h�P
     ,iv_crowd_code_02  IN    VARCHAR2     --   17.�Q�R�[�h�Q
     ,iv_crowd_code_03  IN    VARCHAR2     --   18.�Q�R�[�h�R
     ,iv_crowd_code_04  IN    VARCHAR2     --   19.�Q�R�[�h�S
     ,iv_crowd_code_05  IN    VARCHAR2     --   20.�Q�R�[�h�T
     ,iv_crowd_code_06  IN    VARCHAR2     --   21.�Q�R�[�h�U
     ,iv_crowd_code_07  IN    VARCHAR2     --   22.�Q�R�[�h�V
     ,iv_crowd_code_08  IN    VARCHAR2     --   23.�Q�R�[�h�W
     ,iv_crowd_code_09  IN    VARCHAR2     --   24.�Q�R�[�h�X
     ,iv_crowd_code_10  IN    VARCHAR2     --   25.�Q�R�[�h�P�O
     ,ov_errbuf         OUT   VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT   VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT   VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_xml_string    VARCHAR2(32000);
    ln_retcode       NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- -----------------------------------------------------
    -- �p�����[�^�i�[
    -- -----------------------------------------------------
    gr_param.year          := iv_year;          -- �N�x
    gr_param.prod_div      := iv_prod_div;      -- ���i�敪
    gr_param.gen           := iv_gen;           -- ����
    gr_param.output_unit   := iv_output_unit;   -- �o�͒P��
    gr_param.output_type   := iv_output_type;   -- �o�͎��
    gr_param.base_01       := iv_base_01;       -- ���_�P
    gr_param.base_02       := iv_base_02;       -- ���_�Q
    gr_param.base_03       := iv_base_03;       -- ���_�R
    gr_param.base_04       := iv_base_04;       -- ���_�S
    gr_param.base_05       := iv_base_05;       -- ���_�T
    gr_param.base_06       := iv_base_06;       -- ���_�U
    gr_param.base_07       := iv_base_07;       -- ���_�V
    gr_param.base_08       := iv_base_08;       -- ���_�W
    gr_param.base_09       := iv_base_09;       -- ���_�X
    gr_param.base_10       := iv_base_10;       -- ���_�P�O
    gr_param.crowd_code_01 := iv_crowd_code_01; -- �Q�R�[�h�P
    gr_param.crowd_code_02 := iv_crowd_code_02; -- �Q�R�[�h�Q
    gr_param.crowd_code_03 := iv_crowd_code_03; -- �Q�R�[�h�R
    gr_param.crowd_code_04 := iv_crowd_code_04; -- �Q�R�[�h�S
    gr_param.crowd_code_05 := iv_crowd_code_05; -- �Q�R�[�h�T
    gr_param.crowd_code_06 := iv_crowd_code_06; -- �Q�R�[�h�U
    gr_param.crowd_code_07 := iv_crowd_code_07; -- �Q�R�[�h�V
    gr_param.crowd_code_08 := iv_crowd_code_08; -- �Q�R�[�h�W
    gr_param.crowd_code_09 := iv_crowd_code_09; -- �Q�R�[�h�X
    gr_param.crowd_code_10 := iv_crowd_code_10; -- �Q�R�[�h�P�O
--
    -- =====================================================
    -- �f�[�^�擾 - �J�X�^���I�v�V�����擾  (B-1-0)
    -- =====================================================
    pro_get_cus_option
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- XML �^�O�o�� - ���[�U��񕔕�(user_info)
    -- =====================================================
    prc_create_xml_data_user
      (
        ov_errbuf        => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode       => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg        => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- XML �^�O�o�� - �p�����[�^��񕔕�(param_info)
    -- =====================================================
    prc_create_xml_data_param
      (
        ov_errbuf        => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode       => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg        => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- XML�f�[�^�쐬 - ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- XML�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>');
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF (lv_errmsg IS NOT NULL)
      AND (lv_retcode = gv_status_warn)THEN
      -- --------------------------------------------------
      -- ���b�Z�[�W�̐ݒ�
      -- --------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<root>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <data_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <lg_skbn_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <g_skbn>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <lg_ktn_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <g_ktn>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <lg_gun_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <g_gun>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <msg>' || lv_errmsg || '</msg>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </g_gun>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </lg_gun_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </g_ktn>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </lg_ktn_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </g_skbn>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </lg_skbn_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </data_info>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</root>');
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- XML�f�[�^���o��
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        lv_xml_string := convert_into_xml
                           (
                             iv_name   =>  gt_xml_data_table(i).tag_name
                            ,iv_value  =>  gt_xml_data_table(i).tag_value
                            ,ic_type   =>  gt_xml_data_table(i).tag_type
                           );
        -- XML�^�O�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string);
      END LOOP xml_data_table;
--
    END IF;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
    ov_errbuf  := lv_errbuf;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main
    (
      errbuf           OUT    VARCHAR2      --   �G���[���b�Z�[�W
     ,retcode          OUT    VARCHAR2      --   �G���[�R�[�h
     ,iv_year          IN     VARCHAR2      --   01.�N�x
     ,iv_prod_div      IN     VARCHAR2      --   02.���i�敪
     ,iv_gen           IN     VARCHAR2      --   03.����
     ,iv_output_unit   IN     VARCHAR2      --   04.�o�͒P��
     ,iv_output_type   IN     VARCHAR2      --   05.�o�͎��
     ,iv_base_01       IN     VARCHAR2      --   06.���_�P
     ,iv_base_02       IN     VARCHAR2      --   07.���_�Q
     ,iv_base_03       IN     VARCHAR2      --   08.���_�R
     ,iv_base_04       IN     VARCHAR2      --   09.���_�S
     ,iv_base_05       IN     VARCHAR2      --   10.���_�T
     ,iv_base_06       IN     VARCHAR2      --   11.���_�U
     ,iv_base_07       IN     VARCHAR2      --   12.���_�V
     ,iv_base_08       IN     VARCHAR2      --   13.���_�W
     ,iv_base_09       IN     VARCHAR2      --   14.���_�X
     ,iv_base_10       IN     VARCHAR2      --   15.���_�P�O
     ,iv_crowd_code_01 IN     VARCHAR2      --   16.�Q�R�[�h�P
     ,iv_crowd_code_02 IN     VARCHAR2      --   17.�Q�R�[�h�Q
     ,iv_crowd_code_03 IN     VARCHAR2      --   18.�Q�R�[�h�R
     ,iv_crowd_code_04 IN     VARCHAR2      --   19.�Q�R�[�h�S
     ,iv_crowd_code_05 IN     VARCHAR2      --   20.�Q�R�[�h�T
     ,iv_crowd_code_06 IN     VARCHAR2      --   21.�Q�R�[�h�U
     ,iv_crowd_code_07 IN     VARCHAR2      --   22.�Q�R�[�h�V
     ,iv_crowd_code_08 IN     VARCHAR2      --   23.�Q�R�[�h�W
     ,iv_crowd_code_09 IN     VARCHAR2      --   24.�Q�R�[�h�X
     ,iv_crowd_code_10 IN     VARCHAR2      --   25.�Q�R�[�h�P�O
    )
  IS
--
--###########################  �Œ蕔 START   ###########################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain
    (
      iv_year          => iv_year           -- 01.�N�x
     ,iv_prod_div      => iv_prod_div       -- 02.���i�敪
     ,iv_gen           => iv_gen            -- 03.����
     ,iv_output_unit   => iv_output_unit    -- 04.�o�͒P��
     ,iv_output_type   => iv_output_type    -- 05.�o�͎��
     ,iv_base_01       => iv_base_01        -- 06.���_�P
     ,iv_base_02       => iv_base_02        -- 07.���_�Q
     ,iv_base_03       => iv_base_03        -- 08.���_�R
     ,iv_base_04       => iv_base_04        -- 09.���_�S
     ,iv_base_05       => iv_base_05        -- 10.���_�T
     ,iv_base_06       => iv_base_06        -- 11.���_�U
     ,iv_base_07       => iv_base_07        -- 12.���_�V
     ,iv_base_08       => iv_base_08        -- 13.���_�W
     ,iv_base_09       => iv_base_09        -- 14.���_�X
     ,iv_base_10       => iv_base_10        -- 15.���_�P�O
     ,iv_crowd_code_01 => iv_crowd_code_01  -- 16.�Q�R�[�h�P
     ,iv_crowd_code_02 => iv_crowd_code_02  -- 17.�Q�R�[�h�Q
     ,iv_crowd_code_03 => iv_crowd_code_03  -- 18.�Q�R�[�h�R
     ,iv_crowd_code_04 => iv_crowd_code_04  -- 19.�Q�R�[�h�S
     ,iv_crowd_code_05 => iv_crowd_code_05  -- 20.�Q�R�[�h�T
     ,iv_crowd_code_06 => iv_crowd_code_06  -- 21.�Q�R�[�h�U
     ,iv_crowd_code_07 => iv_crowd_code_07  -- 22.�Q�R�[�h�V
     ,iv_crowd_code_08 => iv_crowd_code_08  -- 23.�Q�R�[�h�W
     ,iv_crowd_code_09 => iv_crowd_code_09  -- 24.�Q�R�[�h�X
     ,iv_crowd_code_10 => iv_crowd_code_10  -- 25.�Q�R�[�h�P�O
     ,ov_errbuf        => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      errbuf := lv_errmsg;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
--
    ELSIF (lv_retcode = gv_status_warn) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
--
    END IF;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxinv100002c;
/