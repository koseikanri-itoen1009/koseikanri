CREATE OR REPLACE PACKAGE BODY xxinv100003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV100003C(body)
 * Description      : �̔��v�掞�n��\
 * MD.050/070       : �̔��v��E����v�� (T_MD050_BPO_100)
 *                    �̔��v�掞�n��\   (T_MD070_BPO_10C)
 * Version          : 1.8
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------------
 *  pro_get_cus_option           P �f�[�^�擾    - �J�X�^���I�v�V�����擾             (C-1-0)
 *  prc_sale_plan                P �f�[�^���o    - �̔��v�掞�n��\��񒊏o(�S���_��) (C-1-1)
 *  prc_sale_plan_1              P �f�[�^���o    - �̔��v�掞�n��\��񒊏o(���_��)   (C-1-2)
 *  prc_create_xml_data_user     P XML�f�[�^�ϊ� - ���[�U�[��񕔕�    (user_info)
 *  prc_create_xml_data_param    P XML�f�[�^�ϊ� - �p�����[�^��񕔕�  (param_info)
 *  prc_create_xml_data          P XML�f�[�^�쐬 - ���[�f�[�^�o��
 *  prc_create_xml_data_dtl      P XML�f�[�^�쐬 - ���[�f�[�^�o�� ���׍s �f�[�^�L
 *  prc_create_xml_data_dtl_n    P XML�f�[�^�쐬 - ���[�f�[�^�o�� ���׍s �f�[�^��
 *  prc_create_xml_data_st_lt    P XML�f�[�^�쐬 - ���[�f�[�^�o�� ���Q�v/��Q�v�p
 *  prc_create_xml_data_s_k_t    P XML�f�[�^�쐬 - ���[�f�[�^�o�� ���_�v/���i�敪�v/�����v�p
 *  submain                      P ���C�������v���V�[�W��
 *  main                         P �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 *  convert_into_xml             F XML�f�[�^�ϊ�
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------------
 *  2008/02/15   1.0   Tatsuya Kurata   �V�K�쐬
 *  2008/04/23   1.1   Masanobu Kimura  �����ύX�v��#27
 *  2008/04/28   1.2   Sumie Nakamura   �d����W���P���w�b�_(�A�h�I��)���o�����R��Ή�
 *  2008/04/30   1.3   Yuko Kawano      �����ύX�v��#62,76
 *  2008/05/28   1.4   Kazuo Kumamoto   �K��ᔽ(varchar�g�p)�Ή�
 *  2008/07/02   1.5   Satoshi Yunba    �֑������Ή�
 *  2009/04/16   1.6   �g�� ����        �{�ԏ�Q�Ή�(No.1410)
 *  2009/05/29   1.7   �g�� ����        �{�ԏ�Q�Ή�(No.1509)
 *  2009/10/05   1.8   �g�� ����        �{�ԏ�Q�Ή�(No.1648)
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START  #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--##################################  �Œ蕔 END  ################################
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
     ,output_unit      VARCHAR2(6)    -- �o�͒P��
--2008.04.30 Y.Kawano modify start
--     ,output_type      VARCHAR2(6)    -- �o�͎��
     ,output_type      VARCHAR2(8)    -- �o�͎��
--2008.04.30 Y.Kawano modify end
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
  -- �̔��v�掞�n��\���擾�f�[�^�i�[�p���R�[�h�ϐ�(�S���_�p)
  TYPE rec_sale_plan IS RECORD 
    (
       skbn              xxcmn_item_categories2_v.segment1%TYPE      -- ���i�敪
      ,skbn_name         xxcmn_item_categories2_v.description%TYPE   -- ���i�敪(����)
      ,gun               xxcmn_item_categories2_v.segment1%TYPE      -- �Q�R�[�h
      ,item_no           xxcmn_item_mst2_v.item_no%TYPE              -- �i��(�R�[�h)
      ,item_short_name   xxcmn_item_mst2_v.item_short_name%TYPE      -- �i��(����)
      ,case_quant        xxcmn_item_mst2_v.num_of_cases%TYPE         -- ����
      ,quant             mrp_forecast_dates.attribute4%TYPE          -- ����
      ,amount            mrp_forecast_dates.attribute2%TYPE          -- ���z
      ,total_amount      xxpo_price_headers.total_amount%TYPE        -- ���󍇌v
      ,o_amount          xxcmn_item_mst2_v.old_price%TYPE            -- ���E�艿
      ,n_amount          xxcmn_item_mst2_v.new_price%TYPE            -- �V�E�艿
      ,price_st          xxcmn_item_mst2_v.price_start_date%TYPE     -- �艿�K�p�J�n��
      ,month             VARCHAR2(10)                                -- Forecast���t(���̂�)
    );
  TYPE tab_data_sale_plan IS TABLE OF rec_sale_plan INDEX BY BINARY_INTEGER;
--
  -- �̔��v�掞�n��\���擾�f�[�^�i�[�p���R�[�h�ϐ�(���_�p)
  TYPE rec_sale_plan_1 IS RECORD 
    (
       skbn              xxcmn_item_categories2_v.segment1%TYPE      -- ���i�敪
      ,skbn_name         xxcmn_item_categories2_v.description%TYPE   -- ���i�敪(����)
      ,gun               xxcmn_item_categories2_v.segment1%TYPE      -- �Q�R�[�h
      ,item_no           xxcmn_item_mst2_v.item_no%TYPE              -- �i��(�R�[�h)
      ,item_short_name   xxcmn_item_mst2_v.item_short_name%TYPE      -- �i��(����)
      ,case_quant        xxcmn_item_mst2_v.num_of_cases%TYPE         -- ����
      ,quant             mrp_forecast_dates.attribute4%TYPE          -- ����
      ,amount            mrp_forecast_dates.attribute2%TYPE          -- ���z
      ,ktn_code          mrp_forecast_dates.attribute5%TYPE          -- ���_�R�[�h
      ,party_short_name  xxcmn_parties_v.party_short_name%TYPE       -- ���_����
      ,total_amount      xxpo_price_headers.total_amount%TYPE        -- ���󍇌v
      ,o_amount          xxcmn_item_mst2_v.old_price%TYPE            -- ���E�艿
      ,n_amount          xxcmn_item_mst2_v.new_price%TYPE            -- �V�E�艿
      ,price_st          xxcmn_item_mst2_v.price_start_date%TYPE     -- �艿�K�p�J�n��
      ,month             VARCHAR2(10)                                -- Forecast���t(���̂�)
    );
  TYPE tab_data_sale_plan_1 IS TABLE OF rec_sale_plan_1 INDEX BY BINARY_INTEGER;
--
  -- �e�W�v���ڗp
  TYPE add_total IS RECORD
    (
      may_quant      NUMBER     -- �T�� ����
     ,may_amount     NUMBER     -- �T�� ���z
     ,may_price      NUMBER     -- �T�� �i�ڒ艿
     ,may_to_amount  NUMBER     -- �T�� ���󍇌v
     ,may_quant_t    NUMBER     -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,may_s_cost     NUMBER     -- �T�� �W������(�v�Z�p)
     ,may_calc       NUMBER     -- �T�� �i�ڒ艿*����(�v�Z�p)
     ,may_minus_flg   VARCHAR2(1)  -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
     ,may_ht_zero_flg VARCHAR2(1)  -- �T�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,jun_quant      NUMBER     -- �U�� ����
     ,jun_amount     NUMBER     -- �U�� ���z
     ,jun_price      NUMBER     -- �U�� �i�ڒ艿
     ,jun_to_amount  NUMBER     -- �U�� ���󍇌v
     ,jun_quant_t    NUMBER     -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,jun_s_cost     NUMBER     -- �U�� �W������(�v�Z�p)
     ,jun_calc       NUMBER     -- �U�� �i�ڒ艿*����(�v�Z�p)
     ,jun_minus_flg   VARCHAR2(1)  -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
     ,jun_ht_zero_flg VARCHAR2(1)  -- �U�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,jul_quant      NUMBER     -- �V�� ����
     ,jul_amount     NUMBER     -- �V�� ���z
     ,jul_price      NUMBER     -- �V�� �i�ڒ艿
     ,jul_to_amount  NUMBER     -- �V�� ���󍇌v
     ,jul_quant_t    NUMBER     -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,jul_s_cost     NUMBER     -- �V�� �W������(�v�Z�p)
     ,jul_calc       NUMBER     -- �V�� �i�ڒ艿*����(�v�Z�p)
     ,jul_minus_flg   VARCHAR2(1)  -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
     ,jul_ht_zero_flg VARCHAR2(1)  -- �V�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,aug_quant      NUMBER     -- �W�� ����
     ,aug_amount     NUMBER     -- �W�� ���z
     ,aug_price      NUMBER     -- �W�� �i�ڒ艿
     ,aug_to_amount  NUMBER     -- �W�� ���󍇌v
     ,aug_quant_t    NUMBER     -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,aug_s_cost     NUMBER     -- �W��  �W������(�v�Z�p)
     ,aug_calc       NUMBER     -- �W�� �i�ڒ艿*����(�v�Z�p)
     ,aug_minus_flg   VARCHAR2(1)  -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
     ,aug_ht_zero_flg VARCHAR2(1)  -- �W�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,sep_quant      NUMBER     -- �X�� ����
     ,sep_amount     NUMBER     -- �X�� ���z
     ,sep_price      NUMBER     -- �X�� �i�ڒ艿
     ,sep_to_amount  NUMBER     -- �X�� ���󍇌v
     ,sep_quant_t    NUMBER     -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,sep_s_cost     NUMBER     -- �X�� �W������(�v�Z�p)
     ,sep_calc       NUMBER     -- �X�� �i�ڒ艿*����(�v�Z�p)
     ,sep_minus_flg   VARCHAR2(1)  -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
     ,sep_ht_zero_flg VARCHAR2(1)  -- �X�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,oct_quant      NUMBER     -- �P�O�� ����
     ,oct_amount     NUMBER     -- �P�O�� ���z
     ,oct_price      NUMBER     -- �P�O�� �i�ڒ艿
     ,oct_to_amount  NUMBER     -- �P�O�� ���󍇌v
     ,oct_quant_t    NUMBER     -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,oct_s_cost     NUMBER     -- �P�O�� �W������(�v�Z�p)
     ,oct_calc       NUMBER     -- �P�O�� �i�ڒ艿*����(�v�Z�p)
     ,oct_minus_flg   VARCHAR2(1)  -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
     ,oct_ht_zero_flg VARCHAR2(1)  -- �P�O�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,nov_quant      NUMBER     -- �P�P�� ����
     ,nov_amount     NUMBER     -- �P�P�� ���z
     ,nov_price      NUMBER     -- �P�P�� �i�ڒ艿
     ,nov_to_amount  NUMBER     -- �P�P�� ���󍇌v
     ,nov_quant_t    NUMBER     -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,nov_s_cost     NUMBER     -- �P�P�� �W������(�v�Z�p)
     ,nov_calc       NUMBER     -- �P�P�� �i�ڒ艿*����(�v�Z�p)
     ,nov_minus_flg   VARCHAR2(1)  -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
     ,nov_ht_zero_flg VARCHAR2(1)  -- �P�P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,dec_quant      NUMBER     -- �P�Q�� ����
     ,dec_amount     NUMBER     -- �P�Q�� ���z
     ,dec_price      NUMBER     -- �P�Q�� �i�ڒ艿
     ,dec_to_amount  NUMBER     -- �P�Q�� ���󍇌v
     ,dec_quant_t    NUMBER     -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,dec_s_cost     NUMBER     -- �P�Q�� �W������(�v�Z�p)
     ,dec_calc       NUMBER     -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
     ,dec_minus_flg   VARCHAR2(1)  -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
     ,dec_ht_zero_flg VARCHAR2(1)  -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,jan_quant      NUMBER     -- �P�� ����
     ,jan_amount     NUMBER     -- �P�� ���z
     ,jan_price      NUMBER     -- �P�� �i�ڒ艿
     ,jan_to_amount  NUMBER     -- �P�� ���󍇌v
     ,jan_quant_t    NUMBER     -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,jan_s_cost     NUMBER     -- �P�� �W������(�v�Z�p)
     ,jan_calc       NUMBER     -- �P�� �i�ڒ艿*����(�v�Z�p)
     ,jan_minus_flg   VARCHAR2(1)  -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
     ,jan_ht_zero_flg VARCHAR2(1)  -- �P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,feb_quant      NUMBER     -- �Q�� ����
     ,feb_amount     NUMBER     -- �Q�� ���z
     ,feb_price      NUMBER     -- �Q�� �i�ڒ艿
     ,feb_to_amount  NUMBER     -- �Q�� ���󍇌v
     ,feb_quant_t    NUMBER     -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,feb_s_cost     NUMBER     -- �Q�� �W������(�v�Z�p)
     ,feb_calc       NUMBER     -- �Q�� �i�ڒ艿*����(�v�Z�p)
     ,feb_minus_flg   VARCHAR2(1)  -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
     ,feb_ht_zero_flg VARCHAR2(1)  -- �Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,mar_quant      NUMBER     -- �R�� ����
     ,mar_amount     NUMBER     -- �R�� ���z
     ,mar_price      NUMBER     -- �R�� �i�ڒ艿
     ,mar_to_amount  NUMBER     -- �R�� ���󍇌v
     ,mar_quant_t    NUMBER     -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,mar_s_cost     NUMBER     -- �R�� �W������(�v�Z�p)
     ,mar_calc       NUMBER     -- �R�� �i�ڒ艿*����(�v�Z�p)
     ,mar_minus_flg   VARCHAR2(1)  -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
     ,mar_ht_zero_flg VARCHAR2(1)  -- �R�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,apr_quant      NUMBER     -- �S�� ����
     ,apr_amount     NUMBER     -- �S�� ���z
     ,apr_price      NUMBER     -- �S�� �i�ڒ艿
     ,apr_to_amount  NUMBER     -- �S�� ���㍇�v
     ,apr_quant_t    NUMBER     -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,apr_s_cost     NUMBER     -- �S�� �W������(�v�Z�p)
     ,apr_calc       NUMBER     -- �S�� �i�ڒ艿*����(�v�Z�p)
     ,apr_minus_flg   VARCHAR2(1)  -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
     ,apr_ht_zero_flg VARCHAR2(1)  -- �S�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,year_quant     NUMBER     -- �N�v ����
     ,year_amount    NUMBER     -- �N�v ���z
     ,year_price     NUMBER     -- �N�v �i�ڒ艿
     ,year_to_amount NUMBER     -- �N�v ���󍇌v
     ,year_quant_t   NUMBER     -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,year_s_cost    NUMBER     -- �N�v �W������(�v�Z�p)
     ,year_calc      NUMBER     -- �N�v �i�ڒ艿*����(�v�Z�p)
     ,year_minus_flg   VARCHAR2(1)  -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
     ,year_ht_zero_flg VARCHAR2(1)  -- �N�v �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
    );
  TYPE tab_add_total IS TABLE OF add_total INDEX BY PLS_INTEGER;
--
  -- XML�o�͔���
  TYPE xml_out IS RECORD
    (
--mod start 1.4
--      tag_name       VARCHAR(5)     -- �^�O�l�[��
--     ,out_fg         VARCHAR(1)     -- �o�͔���p
      tag_name       VARCHAR2(5)     -- �^�O�l�[��
     ,out_fg         VARCHAR2(1)     -- �o�͔���p
--mod end 1.4
    );
  TYPE tab_xml_out IS TABLE OF xml_out INDEX BY PLS_INTEGER;
  
  -- ==================================================
  -- ���[�U�[��`�O���[�o���萔
  -- ==================================================
  gv_pkg_name         CONSTANT VARCHAR2(20) := 'XXINV100003C';           -- �p�b�P�[�W��
  gv_prf_start_day    CONSTANT VARCHAR2(30) := 'XXCMN_PERIOD_START_DAY'; -- XXCMN:�N�x�J�n����
  gv_prf_prod         CONSTANT VARCHAR2(50) := 'XXCMN_ITEM_DIV';         -- XXCMN:���i�敪
  gv_prf_crowd        CONSTANT VARCHAR2(50) := 'XXCMN_CATEGORY_NAME_OTGUN';
                                                           -- XXCMN:�J�e�S���Z�b�g��(�Q�R�[�h)
--2008.04.30 Y.Kawano add start
  gv_master_org_id    CONSTANT VARCHAR2(30)  := 'XXCMN_MASTER_ORG_ID';    --XXCMN:�}�X�^�g�DID
--2008.04.30 Y.Kawano add end
  gv_name_sale_plan   CONSTANT VARCHAR2(2)  := '05';                     -- '�̔��v��'
  gv_prod_div_leaf    CONSTANT VARCHAR2(1)  := '1';                      -- '���[�t'
  gv_prod_div_drink   CONSTANT VARCHAR2(1)  := '2';                      -- '�h�����N'
  gv_output_unit      CONSTANT VARCHAR2(1)  := '0';                      -- '�{��'
-- �r�p�k�쐬�p
  gv_sql_l_block      CONSTANT VARCHAR2(2)  := ' (';                     -- ������'('
  gv_sql_r_block      CONSTANT VARCHAR2(2)  := ') ';                     -- �E����')'
  gv_sql_dot          CONSTANT VARCHAR2(3)  := ' , ';                    -- �J���}','
-- ���[�\���p
  gv_report_id        CONSTANT VARCHAR2(12) := 'XXINV100003T';           -- ���[ID
  gv_name_year        CONSTANT VARCHAR2(10) := '�N�x';
  gv_name_all_ktn     CONSTANT VARCHAR2(10) := '�S���_';
  gv_output_unit_0    CONSTANT VARCHAR2(10) := '�{��';                   -- �o�͒P�� '0'
  gv_output_unit_1    CONSTANT VARCHAR2(10) := '�P�[�X';                 -- �o�͒P�� '1'
  gv_label_st         CONSTANT VARCHAR2(10) := '�y���Q�v�z';
  gv_label_lt         CONSTANT VARCHAR2(10) := '�y��Q�v�z';
-- �G���[�R�[�h
  gv_application      CONSTANT VARCHAR2(5)  := 'XXCMN';                  -- �A�v���P�[�V����
  gv_tkn_pro          CONSTANT VARCHAR2(15) := 'PROFILE';                -- �v���t�@�C����
  gv_err_code_no_data CONSTANT VARCHAR2(20) := 'APP-XXCMN-10122';        -- ���[�O�����b�Z�[�W
  gv_err_pro          CONSTANT VARCHAR2(20) := 'APP-XXCMN-10002';
                                                           -- �v���t�@�C���擾�G���[���b�Z�[�W
-- �o�̓^�O�l�[��
  gv_name_may         CONSTANT VARCHAR2(4)  := 'may_';                   -- �T��
  gv_name_jun         CONSTANT VARCHAR2(4)  := 'jun_';                   -- �U��
  gv_name_jul         CONSTANT VARCHAR2(4)  := 'jul_';                   -- �V��
  gv_name_aug         CONSTANT VARCHAR2(4)  := 'aug_';                   -- �W��
  gv_name_sep         CONSTANT VARCHAR2(4)  := 'sep_';                   -- �X��
  gv_name_oct         CONSTANT VARCHAR2(4)  := 'oct_';                   -- �P�O��
  gv_name_nov         CONSTANT VARCHAR2(4)  := 'nov_';                   -- �P�P��
  gv_name_dec         CONSTANT VARCHAR2(4)  := 'dec_';                   -- �P�Q��
  gv_name_jan         CONSTANT VARCHAR2(4)  := 'jan_';                   -- �P��
  gv_name_feb         CONSTANT VARCHAR2(4)  := 'feb_';                   -- �Q��
  gv_name_mar         CONSTANT VARCHAR2(4)  := 'mar_';                   -- �R��
  gv_name_apr         CONSTANT VARCHAR2(4)  := 'apr_';                   -- �S��
  gv_name_st          CONSTANT VARCHAR2(3)  := 'st_';                    -- ���Q�v�p
  gv_name_lt          CONSTANT VARCHAR2(3)  := 'lt_';                    -- ��Q�v�p
  gv_name_ktn         CONSTANT VARCHAR2(4)  := 'ktn_';                   -- ���_�p
  gv_name_skbn        CONSTANT VARCHAR2(5)  := 'skbn_';                  -- ���i�敪�p
  gv_name_ttl         CONSTANT VARCHAR2(4)  := 'ttl_';                   -- �����v�p
--
  gn_0                NUMBER                := 0;                        -- 0
  gn_kotei_70         NUMBER(6,2)           := 70.00;                    -- �Œ�l(�|����)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_start_day          DATE;                 -- �N�x�J�n����
  gv_name_prod          VARCHAR2(10);         -- ���i�敪
  gv_name_crowd         VARCHAR2(10);         -- �Q�R�[�h
--2008.04.30 Y.Kawano add start
  gn_org_id             NUMBER;            -- �}�X�^�g�DID
--2008.04.30 Y.Kawano add end
-- �r�p�k�쐬�p
  gv_sql_sel            VARCHAR2(9000);       -- SQL�g�����p
  gv_sql_select         VARCHAR2(5000);       -- SELECT��
  gv_sql_from           VARCHAR2(5000);       -- FROM��
  gv_sql_where          VARCHAR2(6000);       -- WHERE��
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
  gv_sql_group_by       VARCHAR2(5000);       -- GROUP BY��
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
  gv_sql_order_by       VARCHAR2(5000);       -- ORDER BY��
  gv_sql_prod_div       VARCHAR2(5000);       -- ���i�敪(���͂o�L)
  gv_sql_prod_div_n     VARCHAR2(5000);       -- ���i�敪(���͂o��)
  gv_sql_crowd_code     VARCHAR2(5000);       -- �Q�R�[�h(���͂o�L)
-- �Q�R�[�h���͂o�p
  gv_sql_crowd_code_01  VARCHAR2(50);         -- �Q�R�[�h�P
  gv_sql_crowd_code_02  VARCHAR2(50);         -- �Q�R�[�h�Q
  gv_sql_crowd_code_03  VARCHAR2(50);         -- �Q�R�[�h�R
  gv_sql_crowd_code_04  VARCHAR2(50);         -- �Q�R�[�h�S
  gv_sql_crowd_code_05  VARCHAR2(50);         -- �Q�R�[�h�T
  gv_sql_crowd_code_06  VARCHAR2(50);         -- �Q�R�[�h�U
  gv_sql_crowd_code_07  VARCHAR2(50);         -- �Q�R�[�h�V
  gv_sql_crowd_code_08  VARCHAR2(50);         -- �Q�R�[�h�W
  gv_sql_crowd_code_09  VARCHAR2(50);         -- �Q�R�[�h�X
  gv_sql_crowd_code_10  VARCHAR2(50);         -- �Q�R�[�h�P�O
--
  gl_xml_idx            NUMBER;               -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
  gt_xml_data_table     XML_DATA;             -- �w�l�k�f�[�^�^�O�\
  gr_param              rec_param_data ;      -- ���̓p�����[�^
  gr_sale_plan          tab_data_sale_plan;   -- �S���_�p
  gr_sale_plan_1        tab_data_sale_plan_1; -- ���_�p
  gr_add_total          tab_add_total;        -- �W�v�p����
  gr_xml_out            tab_xml_out;          -- XML�o�͔���p
--
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
   * Description      : �J�X�^���I�v�V�����擾  (C-1-0)
   ***********************************************************************************/
  PROCEDURE pro_get_cus_option
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --------------------------------------
    -- �v���t�@�C������N�x�J�n�����擾
    --------------------------------------
    lv_start_day := SUBSTRB(FND_PROFILE.VALUE(gv_prf_start_day),1,5);
    -- �擾�G���[��
    IF (lv_start_day IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(gv_application     -- 'XXCMN'
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
    --------------------------------------
    -- �v���t�@�C�����珤�i�敪�擾
    --------------------------------------
    gv_name_prod := SUBSTRB(FND_PROFILE.VALUE(gv_prf_prod),1,30);
    -- �擾�G���[��
    IF (gv_name_prod IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(gv_application    -- 'XXCMN'
                                                    ,gv_err_pro        -- �v���t�@�C���擾�G���[
                                                    ,gv_tkn_pro        -- �g�[�N��'PROFILE'
                                                    ,gv_prf_prod)      -- XXCMN:���i�敪
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    --------------------------------------
    -- �v���t�@�C������Q�R�[�h�擾
    --------------------------------------
    gv_name_crowd := SUBSTRB(FND_PROFILE.VALUE(gv_prf_crowd),1,30);
    -- �擾�G���[��
    IF (gv_name_crowd IS NULL) THEN
      lv_errmsg   := SUBSTRB(xxcmn_common_pkg.get_msg(gv_application    -- 'XXCMN'
                                                     ,gv_err_pro        -- �v���t�@�C���擾�G���[
                                                     ,gv_tkn_pro        -- �g�[�N��'PROFILE'
                                                     ,gv_prf_crowd)
                                                              -- XXCMN:�J�e�S���Z�b�g��(�Q�R�[�h)
                                                     ,1
                                                     ,5000);
      RAISE global_api_expt;
    END IF;
--
--2008.04.30 Y.Kawano add start
--FND_FILE.PUT_LINE(FND_FILE.LOG,'�v���t�@�C���擾');
    -- �v���t�@�C������XXCMN:�}�X�^�g�DID�擾
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(gv_master_org_id));
--FND_FILE.PUT_LINE(FND_FILE.LOG,'�v���t�@�C���擾��Forg_id='|| gn_org_id);
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
--2008.04.30 Y.Kawano add end
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
   * Description      : �f�[�^���o - �̔��v�掞�n��\��񒊏o(�S���_��) (C-1-1)
   ***********************************************************************************/
  PROCEDURE prc_sale_plan
    (
      ot_sale_plan  OUT NOCOPY tab_data_sale_plan -- �擾���R�[�h�Q
     ,ov_errbuf     OUT VARCHAR2                  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gv_sql_select := 'SELECT xicv1.segment1                 AS skbn            -- ���i�敪
                            ,xicv1.description              AS skbn_name       -- ���i�敪(����)
                            ,xicv.segment1                  AS gun             -- �Q�R�[�h
                            ,ximv.item_no                   AS item_no         -- �i��(�R�[�h)
                            ,ximv.item_short_name           AS item_short_name -- �i��(����)
                            ,ximv.num_of_cases              AS case_quant      -- ����
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
                            --,mfd.attribute4                 AS quant           -- ����
                            --,mfd.attribute2                 AS amount          -- ���z
                            ,SUM(mfd.attribute4)            AS quant           -- ����
                            ,SUM(mfd.attribute2)            AS amount          -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
                            ,xph.total_amount               AS total_amount    -- ���󍇌v
                            ,ximv.old_price                 AS o_amount        -- ���E�艿
                            ,ximv.new_price                 AS n_amount        -- �V�E�艿
                            ,ximv.price_start_date          AS price_st        -- �艿�K�p�J�n��
                            ,SUBSTRB(mfd.forecast_date,4,3) AS month      -- forecast���t(���̂�)
                     ';
--
    -- FROM��
    gv_sql_from   := ' FROM mrp_forecast_designators  mfds    -- Forecast��
                           ,mrp_forecast_dates        mfd     -- Forecast���t
                           ,xxpo_price_headers        xph     -- �d��/�W���P���w�b�_(�A�h�I��)
                           ,xxcmn_item_categories2_v  xicv    -- OPM�i�ڃJ�e�S���������VIEW
                           ,xxcmn_item_categories2_v  xicv1   -- OPM�i�ڃJ�e�S���������VIEW(��)
                           ,xxcmn_item_mst2_v         ximv    -- OPM�i�ڏ��VIEW
                     ';
--
    -- WHERE��
    gv_sql_where  := ' WHERE mfds.attribute1          = :para_name_sale_plan      -- �̔��v��
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
                       AND   ximv.item_no             = xicv.item_no
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
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- GROUP BY��
    gv_sql_group_by      := ' GROUP BY xicv1.segment1                    -- ���i�敪
                                     ,xicv1.description                 -- ���i�敪(����)
                                     ,xicv.segment1                     -- �Q�R�[�h
                                     ,ximv.item_no                      -- �i��(�R�[�h)
                                     ,ximv.item_short_name              -- �i��(����)
                                     ,ximv.num_of_cases                 -- ����
                                     ,xph.total_amount                  -- ���󍇌v
                                     ,ximv.old_price                    -- ���E�艿
                                     ,ximv.new_price                    -- �V�E�艿
                                     ,ximv.price_start_date             -- �艿�K�p�J�n��
                                     ,mfd.forecast_date ';  -- forecast���t(���̂�)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- ORDER BY��
    gv_sql_order_by      := ' ORDER BY xicv1.segment1       -- ���i�敪
                                      ,xicv.segment1        -- �Q�R�[�h
                                      ,ximv.item_no         -- �i��
                                      ,mfd.forecast_date';  -- forecast���t
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
    IF ((gr_param.crowd_code_01 IS NOT NULL)
      OR (gr_param.crowd_code_02 IS NOT NULL)
        OR (gr_param.crowd_code_03 IS NOT NULL)
          OR (gr_param.crowd_code_04 IS NOT NULL)
            OR (gr_param.crowd_code_05 IS NOT NULL)
              OR (gr_param.crowd_code_06 IS NOT NULL)
                OR (gr_param.crowd_code_07 IS NOT NULL)
                  OR (gr_param.crowd_code_08 IS NOT NULL)
                    OR (gr_param.crowd_code_09 IS NOT NULL)
                      OR (gr_param.crowd_code_10 IS NOT NULL)) THEN
      -- �Q�R�[�h���o���� + ������
      gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_l_block;
      -- ���͂o �Q�R�[�h�P�ɓ��͗L
      IF (gr_param.crowd_code_01 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_01;
      END IF;
      -- ���͂o �Q�R�[�h�Q�ɓ��͗L
      IF ((gr_param.crowd_code_02 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_02;
      ELSIF (gr_param.crowd_code_02 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_02;
      END IF;
      -- ���͂o �Q�R�[�h�R�ɓ��͗L
      IF ((gr_param.crowd_code_03 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_03;
      ELSIF (gr_param.crowd_code_03 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_03;
      END IF;
      -- ���͂o �Q�R�[�h�S�ɓ��͗L
      IF ((gr_param.crowd_code_04 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_04;
      ELSIF (gr_param.crowd_code_04 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_04;
      END IF;
      -- ���͂o �Q�R�[�h�T�ɓ��͗L
      IF ((gr_param.crowd_code_05 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_05;
      ELSIF (gr_param.crowd_code_05 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_05;
      END IF;
      -- ���͂o �Q�R�[�h�U�ɓ��͗L
      IF ((gr_param.crowd_code_06 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_06;
      ELSIF (gr_param.crowd_code_06 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_06;
      END IF;
      -- ���͂o �Q�R�[�h�V�ɓ��͗L
      IF ((gr_param.crowd_code_07 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_07;
      ELSIF (gr_param.crowd_code_07 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_07;
      END IF;
      -- ���͂o �Q�R�[�h�W�ɓ��͗L
      IF ((gr_param.crowd_code_08 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)
                    AND (gr_param.crowd_code_07 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_08;
      ELSIF (gr_param.crowd_code_08 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_08;
      END IF;
      -- ���͂o �Q�R�[�h�X�ɓ��͗L
      IF ((gr_param.crowd_code_09 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)
                    AND (gr_param.crowd_code_07 IS NULL)
                      AND (gr_param.crowd_code_08 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_09;
      ELSIF (gr_param.crowd_code_09 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_09;
      END IF;
      -- ���͂o �Q�R�[�h�P�O�ɓ��͗L
      IF ((gr_param.crowd_code_10 IS NOT NULL)
        AND (gr_param.crowd_code_01 IS NULL)
          AND (gr_param.crowd_code_02 IS NULL)
            AND (gr_param.crowd_code_03 IS NULL)
              AND (gr_param.crowd_code_04 IS NULL)
                AND (gr_param.crowd_code_05 IS NULL)
                  AND (gr_param.crowd_code_06 IS NULL)
                    AND (gr_param.crowd_code_07 IS NULL)
                      AND (gr_param.crowd_code_08 IS NULL)
                        AND (gr_param.crowd_code_09 IS NULL)) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_10;
      ELSIF (gr_param.crowd_code_10 IS NOT NULL) THEN
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_10;
      END IF;
      -- �Q�R�[�h���o���� + �E����
      gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_r_block;
      -- �쐬�r�p�k���ɌQ�R�[�h���o��������
      gv_sql_sel        := gv_sql_sel || gv_sql_crowd_code;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- GROUP BY�匋��
    gv_sql_sel := gv_sql_sel || gv_sql_group_by;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
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
  END prc_sale_plan;
--
  /**********************************************************************************
   * Procedure Name   : prc_sale_plan_1
   * Description      : �f�[�^���o - �̔��v�掞�n��\��񒊏o(���_��) (C-1-2)
   ***********************************************************************************/
  PROCEDURE prc_sale_plan_1
    (
      ot_sale_plan_1 OUT NOCOPY tab_data_sale_plan_1 -- �擾���R�[�h�Q
     ,ov_errbuf      OUT VARCHAR2                    -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode     OUT VARCHAR2                    -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg      OUT VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_sql_base       VARCHAR2(5000);  -- ���_(���͂o�L)
    -- ���_���͂o�p
    lv_sql_base_01    VARCHAR2(100);   -- ���_�P
    lv_sql_base_02    VARCHAR2(100);   -- ���_�Q
    lv_sql_base_03    VARCHAR2(100);   -- ���_�R
    lv_sql_base_04    VARCHAR2(100);   -- ���_�S
    lv_sql_base_05    VARCHAR2(100);   -- ���_�T
    lv_sql_base_06    VARCHAR2(100);   -- ���_�U
    lv_sql_base_07    VARCHAR2(100);   -- ���_�V
    lv_sql_base_08    VARCHAR2(100);   -- ���_�W
    lv_sql_base_09    VARCHAR2(100);   -- ���_�X
    lv_sql_base_10    VARCHAR2(100);   -- ���_�P�O
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
    gv_sql_select := 'SELECT xicv1.segment1                 AS skbn             -- ���i�敪
                            ,xicv1.description              AS skbn_name        -- ���i�敪(����)
                            ,xicv.segment1                  AS gun              -- �Q�R�[�h
                            ,ximv.item_no                   AS item_no          -- �i��(�R�[�h)
                            ,ximv.item_short_name           AS item_short_name  -- �i��(����)
                            ,ximv.num_of_cases              AS case_quant       -- ����
                            ,mfd.attribute4                 AS quant            -- ����
                            ,mfd.attribute2                 AS amount           -- ���z
                            ,mfd.attribute5                 AS ktn_code         -- ���_�R�[�h
                            ,xpv.party_short_name           AS party_short_name -- ���_��
                            ,xph.total_amount               AS total_amount     -- ���󍇌v
                            ,ximv.old_price                 AS o_amount         -- ���E�艿
                            ,ximv.new_price                 AS n_amount         -- �V�E�艿
                            ,ximv.price_start_date          AS price_st         -- �艿�K�p�J�n��
                            ,SUBSTRB(mfd.forecast_date,4,3) AS month      -- forecast���t(���̂�)
                     ';
--
    -- FROM��
    gv_sql_from   := ' FROM mrp_forecast_designators  mfds    -- Forecast��
                           ,mrp_forecast_dates        mfd     -- Forecast���t
                           ,xxpo_price_headers        xph     -- �d��/�W���P���w�b�_(�A�h�I��)
                           ,xxcmn_item_categories2_v  xicv    -- OPM�i�ڃJ�e�S���������VIEW
                           ,xxcmn_item_categories2_v  xicv1   -- OPM�i�ڃJ�e�S���������VIEW(��)
                           ,xxcmn_item_mst2_v         ximv    -- OPM�i�ڏ��VIEW
-- 2009/10/5 v1.8 T.Yoshimoto Mod Start �{��#1648
                           --,xxcmn_parties_v           xpv     -- �p�[�e�B���VIEW
                           ,xxcmn_parties3_v          xpv     -- �p�[�e�B���VIEW2
-- 2009/10/5 v1.8 T.Yoshimoto Mod End �{��#1648
                     ';
--
    -- WHERE��
    gv_sql_where  := ' WHERE mfds.attribute1          = :para_name_sale_plan      -- �̔��v��
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
                       AND   ximv.item_no             = xicv.item_no
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
    gv_sql_prod_div      := ' AND xicv1.segment1 = ''' || gr_param.prod_div || '''
                            ';
    -- ���i�敪���o���� (���͂o NULL)
    gv_sql_prod_div_n    := ' AND xicv1.segment1 IN (''' || gv_prod_div_leaf  || '''
                                                       ' || gv_sql_dot        || '
                                                     ''' || gv_prod_div_drink || ''') -- 1,2�̗������o
                            ';
--
    -- ���_���o���� (1���10�̓��̓p�����[�^)
    lv_sql_base          := ' AND mfd.attribute5 IN ';
    lv_sql_base_01       := '''' || gr_param.base_01 || '''';
    lv_sql_base_02       := '''' || gr_param.base_02 || '''';
    lv_sql_base_03       := '''' || gr_param.base_03 || '''';
    lv_sql_base_04       := '''' || gr_param.base_04 || '''';
    lv_sql_base_05       := '''' || gr_param.base_05 || '''';
    lv_sql_base_06       := '''' || gr_param.base_06 || '''';
    lv_sql_base_07       := '''' || gr_param.base_07 || '''';
    lv_sql_base_08       := '''' || gr_param.base_08 || '''';
    lv_sql_base_09       := '''' || gr_param.base_09 || '''';
    lv_sql_base_10       := '''' || gr_param.base_10 || '''';
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
    -- ORDER BY��
    gv_sql_order_by      := ' ORDER BY xicv1.segment1       -- ���i�敪
                                      ,mfd.attribute5       -- ���_
                                      ,xicv.segment1        -- �Q�R�[�h
                                      ,ximv.item_no         -- �i��
                                      ,mfd.forecast_date';  -- forecast���t
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
    IF ((gr_param.base_01 IS NOT NULL)
      OR (gr_param.base_02 IS NOT NULL)
        OR (gr_param.base_03 IS NOT NULL)
          OR (gr_param.base_04 IS NOT NULL)
            OR (gr_param.base_05 IS NOT NULL)
              OR (gr_param.base_06 IS NOT NULL)
                OR (gr_param.base_07 IS NOT NULL)
                  OR (gr_param.base_08 IS NOT NULL)
                    OR (gr_param.base_09 IS NOT NULL)
                      OR (gr_param.base_10 IS NOT NULL)) THEN
      -- ���_���o���� + ������
      lv_sql_base   := lv_sql_base || gv_sql_l_block;
      -- ���͂o ���_�P�ɓ��͗L
      IF (gr_param.base_01 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_01;
      END IF;
      -- ���͂o ���_�Q�ɓ��͗L
      IF ((gr_param.base_02 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_02;
      ELSIF (gr_param.base_02 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_02;
      END IF;
      -- ���͂o ���_�R�ɓ��͗L
      IF ((gr_param.base_03 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_03;
      ELSIF (gr_param.base_03 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_03;
      END IF;
      -- ���͂o ���_�S�ɓ��͗L
      IF ((gr_param.base_04 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_04;
      ELSIF (gr_param.base_04 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_04;
      END IF;
      -- ���͂o ���_�T�ɓ��͗L
      IF ((gr_param.base_05 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_05;
      ELSIF (gr_param.base_05 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_05;
      END IF;
      -- ���͂o ���_�U�ɓ��͗L
      IF ((gr_param.base_06 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_06;
      ELSIF (gr_param.base_06 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_06;
      END IF;
      -- ���͂o ���_�V�ɓ��͗L
      IF ((gr_param.base_07 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_07;
      ELSIF (gr_param.base_07 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_07;
      END IF;
      -- ���͂o ���_�W�ɓ��͗L
      IF ((gr_param.base_08 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)
                    AND (gr_param.base_07 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_08;
      ELSIF (gr_param.base_08 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_08;
      END IF;
      -- ���͂o ���_�X�ɓ��͗L
      IF ((gr_param.base_09 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)
                    AND (gr_param.base_07 IS NULL)
                      AND (gr_param.base_08 IS NULL)) THEN
        lv_sql_base := lv_sql_base || lv_sql_base_09;
      ELSIF (gr_param.base_09 IS NOT NULL) THEN
        lv_sql_base := lv_sql_base || gv_sql_dot || lv_sql_base_09;
      END IF;
      -- ���͂o ���_�P�O�ɓ��͗L
      IF ((gr_param.base_10 IS NOT NULL)
        AND (gr_param.base_01 IS NULL)
          AND (gr_param.base_02 IS NULL)
            AND (gr_param.base_03 IS NULL)
              AND (gr_param.base_04 IS NULL)
                AND (gr_param.base_05 IS NULL)
                  AND (gr_param.base_06 IS NULL)
                    AND (gr_param.base_07 IS NULL)
                      AND (gr_param.base_08 IS NULL)
                        AND (gr_param.base_09 IS NULL)) THEN
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
      IF ((gr_param.crowd_code_01 IS NOT NULL)
        OR (gr_param.crowd_code_02 IS NOT NULL)
          OR (gr_param.crowd_code_03 IS NOT NULL)
            OR (gr_param.crowd_code_04 IS NOT NULL)
              OR (gr_param.crowd_code_05 IS NOT NULL)
                OR (gr_param.crowd_code_06 IS NOT NULL)
                  OR (gr_param.crowd_code_07 IS NOT NULL)
                    OR (gr_param.crowd_code_08 IS NOT NULL)
                      OR (gr_param.crowd_code_09 IS NOT NULL)
                        OR (gr_param.crowd_code_10 IS NOT NULL)) THEN
        -- �Q�R�[�h���o���� + ������
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_l_block;
        -- ���͂o �Q�R�[�h�P�ɓ��͗L
        IF (gr_param.crowd_code_01 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_01;
        END IF;
        -- ���͂o �Q�R�[�h�Q�ɓ��͗L
        IF ((gr_param.crowd_code_02 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_02;
        ELSIF (gr_param.crowd_code_02 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_02;
        END IF;
        -- ���͂o �Q�R�[�h�R�ɓ��͗L
        IF ((gr_param.crowd_code_03 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_03;
        ELSIF (gr_param.crowd_code_03 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_03;
        END IF;
        -- ���͂o �Q�R�[�h�S�ɓ��͗L
        IF ((gr_param.crowd_code_04 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_04;
        ELSIF (gr_param.crowd_code_04 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_04;
        END IF;
        -- ���͂o �Q�R�[�h�T�ɓ��͗L
        IF ((gr_param.crowd_code_05 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_05;
        ELSIF (gr_param.crowd_code_05 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_05;
        END IF;
        -- ���͂o �Q�R�[�h�U�ɓ��͗L
        IF ((gr_param.crowd_code_06 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_06;
        ELSIF (gr_param.crowd_code_06 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_06;
        END IF;
        -- ���͂o �Q�R�[�h�V�ɓ��͗L
        IF ((gr_param.crowd_code_07 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_07;
        ELSIF (gr_param.crowd_code_07 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_07;
        END IF;
        -- ���͂o �Q�R�[�h�W�ɓ��͗L
        IF ((gr_param.crowd_code_08 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_08;
        ELSIF (gr_param.crowd_code_08 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_08;
        END IF;
        -- ���͂o �Q�R�[�h�X�ɓ��͗L
        IF ((gr_param.crowd_code_09 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_09;
        ELSIF (gr_param.crowd_code_09 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_09;
        END IF;
        -- ���͂o �Q�R�[�h�P�O�ɓ��͗L
        IF ((gr_param.crowd_code_10 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL)
                          AND (gr_param.crowd_code_09 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_10;
        ELSIF (gr_param.crowd_code_10 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_10;
        END IF;
        -- �Q�R�[�h���o���� + �E����
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_r_block;
        -- �쐬�r�p�k���ɌQ�R�[�h���o��������
        gv_sql_sel        := gv_sql_sel || gv_sql_crowd_code;
      END IF;
--
    -- ���͂o�u���_�P����P�O�v�ɓ��͖��̏ꍇ
    ELSE
      -- ���͂o�u�Q�R�[�h�P����P�O�v�ɓ��͗L�̏ꍇ
      IF ((gr_param.crowd_code_01 IS NOT NULL)
        OR (gr_param.crowd_code_02 IS NOT NULL)
          OR (gr_param.crowd_code_03 IS NOT NULL)
            OR (gr_param.crowd_code_04 IS NOT NULL)
              OR (gr_param.crowd_code_05 IS NOT NULL)
                OR (gr_param.crowd_code_06 IS NOT NULL)
                  OR (gr_param.crowd_code_07 IS NOT NULL)
                    OR (gr_param.crowd_code_08 IS NOT NULL)
                      OR (gr_param.crowd_code_09 IS NOT NULL)
                        OR (gr_param.crowd_code_10 IS NOT NULL)) THEN
        -- �Q�R�[�h���o���� + ������
        gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_l_block;
        -- ���͂o �Q�R�[�h�P�ɓ��͗L
        IF (gr_param.crowd_code_01 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_01;
        END IF;
        -- ���͂o �Q�R�[�h�Q�ɓ��͗L
        IF ((gr_param.crowd_code_02 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_02;
        ELSIF (gr_param.crowd_code_02 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_02;
        END IF;
        -- ���͂o �Q�R�[�h�R�ɓ��͗L
        IF ((gr_param.crowd_code_03 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_03;
        ELSIF (gr_param.crowd_code_03 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_03;
        END IF;
        -- ���͂o �Q�R�[�h�S�ɓ��͗L
        IF ((gr_param.crowd_code_04 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_04;
        ELSIF (gr_param.crowd_code_04 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_04;
        END IF;
        -- ���͂o �Q�R�[�h�T�ɓ��͗L
        IF ((gr_param.crowd_code_05 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_05;
        ELSIF (gr_param.crowd_code_05 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_05;
        END IF;
        -- ���͂o �Q�R�[�h�U�ɓ��͗L
        IF ((gr_param.crowd_code_06 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_06;
        ELSIF (gr_param.crowd_code_06 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_06;
        END IF;
        -- ���͂o �Q�R�[�h�V�ɓ��͗L
        IF ((gr_param.crowd_code_07 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_07;
        ELSIF (gr_param.crowd_code_07 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_07;
        END IF;
        -- ���͂o �Q�R�[�h�W�ɓ��͗L
        IF ((gr_param.crowd_code_08 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_08;
        ELSIF (gr_param.crowd_code_08 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_08;
        END IF;
        -- ���͂o �Q�R�[�h�X�ɓ��͗L
        IF ((gr_param.crowd_code_09 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL)) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_crowd_code_09;
        ELSIF (gr_param.crowd_code_09 IS NOT NULL) THEN
          gv_sql_crowd_code := gv_sql_crowd_code || gv_sql_dot || gv_sql_crowd_code_09;
        END IF;
        -- ���͂o �Q�R�[�h�P�O�ɓ��͗L
        IF ((gr_param.crowd_code_10 IS NOT NULL)
          AND (gr_param.crowd_code_01 IS NULL)
            AND (gr_param.crowd_code_02 IS NULL)
              AND (gr_param.crowd_code_03 IS NULL)
                AND (gr_param.crowd_code_04 IS NULL)
                  AND (gr_param.crowd_code_05 IS NULL)
                    AND (gr_param.crowd_code_06 IS NULL)
                      AND (gr_param.crowd_code_07 IS NULL)
                        AND (gr_param.crowd_code_08 IS NULL)
                          AND (gr_param.crowd_code_09 IS NULL)) THEN
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
                                                                       ,gv_price_type  -- add 2008/04/28
                                                                       ,gd_start_day
                                                                       ,gd_start_day 
                                                                       ;
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
  END prc_sale_plan_1;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_user
   * Description      : XML�f�[�^�ϊ� - ���[�U�[��񕔕�(user_info)
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_user
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
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
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id;
--
    -- ���s��
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(SYSDATE, 'YYYY/MM/DD HH24:MI:SS');
--
    -- ���O�C�����[�U�[�F��������
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID);
--
    -- ���O�C�����[�U�[�F���[�U�[��
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID);
--
    -- ====================================================
    -- �I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
  EXCEPTION
--
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
--
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_param
   * Description      : XML�f�[�^�ϊ� - �p�����[�^��񕔕�(param_info)
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_param
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    -- ====================================================
    -- �f�[�^�^�O
    -- ====================================================
    -- �N�x
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'year';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.year || gv_name_year;
--
    -- ����
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sdi_num';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.gen;
--
    -- �o�͒P��
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'out_unit';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- ���̓p�����[�^����               --
    --------------------------------------
    -- [0]�̏ꍇ
    IF (gr_param.output_unit = gv_output_unit) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := gv_output_unit_0;  -- '�{��'
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := gv_output_unit_1;  -- '�P�[�X'
    END IF;
--
    -- ====================================================
    -- �I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/param_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
  EXCEPTION
--
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
--
  END prc_create_xml_data_param ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data_dtl
   * Description      : XML�f�[�^�쐬 - ���[�f�[�^�o�� ���׍s �f�[�^�L
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_dtl
    (
      iv_label_name     IN VARCHAR2  -- �o�̓^�O��
     ,in_quant          IN NUMBER    -- ����
     ,in_case_quant     IN NUMBER    -- ����
     ,in_amount         IN NUMBER    -- ���z
     ,in_total_amount   IN NUMBER    -- ���󍇌v
     ,iv_price_st       IN VARCHAR2  -- �艿�K�p�J�n��
     ,in_n_amount       IN NUMBER    -- �V�艿
     ,in_o_amount       IN NUMBER    -- ���艿
     ,on_quant         OUT NUMBER    -- �N�v�p ����
     ,on_price         OUT NUMBER    -- �N�v�p �i�ڒ艿
     ,ov_errbuf        OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_dtl'; -- �v���O������
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
    ln_chk_0          NUMBER;     -- �O���Z���荀��
    ln_kake_par       NUMBER;     -- �v�Z���ʔ���
    ln_arari          NUMBER;     -- �e���p
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
    -- ���ʃf�[�^
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
    -- ���͂o�w�o�͒P�ʁx���u�{���v�̏ꍇ
    IF (gr_param.output_unit = gv_output_unit) THEN
      on_quant := in_quant;
--
      gt_xml_data_table(gl_xml_idx).tag_value := on_quant;
    -- ���͂o�w�o�͒P�ʁx���u�P�[�X�v�̏ꍇ
    ELSE
      -- �O���Z��𔻒�
      IF (in_case_quant <> gn_0) THEN
        -- �l��[0]�o�Ȃ���΁A���ʌv�Z  (���� / ����)  �����ȉ�1�ʐ؏�
        on_quant := CEIL(in_quant / in_case_quant);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        on_quant :=  gn_0;
      END IF;
        gt_xml_data_table(gl_xml_idx).tag_value := on_quant;
    END IF;
--
    -- -----------------------------------------------------
    -- ���z�f�[�^
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND(in_amount / 1000,0);
--
    -- -----------------------------------------------------
    -- �e�����f�[�^
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
    -- �e���v�Z (���z�|���󍇌v������)
    ln_arari := in_amount - in_total_amount * in_quant;
    -- �O���Z��𔻒�
    IF (in_amount <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := ROUND((ln_arari / in_amount * 100),2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- -----------------------------------------------------
    -- �|���f�[�^
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
    -- �i�ڒ艿����  �艿�K�p�J�n���ɂċ��艿�E�V�艿�̎g�p���f
    -- �N�x�J�n������OPM�i�ڃ}�X�^�艿�K�p�J�n���ȏ�̏ꍇ
    IF (FND_DATE.STRING_TO_DATE(iv_price_st,'YYYY/MM/DD')   <= gd_start_day) THEN
      -- �V�艿���g�p
      on_price := in_n_amount;
    -- �N�x�J�n������OPM�i�ڃ}�X�^�艿�K�p�J�n�������̏ꍇ
    ELSIF (FND_DATE.STRING_TO_DATE(iv_price_st,'YYYY/MM/DD') > gd_start_day) THEN
      -- ���艿���g�p
      on_price := in_o_amount;
    END IF;
--
    -- �O���Z���荀�ڂ֔���l��}��
--2008.04.30 Y.Kawano modify start
--    ln_chk_0 := on_price * in_quant * 100;
    ln_chk_0 := on_price * in_quant;
--2008.04.30 Y.Kawano modify end
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
--2008.04.30 Y.Kawano modify start
--      ln_kake_par := ROUND(in_amount / ln_chk_0,2);
      ln_kake_par := ROUND((in_amount * 100) / ln_chk_0,2);
--2008.04.30 Y.Kawano modify end
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((on_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
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
  END prc_create_xml_data_dtl;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data_dtl_n
   * Description      : XML�f�[�^�쐬 - ���[�f�[�^�o�� ���׍s �f�[�^��
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_dtl_n
    (
      iv_label_name     IN VARCHAR2 -- �o�̓^�O��
     ,ov_errbuf        OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_dtl_n'; -- �v���O������
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
    -- ���ʃf�[�^
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
--
    -- -----------------------------------------------------
    -- ���z�f�[�^
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
--
    -- -----------------------------------------------------
    -- �e�����f�[�^
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
--
    -- -----------------------------------------------------
    -- �|���f�[�^
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
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
  END prc_create_xml_data_dtl_n;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data_st_lt
   * Description      : XML�f�[�^�쐬 - ���[�f�[�^�o�� ���Q�v/��Q�v
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_st_lt
    (
      iv_label_name     IN VARCHAR2 -- �Q�v�p�^�O��
     ,iv_name           IN VARCHAR2 -- �Q�v�^�C�g��
     ,in_may_quant      IN NUMBER   -- �T�� ����
     ,in_may_amount     IN NUMBER   -- �T�� ���z
     ,in_may_price      IN NUMBER   -- �T�� �i�ڒ艿
     ,in_may_to_amount  IN NUMBER   -- �T�� ���󍇌v
     ,in_may_quant_t    IN NUMBER   -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_may_s_cost     IN NUMBER   -- �T�� �W������(�v�Z�p)
     ,in_may_calc       IN NUMBER   -- �T�� �i�ڒ艿*����(�v�Z�p)
     ,in_may_minus_flg   IN VARCHAR2 -- �T�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_may_ht_zero_flg IN VARCHAR2 -- �T�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_jun_quant      IN NUMBER   -- �U�� ����
     ,in_jun_amount     IN NUMBER   -- �U�� ���z
     ,in_jun_price      IN NUMBER   -- �U�� �i�ڒ艿
     ,in_jun_to_amount  IN NUMBER   -- �U�� ���󍇌v
     ,in_jun_quant_t    IN NUMBER   -- �U�� ����(�v�Z�p)
 -- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_jun_s_cost     IN NUMBER   -- �U�� �W������(�v�Z�p)
     ,in_jun_calc       IN NUMBER   -- �U�� �i�ڒ艿*����(�v�Z�p)
     ,in_jun_minus_flg   IN VARCHAR2 -- �U�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_jun_ht_zero_flg IN VARCHAR2 -- �U�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_jul_quant      IN NUMBER   -- �V�� ����
     ,in_jul_amount     IN NUMBER   -- �V�� ���z
     ,in_jul_price      IN NUMBER   -- �V�� �i�ڒ艿
     ,in_jul_to_amount  IN NUMBER   -- �V�� ���󍇌v
     ,in_jul_quant_t    IN NUMBER   -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_jul_s_cost     IN NUMBER   -- �V�� �W������(�v�Z�p)
     ,in_jul_calc       IN NUMBER   -- �V�� �i�ڒ艿*����(�v�Z�p)
     ,in_jul_minus_flg   IN VARCHAR2 -- �V�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_jul_ht_zero_flg IN VARCHAR2 -- �V�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_aug_quant      IN NUMBER   -- �W�� ����
     ,in_aug_amount     IN NUMBER   -- �W�� ���z
     ,in_aug_price      IN NUMBER   -- �W�� �i�ڒ艿
     ,in_aug_to_amount  IN NUMBER   -- �W�� ���󍇌v
     ,in_aug_quant_t    IN NUMBER   -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_aug_s_cost     IN NUMBER   -- �W�� �W������(�v�Z�p)
     ,in_aug_calc       IN NUMBER   -- �W�� �i�ڒ艿*����(�v�Z�p)
     ,in_aug_minus_flg   IN VARCHAR2 -- �W�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_aug_ht_zero_flg IN VARCHAR2 -- �W�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_sep_quant      IN NUMBER   -- �X�� ����
     ,in_sep_amount     IN NUMBER   -- �X�� ���z
     ,in_sep_price      IN NUMBER   -- �X�� �i�ڒ艿
     ,in_sep_to_amount  IN NUMBER   -- �X�� ���󍇌v
     ,in_sep_quant_t    IN NUMBER   -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_sep_s_cost     IN NUMBER   -- �X�� �W������(�v�Z�p)
     ,in_sep_calc       IN NUMBER   -- �X�� �i�ڒ艿*����(�v�Z�p)
     ,in_sep_minus_flg   IN VARCHAR2 -- �X�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_sep_ht_zero_flg IN VARCHAR2 -- �X�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_oct_quant      IN NUMBER   -- �P�O�� ����
     ,in_oct_amount     IN NUMBER   -- �P�O�� ���z
     ,in_oct_price      IN NUMBER   -- �P�O�� �i�ڒ艿
     ,in_oct_to_amount  IN NUMBER   -- �P�O�� ���󍇌v
     ,in_oct_quant_t    IN NUMBER   -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_oct_s_cost     IN NUMBER   -- �P�O�� �W������(�v�Z�p)
     ,in_oct_calc       IN NUMBER   -- �P�O�� �i�ڒ艿*����(�v�Z�p)
     ,in_oct_minus_flg   IN VARCHAR2 -- �P�O�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_oct_ht_zero_flg IN VARCHAR2 -- �P�O�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_nov_quant      IN NUMBER   -- �P�P�� ����
     ,in_nov_amount     IN NUMBER   -- �P�P�� ���z
     ,in_nov_price      IN NUMBER   -- �P�P�� �i�ڒ艿
     ,in_nov_to_amount  IN NUMBER   -- �P�P�� ���󍇌v
     ,in_nov_quant_t    IN NUMBER   -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_nov_s_cost     IN NUMBER   -- �P�P�� �W������(�v�Z�p)
     ,in_nov_calc       IN NUMBER   -- �P�P�� �i�ڒ艿*����(�v�Z�p)
     ,in_nov_minus_flg   IN VARCHAR2 -- �P�P�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_nov_ht_zero_flg IN VARCHAR2 -- �P�P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_dec_quant      IN NUMBER   -- �P�Q�� ����
     ,in_dec_amount     IN NUMBER   -- �P�Q�� ���z
     ,in_dec_price      IN NUMBER   -- �P�Q�� �i�ڒ艿
     ,in_dec_to_amount  IN NUMBER   -- �P�Q�� ���󍇌v
     ,in_dec_quant_t    IN NUMBER   -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_dec_s_cost     IN NUMBER   -- �P�Q�� �W������(�v�Z�p)
     ,in_dec_calc       IN NUMBER   -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
     ,in_dec_minus_flg   IN VARCHAR2 -- �P�Q�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_dec_ht_zero_flg IN VARCHAR2 -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_jan_quant      IN NUMBER   -- �P�� ����
     ,in_jan_amount     IN NUMBER   -- �P�� ���z
     ,in_jan_price      IN NUMBER   -- �P�� �i�ڒ艿
     ,in_jan_to_amount  IN NUMBER   -- �P�� ���󍇌v
     ,in_jan_quant_t    IN NUMBER   -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_jan_s_cost     IN NUMBER   -- �P�� �W������(�v�Z�p)
     ,in_jan_calc       IN NUMBER   -- �P�� �i�ڒ艿*����(�v�Z�p)
     ,in_jan_minus_flg   IN VARCHAR2 -- �P�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_jan_ht_zero_flg IN VARCHAR2 -- �P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_feb_quant      IN NUMBER   -- �Q�� ����
     ,in_feb_amount     IN NUMBER   -- �Q�� ���z
     ,in_feb_price      IN NUMBER   -- �Q�� �i�ڒ艿
     ,in_feb_to_amount  IN NUMBER   -- �Q�� ���󍇌v
     ,in_feb_quant_t    IN NUMBER   -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_feb_s_cost     IN NUMBER   -- �Q�� �W������(�v�Z�p)
     ,in_feb_calc       IN NUMBER   -- �Q�� �i�ڒ艿*����(�v�Z�p)
     ,in_feb_minus_flg   IN VARCHAR2 -- �Q�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_feb_ht_zero_flg IN VARCHAR2 -- �Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_mar_quant      IN NUMBER   -- �R�� ����
     ,in_mar_amount     IN NUMBER   -- �R�� ���z
     ,in_mar_price      IN NUMBER   -- �R�� �i�ڒ艿
     ,in_mar_to_amount  IN NUMBER   -- �R�� ���󍇌v
     ,in_mar_quant_t    IN NUMBER   -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_mar_s_cost     IN NUMBER   -- �R�� �W������(�v�Z�p)
     ,in_mar_calc       IN NUMBER   -- �R�� �i�ڒ艿*����(�v�Z�p)
     ,in_mar_minus_flg   IN VARCHAR2 -- �R�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_mar_ht_zero_flg IN VARCHAR2 -- �R�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_apr_quant      IN NUMBER   -- �S�� ����
     ,in_apr_amount     IN NUMBER   -- �S�� ���z
     ,in_apr_price      IN NUMBER   -- �S�� �i�ڒ艿
     ,in_apr_to_amount  IN NUMBER   -- �S�� ���󍇌v
     ,in_apr_quant_t    IN NUMBER   -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_apr_s_cost     IN NUMBER   -- �S�� �W������(�v�Z�p)
     ,in_apr_calc       IN NUMBER   -- �S�� �i�ڒ艿*����(�v�Z�p)
     ,in_apr_minus_flg   IN VARCHAR2 -- �S�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_apr_ht_zero_flg IN VARCHAR2 -- �S�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_year_quant     IN NUMBER   -- �N�v ����
     ,in_year_amount    IN NUMBER   -- �N�v ���z
     ,in_year_price     IN NUMBER   -- �N�v �i�ڒ艿
     ,in_year_to_amount IN NUMBER   -- �N�v ���󍇌v
     ,in_year_quant_t   IN NUMBER   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_year_s_cost    IN NUMBER   -- �N�v �W������(�v�Z�p)
     ,in_year_calc      IN NUMBER   -- �N�v �i�ڒ艿*����(�v�Z�p)
     ,in_year_minus_flg   IN VARCHAR2 -- �N�v�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_year_ht_zero_flg IN VARCHAR2 -- �N�v�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,ov_errbuf        OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_st_lt'; -- �v���O������
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
    ln_chk_0          NUMBER;     -- �O���Z���荀��
    ln_kake_par       NUMBER;     -- �v�Z���ʔ���
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
    -- �f�[�^�^�O
    -- ====================================================
    -- �Q�v�^�C�g��
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'label';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := iv_name;
--
    -- �T�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_may_quant_t;
--
    -- �T�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_may_amount / 1000),0);
--
    -- �T�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_may_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_may_amount - in_may_to_amount * in_may_quant) / in_may_amount) * 100,2);
        ROUND(((in_may_amount - in_may_s_cost) / in_may_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �T�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_may_price * in_may_quant;
    ln_chk_0 := in_may_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_may_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_may_amount = 0)
      AND (in_may_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_may_price = 0)
      OR (ln_kake_par < 0)) THEN
        ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_may_minus_flg = 'Y' ) OR ( in_may_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- �U�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_jun_quant_t;
--
    -- �U�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_jun_amount / 1000),0);
--
    -- �U�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_jun_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_jun_amount - in_jun_to_amount * in_jun_quant) / in_jun_amount) * 100,2);
        ROUND(((in_jun_amount - in_jun_s_cost) / in_jun_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �U�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_jun_price * in_jun_quant;
    ln_chk_0 := in_jun_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_jun_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_jun_amount = 0)
      AND (in_jun_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_jun_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_jun_minus_flg = 'Y' ) OR ( in_jun_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- �V�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_jul_quant_t;
--
    -- �V�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_jul_amount / 1000),0);
--
    -- �V�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_jul_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_jul_amount - in_jul_to_amount * in_jul_quant) / in_jul_amount) * 100,2);
        ROUND(((in_jul_amount - in_jul_s_cost) / in_jul_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �V�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_jul_price * in_jul_quant;
    ln_chk_0 := in_jul_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_jul_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_jul_amount = 0)
      AND (in_jul_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_jul_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_jul_minus_flg = 'Y' ) OR ( in_jul_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- �W�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_aug_quant_t;
--
    -- �W�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_aug_amount / 1000),0);
--
    -- �W�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_aug_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_aug_amount - in_aug_to_amount * in_aug_quant) / in_aug_amount) * 100,2);
        ROUND(((in_aug_amount - in_aug_s_cost) / in_aug_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �W�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_aug_price * in_aug_quant;
    ln_chk_0 := in_aug_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_aug_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_aug_amount = 0)
      AND (in_aug_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_aug_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_aug_minus_flg = 'Y' ) OR ( in_aug_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- �X�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_sep_quant_t;
--
    -- �X�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_sep_amount / 1000),0);
--
    -- �X�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_sep_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_sep_amount - in_sep_to_amount * in_sep_quant) / in_sep_amount) * 100,2);
        ROUND(((in_sep_amount - in_sep_s_cost) / in_sep_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �X�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_sep_price * in_sep_quant;
    ln_chk_0 := in_sep_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_sep_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6F T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_sep_amount = 0)
      AND (in_sep_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_sep_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_sep_minus_flg = 'Y' ) OR ( in_sep_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- �P�O�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_oct_quant_t;
--
    -- �P�O�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_oct_amount / 1000),0);
--
    -- �P�O�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_oct_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_oct_amount - in_oct_to_amount * in_oct_quant) / in_oct_amount) * 100,2);
        ROUND(((in_oct_amount - in_oct_s_cost) / in_oct_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �P�O�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_oct_price * in_oct_quant;
    ln_chk_0 := in_oct_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_oct_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_oct_amount = 0)
      AND (in_oct_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_oct_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_oct_minus_flg = 'Y' ) OR ( in_oct_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- �P�P�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_nov_quant_t;
--
    -- �P�P�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_nov_amount / 1000),0);
--
    -- �P�P�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_nov_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_nov_amount - in_nov_to_amount * in_nov_quant) / in_nov_amount) * 100,2);
        ROUND(((in_nov_amount - in_nov_s_cost) / in_nov_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �P�P�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_nov_price * in_nov_quant;
    ln_chk_0 := in_nov_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_nov_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_nov_amount = 0)
      AND (in_nov_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_nov_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_nov_minus_flg = 'Y' ) OR ( in_nov_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- �P�Q�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_dec_quant_t;
--
    -- �P�Q�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_dec_amount / 1000),0);
--
    -- �P�Q�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_dec_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_dec_amount - in_dec_to_amount * in_dec_quant) / in_dec_amount) * 100,2);
        ROUND(((in_dec_amount - in_dec_s_cost) / in_dec_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �P�Q�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_dec_price * in_dec_quant;
    ln_chk_0 := in_dec_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_dec_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_dec_amount = 0)
      AND (in_dec_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_dec_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_dec_minus_flg = 'Y' ) OR ( in_dec_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- �P�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_jan_quant_t;
--
    -- �P�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_jan_amount / 1000),0);
--
    -- �P�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_jan_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_jan_amount - in_jan_to_amount * in_jan_quant) / in_jan_amount) * 100,2);
        ROUND(((in_jan_amount - in_jan_s_cost) / in_jan_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �P�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_jan_price * in_jan_quant;
    ln_chk_0 := in_jan_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_jan_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_jan_amount = 0)
      AND (in_jan_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_jan_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_jan_minus_flg = 'Y' ) OR ( in_jan_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- �Q�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_feb_quant_t;
--
    -- �Q�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_feb_amount / 1000),0);
--
    -- �Q�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_feb_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_feb_amount - in_feb_to_amount * in_feb_quant) / in_feb_amount) * 100,2);
        ROUND(((in_feb_amount - in_feb_s_cost) / in_feb_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �Q�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_feb_price * in_feb_quant;
    ln_chk_0 := in_feb_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_feb_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_feb_amount = 0)
      AND (in_feb_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_feb_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_feb_minus_flg = 'Y' ) OR ( in_feb_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- �R�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_mar_quant_t;
--
    -- �R�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_mar_amount / 1000),0);
--
    -- �R�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_mar_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_mar_amount - in_mar_to_amount * in_mar_quant) / in_mar_amount) * 100,2);
        ROUND(((in_mar_amount - in_mar_s_cost) / in_mar_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �R�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_mar_price * in_mar_quant;
    ln_chk_0 := in_mar_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_mar_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_mar_amount = 0)
      AND (in_mar_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_mar_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_mar_minus_flg = 'Y' ) OR ( in_mar_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- �S�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_apr_quant_t;
--
    -- �S�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_apr_amount / 1000),0);
--
    -- �S�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_apr_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_apr_amount - in_apr_to_amount * in_apr_quant) / in_apr_amount) * 100,2);
        ROUND(((in_apr_amount - in_apr_s_cost) / in_apr_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �S�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_apr_price * in_apr_quant;
    ln_chk_0 := in_apr_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_apr_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_apr_amount = 0)
      AND (in_apr_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_apr_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_apr_minus_flg = 'Y' ) OR ( in_apr_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
    -- �N�v ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_year_quant_t;
--
    -- �N�v ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_year_amount / 1000),0);
--
    -- �N�v �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_year_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--          ROUND(((in_year_amount - in_year_to_amount * in_year_quant) / in_year_amount) * 100,2);
        ROUND(((in_year_amount - in_year_s_cost) / in_year_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �N�v �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_year_price * in_year_quant;
    ln_chk_0 := in_year_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_year_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_year_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_year_minus_flg = 'Y' ) OR ( in_year_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
--
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
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
  END prc_create_xml_data_st_lt;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data_s_k_t
   * Description      : XML�f�[�^�쐬 - ���[�f�[�^�o�� ���_�v/���i�敪�v/�����v�p
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_s_k_t
    (
      iv_label_name     IN VARCHAR2 -- �v�^�C�g��
     ,in_may_quant      IN NUMBER   -- �T�� ����
     ,in_may_amount     IN NUMBER   -- �T�� ���z
     ,in_may_price      IN NUMBER   -- �T�� �i�ڒ艿
     ,in_may_to_amount  IN NUMBER   -- �T�� ���󍇌v
     ,in_may_quant_t    IN NUMBER   -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_may_s_cost     IN NUMBER   -- �T�� �W������(�v�Z�p)
     ,in_may_calc       IN NUMBER   -- �T�� �i�ڒ艿*����(�v�Z�p)
     ,in_may_minus_flg   IN VARCHAR2 -- �T�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_may_ht_zero_flg IN VARCHAR2 -- �T�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_jun_quant      IN NUMBER   -- �U�� ����
     ,in_jun_amount     IN NUMBER   -- �U�� ���z
     ,in_jun_price      IN NUMBER   -- �U�� �i�ڒ艿
     ,in_jun_to_amount  IN NUMBER   -- �U�� ���󍇌v
     ,in_jun_quant_t    IN NUMBER   -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_jun_s_cost     IN NUMBER   -- �U�� �W������(�v�Z�p)
     ,in_jun_calc       IN NUMBER   -- �U�� �i�ڒ艿*����(�v�Z�p)
     ,in_jun_minus_flg   IN VARCHAR2 -- �U�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_jun_ht_zero_flg IN VARCHAR2 -- �U�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_jul_quant      IN NUMBER   -- �V�� ����
     ,in_jul_amount     IN NUMBER   -- �V�� ���z
     ,in_jul_price      IN NUMBER   -- �V�� �i�ڒ艿
     ,in_jul_to_amount  IN NUMBER   -- �V�� ���󍇌v
     ,in_jul_quant_t    IN NUMBER   -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_jul_s_cost     IN NUMBER   -- �V�� �W������(�v�Z�p)
     ,in_jul_calc       IN NUMBER   -- �V�� �i�ڒ艿*����(�v�Z�p)
     ,in_jul_minus_flg   IN VARCHAR2 -- �V�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_jul_ht_zero_flg IN VARCHAR2 -- �V�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_aug_quant      IN NUMBER   -- �W�� ����
     ,in_aug_amount     IN NUMBER   -- �W�� ���z
     ,in_aug_price      IN NUMBER   -- �W�� �i�ڒ艿
     ,in_aug_to_amount  IN NUMBER   -- �W�� ���󍇌v
     ,in_aug_quant_t    IN NUMBER   -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_aug_s_cost     IN NUMBER   -- �W�� �W������(�v�Z�p)
     ,in_aug_calc       IN NUMBER   -- �W�� �i�ڒ艿*����(�v�Z�p)
     ,in_aug_minus_flg   IN VARCHAR2 -- �W�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_aug_ht_zero_flg IN VARCHAR2 -- �W�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_sep_quant      IN NUMBER   -- �X�� ����
     ,in_sep_amount     IN NUMBER   -- �X�� ���z
     ,in_sep_price      IN NUMBER   -- �X�� �i�ڒ艿
     ,in_sep_to_amount  IN NUMBER   -- �X�� ���󍇌v
     ,in_sep_quant_t    IN NUMBER   -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_sep_s_cost     IN NUMBER   -- �X�� �W������(�v�Z�p)
     ,in_sep_calc       IN NUMBER   -- �X�� �i�ڒ艿*����(�v�Z�p)
     ,in_sep_minus_flg   IN VARCHAR2 -- �X�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_sep_ht_zero_flg IN VARCHAR2 -- �X�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_oct_quant      IN NUMBER   -- �P�O�� ����
     ,in_oct_amount     IN NUMBER   -- �P�O�� ���z
     ,in_oct_price      IN NUMBER   -- �P�O�� �i�ڒ艿
     ,in_oct_to_amount  IN NUMBER   -- �P�O�� ���󍇌v
     ,in_oct_quant_t    IN NUMBER   -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_oct_s_cost     IN NUMBER   -- �P�O�� �W������(�v�Z�p)
     ,in_oct_calc       IN NUMBER   -- �P�O�� �i�ڒ艿*����(�v�Z�p)
     ,in_oct_minus_flg   IN VARCHAR2 -- �P�O�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_oct_ht_zero_flg IN VARCHAR2 -- �P�O�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_nov_quant      IN NUMBER   -- �P�P�� ����
     ,in_nov_amount     IN NUMBER   -- �P�P�� ���z
     ,in_nov_price      IN NUMBER   -- �P�P�� �i�ڒ艿
     ,in_nov_to_amount  IN NUMBER   -- �P�P�� ���󍇌v
     ,in_nov_quant_t    IN NUMBER   -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_nov_s_cost     IN NUMBER   -- �P�P�� �W������(�v�Z�p)
     ,in_nov_calc       IN NUMBER   -- �P�P�� �i�ڒ艿*����(�v�Z�p)
     ,in_nov_minus_flg   IN VARCHAR2 -- �P�P�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_nov_ht_zero_flg IN VARCHAR2 -- �P�P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_dec_quant      IN NUMBER   -- �P�Q�� ����
     ,in_dec_amount     IN NUMBER   -- �P�Q�� ���z
     ,in_dec_price      IN NUMBER   -- �P�Q�� �i�ڒ艿
     ,in_dec_to_amount  IN NUMBER   -- �P�Q�� ���󍇌v
     ,in_dec_quant_t    IN NUMBER   -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_dec_s_cost     IN NUMBER   -- �P�Q�� �W������(�v�Z�p)
     ,in_dec_calc       IN NUMBER   -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
     ,in_dec_minus_flg   IN VARCHAR2 -- �P�Q�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_dec_ht_zero_flg IN VARCHAR2 -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_jan_quant      IN NUMBER   -- �P�� ����
     ,in_jan_amount     IN NUMBER   -- �P�� ���z
     ,in_jan_price      IN NUMBER   -- �P�� �i�ڒ艿
     ,in_jan_to_amount  IN NUMBER   -- �P�� ���󍇌v
     ,in_jan_quant_t    IN NUMBER   -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_jan_s_cost     IN NUMBER   -- �P�� �W������(�v�Z�p)
     ,in_jan_calc       IN NUMBER   -- �P�� �i�ڒ艿*����(�v�Z�p)
     ,in_jan_minus_flg   IN VARCHAR2 -- �P�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_jan_ht_zero_flg IN VARCHAR2 -- �P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_feb_quant      IN NUMBER   -- �Q�� ����
     ,in_feb_amount     IN NUMBER   -- �Q�� ���z
     ,in_feb_price      IN NUMBER   -- �Q�� �i�ڒ艿
     ,in_feb_to_amount  IN NUMBER   -- �Q�� ���󍇌v
     ,in_feb_quant_t    IN NUMBER   -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_feb_s_cost     IN NUMBER   -- �Q�� �W������(�v�Z�p)
     ,in_feb_calc       IN NUMBER   -- �Q�� �i�ڒ艿*����(�v�Z�p)
     ,in_feb_minus_flg   IN VARCHAR2 -- �Q�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_feb_ht_zero_flg IN VARCHAR2 -- �Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_mar_quant      IN NUMBER   -- �R�� ����
     ,in_mar_amount     IN NUMBER   -- �R�� ���z
     ,in_mar_price      IN NUMBER   -- �R�� �i�ڒ艿
     ,in_mar_to_amount  IN NUMBER   -- �R�� ���󍇌v
     ,in_mar_quant_t    IN NUMBER   -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_mar_s_cost     IN NUMBER   -- �R�� �W������(�v�Z�p)
     ,in_mar_calc       IN NUMBER   -- �R�� �i�ڒ艿*����(�v�Z�p)
     ,in_mar_minus_flg   IN VARCHAR2 -- �R�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_mar_ht_zero_flg IN VARCHAR2 -- �R�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_apr_quant      IN NUMBER   -- �S�� ����
     ,in_apr_amount     IN NUMBER   -- �S�� ���z
     ,in_apr_price      IN NUMBER   -- �S�� �i�ڒ艿
     ,in_apr_to_amount  IN NUMBER   -- �S�� ���󍇌v
     ,in_apr_quant_t    IN NUMBER   -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_apr_s_cost     IN NUMBER   -- �S�� �W������(�v�Z�p)
     ,in_apr_calc       IN NUMBER   -- �S�� �i�ڒ艿*����(�v�Z�p)
     ,in_apr_minus_flg   IN VARCHAR2 -- �S�� �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_apr_ht_zero_flg IN VARCHAR2 -- �S�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,in_year_quant     IN NUMBER   -- �N�v ����
     ,in_year_amount    IN NUMBER   -- �N�v ���z
     ,in_year_price     IN NUMBER   -- �N�v �i�ڒ艿
     ,in_year_to_amount IN NUMBER   -- �N�v ���󍇌v
     ,in_year_quant_t   IN NUMBER   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
     ,in_year_s_cost    IN NUMBER   -- �N�v �W������(�v�Z�p)
     ,in_year_calc      IN NUMBER   -- �N�v �i�ڒ艿*����(�v�Z�p)
     ,in_year_minus_flg   IN VARCHAR2 -- �N�v �}�C�i�X�l���݃t���O(�v�Z�p)
     ,in_year_ht_zero_flg IN VARCHAR2 -- �N�v �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
     ,ov_errbuf        OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_s_k_t'; -- �v���O������
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
    ln_chk_0          NUMBER;     -- �O���Z���荀��
    ln_kake_par       NUMBER;     -- �v�Z���ʔ���
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
    -- �f�[�^�^�O
    -- ====================================================
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- �T�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start �{��#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_may_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_may_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End �{��#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- �T�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_may_amount / 1000),0);
--
    -- �T�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_may_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_may_amount - in_may_to_amount * in_may_quant) / in_may_amount) * 100,2);
        ROUND(((in_may_amount - in_may_s_cost) / in_may_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �T�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'may_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_may_price * in_may_quant;
    ln_chk_0 := in_may_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_may_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_may_amount = 0)
      AND (in_may_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_may_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_may_minus_flg = 'Y' ) OR ( in_may_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- �U�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start �{��#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_jun_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_jun_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End �{��#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- �U�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_jun_amount / 1000),0);
--
    -- �U�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_jun_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_jun_amount - in_jun_to_amount * in_jun_quant) / in_jun_amount) * 100,2);
        ROUND(((in_jun_amount - in_jun_s_cost) / in_jun_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �U�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jun_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_jun_price * in_jun_quant;
    ln_chk_0 := in_jun_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_jun_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_jun_amount = 0)
      AND (in_jun_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_jun_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_jun_minus_flg = 'Y' ) OR ( in_jun_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- �V�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start �{��#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_jul_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_jul_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End �{��#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- �V�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_jul_amount / 1000),0);
--
    -- �V�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_jul_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_jul_amount - in_jul_to_amount * in_jul_quant) / in_jul_amount) * 100,2);
        ROUND(((in_jul_amount - in_jul_s_cost) / in_jul_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �V�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jul_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_jul_price * in_jul_quant;
    ln_chk_0 := in_jul_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_jul_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_jul_amount = 0)
      AND (in_jul_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_jul_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_jul_minus_flg = 'Y' ) OR ( in_jul_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- �W�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start �{��#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_aug_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_aug_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End �{��#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- �W�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_aug_amount / 1000),0);
--
    -- �W�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_aug_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_aug_amount - in_aug_to_amount * in_aug_quant) / in_aug_amount) * 100,2);
        ROUND(((in_aug_amount - in_aug_s_cost) / in_aug_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �W�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'aug_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_aug_price * in_aug_quant;
    ln_chk_0 := in_aug_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_aug_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_aug_amount = 0)
      AND (in_aug_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_aug_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_aug_minus_flg = 'Y' ) OR ( in_aug_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- �X�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start �{��#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_sep_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_sep_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End �{��#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- �X�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_sep_amount / 1000),0);
--
    -- �X�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_sep_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_sep_amount - in_sep_to_amount * in_sep_quant) / in_sep_amount) * 100,2);
        ROUND(((in_sep_amount - in_sep_s_cost) / in_sep_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �X�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'sep_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_sep_price * in_sep_quant;
    ln_chk_0 := in_sep_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_sep_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_sep_amount = 0)
      AND (in_sep_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_sep_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_sep_minus_flg = 'Y' ) OR ( in_sep_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- �P�O�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start �{��#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_oct_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_oct_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End �{��#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- �P�O�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_oct_amount / 1000),0);
--
    -- �P�O�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_oct_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_oct_amount - in_oct_to_amount * in_oct_quant) / in_oct_amount) * 100,2);
        ROUND(((in_oct_amount - in_oct_s_cost) / in_oct_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �P�O�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'oct_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_oct_price * in_oct_quant;
    ln_chk_0 := in_oct_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_oct_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_oct_amount = 0)
      AND (in_oct_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_oct_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_oct_minus_flg = 'Y' ) OR ( in_oct_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- �P�P�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start �{��#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_nov_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_nov_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End �{��#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- �P�P�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_nov_amount / 1000),0);
--
    -- �P�P�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_nov_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_nov_amount - in_nov_to_amount * in_nov_quant) / in_nov_amount) * 100,2);
        ROUND(((in_nov_amount - in_nov_s_cost) / in_nov_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �P�P�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'nov_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_nov_price * in_nov_quant;
    ln_chk_0 := in_nov_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_nov_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_nov_amount = 0)
      AND (in_nov_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_nov_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_nov_minus_flg = 'Y' ) OR ( in_nov_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- �P�Q�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start �{��#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_dec_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_dec_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End �{��#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- �P�Q�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_dec_amount / 1000),0);
--
    -- �P�Q�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_dec_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_dec_amount - in_dec_to_amount * in_dec_quant) / in_dec_amount) * 100,2);
            ROUND(((in_dec_amount - in_dec_s_cost) / in_dec_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410

    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �P�Q�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'dec_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_dec_price * in_dec_quant;
    ln_chk_0 := in_dec_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_dec_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_dec_amount = 0)
      AND (in_dec_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_dec_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_dec_minus_flg = 'Y' ) OR ( in_dec_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- �P�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start �{��#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_jan_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_jan_quant_T;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End �{��#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- �P�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_jan_amount / 1000),0);
--
    -- �P�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_jan_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_jan_amount - in_jan_to_amount * in_jan_quant) / in_jan_amount) * 100,2);
        ROUND(((in_jan_amount - in_jan_s_cost) / in_jan_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �P�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'jan_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_jan_price * in_jan_quant;
    ln_chk_0 := in_jan_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_jan_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_jan_amount = 0)
      AND (in_jan_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_jan_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_jan_minus_flg = 'Y' ) OR ( in_jan_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- �Q�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start �{��#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_feb_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_feb_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End �{��#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- �Q�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_feb_amount / 1000),0);
--
    -- �Q�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_feb_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_feb_amount - in_feb_to_amount * in_feb_quant) / in_feb_amount) * 100,2);
        ROUND(((in_feb_amount - in_feb_s_cost) / in_feb_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �Q�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'feb_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_feb_price * in_feb_quant;
    ln_chk_0 := in_feb_calc;
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_feb_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_feb_amount = 0)
      AND (in_feb_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_feb_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_feb_minus_flg = 'Y' ) OR ( in_feb_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- �R�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start �{��#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_mar_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_mar_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod end �{��#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- �R�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_mar_amount / 1000),0);
--
    -- �R�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_mar_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_mar_amount - in_mar_to_amount * in_mar_quant) / in_mar_amount) * 100,2);
        ROUND(((in_mar_amount - in_mar_s_cost) / in_mar_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �R�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'mar_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_mar_price * in_mar_quant;
    ln_chk_0 := in_mar_calc;
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_mar_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_mar_amount = 0)
      AND (in_mar_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_mar_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_mar_minus_flg = 'Y' ) OR ( in_mar_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- �S�� ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2009/05/29 v1.7 T.Yoshimoto Mod Start �{��#1509
--    gt_xml_data_table(gl_xml_idx).tag_value := in_apr_quant;
    gt_xml_data_table(gl_xml_idx).tag_value := in_apr_quant_t;
-- 2009/05/29 v1.7 T.Yoshimoto Mod End �{��#1509
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- �S�� ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_apr_amount / 1000),0);
--
    -- �S�� �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_apr_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--            ROUND(((in_apr_amount - in_apr_to_amount * in_apr_quant) / in_apr_amount) * 100,2);
        ROUND(((in_apr_amount - in_apr_s_cost) / in_apr_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �S�� �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'apr_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_apr_price * in_apr_quant;
    ln_chk_0 := in_apr_calc;
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_apr_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_apr_amount = 0)
      AND (in_apr_price = 0)) THEN
      ln_kake_par := gn_0;
    ELSIF ((in_apr_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_apr_minus_flg = 'Y' ) OR ( in_apr_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    -- �N�v ���ʃf�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_quant';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := in_year_quant;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- �N�v ���z�f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ROUND((in_year_amount / 1000),0);
--
    -- �N�v �e�����f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_arari_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------
    -- �O���Z��𔻒�             --
    --------------------------------
    IF (in_year_amount <> 0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      gt_xml_data_table(gl_xml_idx).tag_value := 
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--          ROUND(((in_year_amount - in_year_to_amount * in_year_quant) / in_year_amount) * 100,2);
        ROUND(((in_year_amount - in_year_s_cost) / in_year_amount) * 100,2);
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
    END IF;
--
    -- �N�v �|���f�[�^
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := iv_label_name || 'year_kake_par';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    --------------------------------------
    -- �O���Z���荀�ڂ֔���l��}��     --
    --------------------------------------
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
--    ln_chk_0 := in_year_price * in_year_quant;
    ln_chk_0 := in_year_calc;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
    -- �O���Z��𔻒�
    IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((in_year_amount * 100) / ln_chk_0,2);
    ELSE
      -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
      ln_kake_par := gn_0;
    END IF;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
/*
    -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF ((in_year_price = 0)
      OR (ln_kake_par < 0)) THEN
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
    END IF;
*/
    -- �i�ڒ艿 = �O�����݂��Ă���A�܂��͐��ʂɃ}�C�i�X�l�����݂��Ă���
    -- �܂��͌v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
    IF (( in_year_minus_flg = 'Y' ) OR ( in_year_ht_zero_flg = 'Y' ) OR ( ln_kake_par < 0 ) ) THEN
--
      ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
--
    END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Mod Star �{��#1410
    gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
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
  END prc_create_xml_data_s_k_t;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : XML�f�[�^�쐬 - ���[�f�[�^�o��
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf     OUT     VARCHAR2   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT     VARCHAR2   -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT     VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_break_init        VARCHAR2(5)           := '*****';
--
    lv_name_leaf         CONSTANT VARCHAR2(10) := '���[�t';
    lv_name_drink        CONSTANT VARCHAR2(10) := '�h�����N';
--
    -- ������p�萔
    lv_jan_name          CONSTANT VARCHAR2(3)  := 'JAN';   -- �P��
    lv_feb_name          CONSTANT VARCHAR2(3)  := 'FEB';   -- �Q��
    lv_mar_name          CONSTANT VARCHAR2(3)  := 'MAR';   -- �R��
    lv_apr_name          CONSTANT VARCHAR2(3)  := 'APR';   -- �S��
    lv_may_name          CONSTANT VARCHAR2(3)  := 'MAY';   -- �T��
    lv_jun_name          CONSTANT VARCHAR2(3)  := 'JUN';   -- �U��
    lv_jul_name          CONSTANT VARCHAR2(3)  := 'JUL';   -- �V��
    lv_aug_name          CONSTANT VARCHAR2(3)  := 'AUG';   -- �W��
    lv_sep_name          CONSTANT VARCHAR2(3)  := 'SEP';   -- �X��
    lv_oct_name          CONSTANT VARCHAR2(3)  := 'OCT';   -- �P�O��
    lv_nov_name          CONSTANT VARCHAR2(3)  := 'NOV';   -- �P�P��
    lv_dec_name          CONSTANT VARCHAR2(3)  := 'DEC';   -- �P�Q��
--
    -- XML�o�͔���p�萔
    lv_yes               CONSTANT VARCHAR2(1)  := 'Y';    -- XML�o�͍�
    lv_no                CONSTANT VARCHAR2(1)  := 'N';    -- XML�o�͖�
--
    -- �u���C�N�L�[���f�p�ϐ�
    lv_skbn_break        xxcmn_item_categories2_v.segment1%TYPE;
                                                   -- ���i�敪����p
    lv_ktn_break         VARCHAR2(10);             -- ���_���f�p
    lv_gun_break         VARCHAR2(10);             -- �Q�R�[�h���f�p
    lv_dtl_break         VARCHAR2(10);             -- �i�ڔ��f�p
    lv_sttl_break        VARCHAR2(10);             -- ���Q�v���f�p
    lv_lttl_break        VARCHAR2(10);             -- ��Q�v���f�p
--
    ln_chk_0             NUMBER;                   -- �O���Z���荀��
    ln_arari             NUMBER;                   -- �e���v�Z�p
    ln_kake_par          NUMBER(8,2);              -- �|�����荀��
--
    -- �e���ڏW�v�ϐ�
    ln_quant             NUMBER := 0;              -- �N�v�p ����
    ln_price             NUMBER := 0;              -- �N�v�p �i�ڒ艿
    ln_year_quant_sum    NUMBER := 0;              -- �N�v ����
    ln_year_amount_sum   NUMBER := 0;              -- �N�v ���z
    ln_year_to_am_sum    NUMBER := 0;              -- �N�v ���󍇌v
    ln_year_price_sum    NUMBER := 0;              -- �N�v �i�ڒ艿
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
    lv_param_name        VARCHAR2(100);            -- �^�O�o�͏����p�^�O��
    lv_param_label       VARCHAR2(100);            -- �^�O�o�͏����p���x��
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
--
    -- *** ���[�J���E��O���� ***
    no_data_expt         EXCEPTION;                -- �擾���R�[�h�O����
--
  BEGIN
--
    -- =====================================================
    -- �u���C�N�L�[������
    -- =====================================================
    lv_skbn_break  := lv_break_init;   -- ���i�敪����pBK
    lv_ktn_break   := lv_break_init;   -- ���_����pBK
    lv_gun_break   := lv_break_init;   -- �Q�R�[�h����pBK
    lv_dtl_break   := lv_break_init;   -- �i�ڃR�[�h����pBK
    lv_sttl_break  := lv_break_init;   -- ���Q�v����pBK
    lv_lttl_break  := lv_break_init;   -- ��Q�v����pBK
--
--  ==========================================================
--  -- ���͂o�w�o�͎�ʁx���u�S���_�v�̏ꍇ                 --
--  ==========================================================
    IF (gr_param.output_type = gv_name_all_ktn) THEN
      -- =====================================================
      -- (�S���_)�f�[�^���o - �̔��v�掞�n��\��񒊏o (C-1-1)
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
      -- �擾�f�[�^���O���̏ꍇ
      ELSIF (gr_sale_plan.COUNT = 0) THEN
        RAISE no_data_expt;
      END IF;
--
      -- =====================================================
      -- (�S���_)���ڃf�[�^���o�E�^�O�o�͏���
      -- =====================================================
      -- -----------------------------------------------------
      -- (�S���_)�f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (�S���_)���i�敪�J�n�k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_skbn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- =====================================================
      -- (�S���_)���ڃf�[�^���o�E�o�͏���
      -- =====================================================
      <<main_data_loop>>
      FOR i IN 1..gr_sale_plan.COUNT LOOP
        -- ====================================================
        --  (�S���_)���i�敪�u���C�N
        -- ====================================================
        -- ���i�敪���؂�ւ�����Ƃ�
        IF (gr_sale_plan(i).skbn <> lv_skbn_break) THEN
          -- ====================================================
          -- (�S���_) ���i�敪�I���f�^�O�o�͔���
          -- ====================================================
          -- �ŏ��̃��R�[�h�̎��͏o�͂���
          IF (lv_skbn_break <> lv_break_init) THEN
            ---------------------------------------------------------------
            -- (�S���_)�e�����o�f�[�^�����݂��Ȃ��ꍇ�A0�\���ɂ�XML�o��  --
            ---------------------------------------------------------------
            <<xml_out_0_loop>>
            FOR m IN 1..12 LOOP
              IF (gr_xml_out(m).out_fg = lv_no) THEN
                prc_create_xml_data_dtl_n
                  (
                    iv_label_name     => gr_xml_out(m).tag_name                      -- �o�̓^�O��
                   ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                   ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                   ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                  );
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
              END IF;
            END LOOP xml_out_0_loop;
--
            -- -----------------------------------------------------
            -- (�S���_)�N�v ���ʃf�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
            -- -----------------------------------------------------
            -- (�S���_)�N�v ���z�f�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
            -- -----------------------------------------------------
            -- (�S���_)�N�v �e�����f�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            ----------------------------------------------
            -- (�S���_)�e���v�Z (���z�|���󍇌v������)  --
            ----------------------------------------------
            ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
            -- �O���Z��𔻒�
            IF (ln_year_amount_sum <> gn_0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            gt_xml_data_table(gl_xml_idx).tag_value := 
                      ROUND((ln_arari / ln_year_amount_sum * 100),2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
            END IF;
--
            -- -----------------------------------------------------
            -- (�S���_)�N�v �|���f�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            --------------------------------------
            -- �O���Z���荀�ڂ֔���l��}��     --
            --------------------------------------
            ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
            -- �O���Z��𔻒�
            IF (ln_chk_0 <> gn_0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_kake_par := gn_0;
            END IF;
--
            -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
            IF ((ln_year_price_sum = 0)
              OR (ln_kake_par < 0)) THEN
              ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
            END IF;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
            -- �e�W�v���ڂփf�[�^�}��
            <<add_total_loop>>
            FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
              gr_add_total(r).year_quant     :=
                 gr_add_total(r).year_quant     + ln_year_quant_sum;        -- ����
              gr_add_total(r).year_amount    :=
                 gr_add_total(r).year_amount    + ln_year_amount_sum;       -- ���z
              gr_add_total(r).year_price     :=
                 gr_add_total(r).year_price     + ln_year_price_sum;        -- �i�ڒ艿
              gr_add_total(r).year_to_amount :=
                 gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- ���󍇌v
              gr_add_total(r).year_quant_t   :=
                 gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- ����(�v)
            END LOOP add_total_loop;
--
            -- -----------------------------------------------------
            --  (�S���_)�i�ڏI���f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  (�S���_)�i�ڏI���k�f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start
/*
            --------------------------------------------------------
            -- ���Q�v�f�[�^�o�� 
            --------------------------------------------------------
            prc_create_xml_data_st_lt
            (
               iv_label_name     => gv_name_st                     -- ���Q�v�p�^�O��
              ,iv_name           => gv_label_st                    -- ���Q�v�^�C�g��
              ,in_may_quant      => gr_add_total(1).may_quant      -- �T�� ����
              ,in_may_amount     => gr_add_total(1).may_amount     -- �T�� ���z
              ,in_may_price      => gr_add_total(1).may_price      -- �T�� �i�ڒ艿
              ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- �T�� ���󍇌v
              ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_may_s_cost     => gr_add_total(1).may_s_cost     -- �T�� �W������(�v�Z�p)
              ,in_may_calc       => gr_add_total(1).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
              ,in_may_minus_flg   => gr_add_total(1).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_may_ht_zero_flg => gr_add_total(1).may_ht_zero_flg -- �T�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jun_quant      => gr_add_total(1).jun_quant      -- �U�� ����
              ,in_jun_amount     => gr_add_total(1).jun_amount     -- �U�� ���z
              ,in_jun_price      => gr_add_total(1).jun_price      -- �U�� �i�ڒ艿
              ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- �U�� ���󍇌v
              ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jun_s_cost     => gr_add_total(1).jun_s_cost     -- �U�� �W������(�v�Z�p)
              ,in_jun_calc       => gr_add_total(1).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
              ,in_jun_minus_flg   => gr_add_total(1).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jun_ht_zero_flg => gr_add_total(1).jun_ht_zero_flg -- �U�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jul_quant      => gr_add_total(1).jul_quant      -- �V�� ����
              ,in_jul_amount     => gr_add_total(1).jul_amount     -- �V�� ���z
              ,in_jul_price      => gr_add_total(1).jul_price      -- �V�� �i�ڒ艿
              ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- �V�� ���󍇌v
              ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jul_s_cost     => gr_add_total(1).jul_s_cost     -- �V�� �W������(�v�Z�p)
              ,in_jul_calc       => gr_add_total(1).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
              ,in_jul_minus_flg   => gr_add_total(1).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jul_ht_zero_flg => gr_add_total(1).jul_ht_zero_flg -- �V�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_aug_quant      => gr_add_total(1).aug_quant      -- �W�� ����
              ,in_aug_amount     => gr_add_total(1).aug_amount     -- �W�� ���z
              ,in_aug_price      => gr_add_total(1).aug_price      -- �W�� �i�ڒ艿
              ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- �W�� ���󍇌v
              ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_aug_s_cost     => gr_add_total(1).aug_s_cost     -- �W�� �W������(�v�Z�p)
              ,in_aug_calc       => gr_add_total(1).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
              ,in_aug_minus_flg   => gr_add_total(1).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_aug_ht_zero_flg => gr_add_total(1).aug_ht_zero_flg -- �W�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_sep_quant      => gr_add_total(1).sep_quant      -- �X�� ����
              ,in_sep_amount     => gr_add_total(1).sep_amount     -- �X�� ���z
              ,in_sep_price      => gr_add_total(1).sep_price      -- �X�� �i�ڒ艿
              ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- �X�� ���󍇌v
              ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_sep_s_cost     => gr_add_total(1).sep_s_cost     -- �X�� �W������(�v�Z�p)
              ,in_sep_calc       => gr_add_total(1).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
              ,in_sep_minus_flg   => gr_add_total(1).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_sep_ht_zero_flg => gr_add_total(1).sep_ht_zero_flg -- �X�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_oct_quant      => gr_add_total(1).oct_quant      -- �P�O�� ����
              ,in_oct_amount     => gr_add_total(1).oct_amount     -- �P�O�� ���z
              ,in_oct_price      => gr_add_total(1).oct_price      -- �P�O�� �i�ڒ艿
              ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- �P�O�� ���󍇌v
              ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_oct_s_cost     => gr_add_total(1).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
              ,in_oct_calc       => gr_add_total(1).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
              ,in_oct_minus_flg   => gr_add_total(1).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_oct_ht_zero_flg => gr_add_total(1).oct_ht_zero_flg -- �P�O�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_nov_quant      => gr_add_total(1).nov_quant      -- �P�P�� ����
              ,in_nov_amount     => gr_add_total(1).nov_amount     -- �P�P�� ���z
              ,in_nov_price      => gr_add_total(1).nov_price      -- �P�P�� �i�ڒ艿
              ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- �P�P�� ���󍇌v
              ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_nov_s_cost     => gr_add_total(1).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
              ,in_nov_calc       => gr_add_total(1).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
              ,in_nov_minus_flg   => gr_add_total(1).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_nov_ht_zero_flg => gr_add_total(1).nov_ht_zero_flg -- �P�P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_dec_quant      => gr_add_total(1).dec_quant      -- �P�Q�� ����
              ,in_dec_amount     => gr_add_total(1).dec_amount     -- �P�Q�� ���z
              ,in_dec_price      => gr_add_total(1).dec_price      -- �P�Q�� �i�ڒ艿
              ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- �P�Q�� ���󍇌v
              ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_dec_s_cost     => gr_add_total(1).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
              ,in_dec_calc       => gr_add_total(1).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_dec_minus_flg   => gr_add_total(1).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_dec_ht_zero_flg => gr_add_total(1).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jan_quant      => gr_add_total(1).jan_quant      -- �P�� ����
              ,in_jan_amount     => gr_add_total(1).jan_amount     -- �P�� ���z
              ,in_jan_price      => gr_add_total(1).jan_price      -- �P�� �i�ڒ艿
              ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- �P�� ���󍇌v
              ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jan_s_cost     => gr_add_total(1).jan_s_cost     -- �P�� �W������(�v�Z�p)
              ,in_jan_calc       => gr_add_total(1).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
              ,in_jan_minus_flg   => gr_add_total(1).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jan_ht_zero_flg => gr_add_total(1).jan_ht_zero_flg -- �P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_feb_quant      => gr_add_total(1).feb_quant      -- �Q�� ����
              ,in_feb_amount     => gr_add_total(1).feb_amount     -- �Q�� ���z
              ,in_feb_price      => gr_add_total(1).feb_price      -- �Q�� �i�ڒ艿
              ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- �Q�� ���󍇌v
              ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_feb_s_cost     => gr_add_total(1).feb_s_cost     -- �Q�� �W������(�v�Z�p)
              ,in_feb_calc       => gr_add_total(1).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_feb_minus_flg   => gr_add_total(1).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_feb_ht_zero_flg => gr_add_total(1).feb_ht_zero_flg -- �Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_mar_quant      => gr_add_total(1).mar_quant      -- �R�� ����
              ,in_mar_amount     => gr_add_total(1).mar_amount     -- �R�� ���z
              ,in_mar_price      => gr_add_total(1).mar_price      -- �R�� �i�ڒ艿
              ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- �R�� ���󍇌v
              ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_mar_s_cost     => gr_add_total(1).mar_s_cost     -- �R�� �W������(�v�Z�p)
              ,in_mar_calc       => gr_add_total(1).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
              ,in_mar_minus_flg   => gr_add_total(1).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_mar_ht_zero_flg => gr_add_total(1).mar_ht_zero_flg -- �R�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_apr_quant      => gr_add_total(1).apr_quant      -- �S�� ����
              ,in_apr_amount     => gr_add_total(1).apr_amount     -- �S�� ���z
              ,in_apr_price      => gr_add_total(1).apr_price      -- �S�� �i�ڒ艿
              ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- �S�� ���󍇌v
              ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_apr_s_cost     => gr_add_total(1).apr_s_cost     -- �S�� �W������(�v�Z�p)
              ,in_apr_calc       => gr_add_total(1).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
              ,in_apr_minus_flg   => gr_add_total(1).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_apr_ht_zero_flg => gr_add_total(1).apr_ht_zero_flg -- �S�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_year_quant     => gr_add_total(1).year_quant     -- �N�v ����
              ,in_year_amount    => gr_add_total(1).year_amount    -- �N�v ���z
              ,in_year_price     => gr_add_total(1).year_price     -- �N�v �i�ڒ艿
              ,in_year_to_amount => gr_add_total(1).year_to_amount -- �N�v ���󍇌v
              ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_year_s_cost    => gr_add_total(1).year_s_cost    -- �N�v �W������(�v�Z�p)
              ,in_year_calc      => gr_add_total(1).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
              ,in_year_minus_flg   => gr_add_total(1).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_year_ht_zero_flg => gr_add_total(1).year_ht_zero_flg -- �N�v �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            --------------------------------------------------------
            -- ��Q�v�f�[�^�o�� 
            --------------------------------------------------------
            prc_create_xml_data_st_lt
            (
               iv_label_name     => gv_name_lt                     -- ��Q�v�p�^�O��
              ,iv_name           => gv_label_lt                    -- ��Q�v�^�C�g��
              ,in_may_quant      => gr_add_total(2).may_quant      -- �T�� ����
              ,in_may_amount     => gr_add_total(2).may_amount     -- �T�� ���z
              ,in_may_price      => gr_add_total(2).may_price      -- �T�� �i�ڒ艿
              ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- �T�� ���󍇌v
              ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_may_s_cost     => gr_add_total(2).may_s_cost     -- �T�� �W������(�v�Z�p)
              ,in_may_calc       => gr_add_total(2).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
              ,in_may_minus_flg   => gr_add_total(2).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_may_ht_zero_flg => gr_add_total(2).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jun_quant      => gr_add_total(2).jun_quant      -- �U�� ����
              ,in_jun_amount     => gr_add_total(2).jun_amount     -- �U�� ���z
              ,in_jun_price      => gr_add_total(2).jun_price      -- �U�� �i�ڒ艿
              ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- �U�� ���󍇌v
              ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jun_s_cost     => gr_add_total(2).jun_s_cost     -- �U�� �W������(�v�Z�p)
              ,in_jun_calc       => gr_add_total(2).jun_calc       -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jun_minus_flg   => gr_add_total(2).jun_minus_flg   -- �U�� �i�ڒ艿*����(�v)
              ,in_jun_ht_zero_flg => gr_add_total(2).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jul_quant      => gr_add_total(2).jul_quant      -- �V�� ����
              ,in_jul_amount     => gr_add_total(2).jul_amount     -- �V�� ���z
              ,in_jul_price      => gr_add_total(2).jul_price      -- �V�� �i�ڒ艿
              ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- �V�� ���󍇌v
              ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jul_s_cost     => gr_add_total(2).jul_s_cost     -- �V�� �W������(�v�Z�p)
              ,in_jul_calc       => gr_add_total(2).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
              ,in_jul_minus_flg   => gr_add_total(2).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jul_ht_zero_flg => gr_add_total(2).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_aug_quant      => gr_add_total(2).aug_quant      -- �W�� ����
              ,in_aug_amount     => gr_add_total(2).aug_amount     -- �W�� ���z
              ,in_aug_price      => gr_add_total(2).aug_price      -- �W�� �i�ڒ艿
              ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- �W�� ���󍇌v
              ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_aug_s_cost     => gr_add_total(2).aug_s_cost     -- �W�� �W������(�v�Z�p)
              ,in_aug_calc       => gr_add_total(2).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
              ,in_aug_minus_flg   => gr_add_total(2).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_aug_ht_zero_flg => gr_add_total(2).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_sep_quant      => gr_add_total(2).sep_quant      -- �X�� ����
              ,in_sep_amount     => gr_add_total(2).sep_amount     -- �X�� ���z
              ,in_sep_price      => gr_add_total(2).sep_price      -- �X�� �i�ڒ艿
              ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- �X�� ���󍇌v
              ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_sep_s_cost     => gr_add_total(2).sep_s_cost     -- �X�� �W������(�v�Z�p)
              ,in_sep_calc       => gr_add_total(2).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
              ,in_sep_minus_flg   => gr_add_total(2).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_sep_ht_zero_flg => gr_add_total(2).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_oct_quant      => gr_add_total(2).oct_quant      -- �P�O�� ����
              ,in_oct_amount     => gr_add_total(2).oct_amount     -- �P�O�� ���z
              ,in_oct_price      => gr_add_total(2).oct_price      -- �P�O�� �i�ڒ艿
              ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- �P�O�� ���󍇌v
              ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_oct_s_cost     => gr_add_total(2).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
              ,in_oct_calc       => gr_add_total(2).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
              ,in_oct_minus_flg   => gr_add_total(2).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_oct_ht_zero_flg => gr_add_total(2).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_nov_quant      => gr_add_total(2).nov_quant      -- �P�P�� ����
              ,in_nov_amount     => gr_add_total(2).nov_amount     -- �P�P�� ���z
              ,in_nov_price      => gr_add_total(2).nov_price      -- �P�P�� �i�ڒ艿
              ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- �P�P�� ���󍇌v
              ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_nov_s_cost     => gr_add_total(2).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
              ,in_nov_calc       => gr_add_total(2).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
              ,in_nov_minus_flg   => gr_add_total(2).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_nov_ht_zero_flg => gr_add_total(2).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_dec_quant      => gr_add_total(2).dec_quant      -- �P�Q�� ����
              ,in_dec_amount     => gr_add_total(2).dec_amount     -- �P�Q�� ���z
              ,in_dec_price      => gr_add_total(2).dec_price      -- �P�Q�� �i�ڒ艿
              ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- �P�Q�� ���󍇌v
              ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_dec_s_cost     => gr_add_total(2).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
              ,in_dec_calc       => gr_add_total(2).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_dec_minus_flg   => gr_add_total(2).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_dec_ht_zero_flg => gr_add_total(2).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jan_quant      => gr_add_total(2).jan_quant      -- �P�� ����
              ,in_jan_amount     => gr_add_total(2).jan_amount     -- �P�� ���z
              ,in_jan_price      => gr_add_total(2).jan_price      -- �P�� �i�ڒ艿
              ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- �P�� ���󍇌v
              ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jan_s_cost     => gr_add_total(2).jan_s_cost     -- �P�� �W������(�v�Z�p)
              ,in_jan_calc       => gr_add_total(2).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
              ,in_jan_minus_flg   => gr_add_total(2).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jan_ht_zero_flg => gr_add_total(2).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_feb_quant      => gr_add_total(2).feb_quant      -- �Q�� ����
              ,in_feb_amount     => gr_add_total(2).feb_amount     -- �Q�� ���z
              ,in_feb_price      => gr_add_total(2).feb_price      -- �Q�� �i�ڒ艿
              ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- �Q�� ���󍇌v
              ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_feb_s_cost     => gr_add_total(2).feb_s_cost     -- �Q�� �W������(�v�Z�p)
              ,in_feb_calc       => gr_add_total(2).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_feb_minus_flg   => gr_add_total(2).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_feb_ht_zero_flg => gr_add_total(2).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_mar_quant      => gr_add_total(2).mar_quant      -- �R�� ����
              ,in_mar_amount     => gr_add_total(2).mar_amount     -- �R�� ���z
              ,in_mar_price      => gr_add_total(2).mar_price      -- �R�� �i�ڒ艿
              ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- �R�� ���󍇌v
              ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_mar_s_cost     => gr_add_total(2).mar_s_cost     -- �R�� �W������(�v�Z�p)
              ,in_mar_calc       => gr_add_total(2).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
              ,in_mar_minus_flg   => gr_add_total(2).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_mar_ht_zero_flg => gr_add_total(2).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_apr_quant      => gr_add_total(2).apr_quant      -- �S�� ����
              ,in_apr_amount     => gr_add_total(2).apr_amount     -- �S�� ���z
              ,in_apr_price      => gr_add_total(2).apr_price      -- �S�� �i�ڒ艿
              ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- �S�� ���󍇌v
              ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_apr_s_cost     => gr_add_total(2).apr_s_cost     -- �S�� �W������(�v�Z�p)
              ,in_apr_calc       => gr_add_total(2).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
              ,in_apr_minus_flg   => gr_add_total(2).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_apr_ht_zero_flg => gr_add_total(2).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_year_quant     => gr_add_total(2).year_quant     -- �N�v ����
              ,in_year_amount    => gr_add_total(2).year_amount    -- �N�v ���z
              ,in_year_price     => gr_add_total(2).year_price     -- �N�v �i�ڒ艿
              ,in_year_to_amount => gr_add_total(2).year_to_amount -- �N�v ���󍇌v
              ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_year_s_cost    => gr_add_total(2).year_s_cost    -- �N�v �W������(�v�Z�p)
              ,in_year_calc      => gr_add_total(2).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
              ,in_year_minus_flg   => gr_add_total(2).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_year_ht_zero_flg => gr_add_total(2).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
*/
            --------------------------------------------------------
            -- (�S���_)(1)���Q�v/(2)��Q�v�f�[�^�o�� 
            --------------------------------------------------------
            <<gun_loop>>
            FOR n IN 1..2 LOOP        -- ���Q�v/��Q�v
--
              -- ���Q�v�̏ꍇ
              IF ( n = 1) THEN
                lv_param_name  := gv_name_st;
                lv_param_label := gv_label_st;
              -- ��Q�v�̏ꍇ
              ELSE
                lv_param_name  := gv_name_lt;
                lv_param_label := gv_label_lt;
              END IF;
--
              prc_create_xml_data_st_lt
              (
                 iv_label_name      => lv_param_name                   -- ��Q�v�p�^�O��
                ,iv_name            => lv_param_label                  -- ��Q�v�^�C�g��
                ,in_may_quant       => gr_add_total(n).may_quant       -- �T�� ����
                ,in_may_amount      => gr_add_total(n).may_amount      -- �T�� ���z
                ,in_may_price       => gr_add_total(n).may_price       -- �T�� �i�ڒ艿
                ,in_may_to_amount   => gr_add_total(n).may_to_amount   -- �T�� ���󍇌v
                ,in_may_quant_t     => gr_add_total(n).may_quant_t     -- �T�� ����(�v�Z�p)
                ,in_may_s_cost      => gr_add_total(n).may_s_cost      -- �T�� �W������(�v�Z�p)
                ,in_may_calc        => gr_add_total(n).may_calc        -- �T�� �i�ڒ艿*����(�v�Z�p)
                ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
                ,in_jun_quant       => gr_add_total(n).jun_quant       -- �U�� ����
                ,in_jun_amount      => gr_add_total(n).jun_amount      -- �U�� ���z
                ,in_jun_price       => gr_add_total(n).jun_price       -- �U�� �i�ڒ艿
                ,in_jun_to_amount   => gr_add_total(n).jun_to_amount   -- �U�� ���󍇌v
                ,in_jun_quant_t     => gr_add_total(n).jun_quant_t     -- �U�� ����(�v�Z�p)
                ,in_jun_s_cost      => gr_add_total(n).jun_s_cost      -- �U�� �W������(�v�Z�p)
                ,in_jun_calc        => gr_add_total(n).jun_calc        -- �U�� �i�ڒ艿*����(�v�Z�p)
                ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
                ,in_jul_quant       => gr_add_total(n).jul_quant       -- �V�� ����
                ,in_jul_amount      => gr_add_total(n).jul_amount      -- �V�� ���z
                ,in_jul_price       => gr_add_total(n).jul_price       -- �V�� �i�ڒ艿
                ,in_jul_to_amount   => gr_add_total(n).jul_to_amount   -- �V�� ���󍇌v
                ,in_jul_quant_t     => gr_add_total(n).jul_quant_t     -- �V�� ����(�v�Z�p)
                ,in_jul_s_cost      => gr_add_total(n).jul_s_cost      -- �V�� �W������(�v�Z�p)
                ,in_jul_calc        => gr_add_total(n).jul_calc        -- �V�� �i�ڒ艿*����(�v�Z�p)
                ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
                ,in_aug_quant       => gr_add_total(n).aug_quant       -- �W�� ����
                ,in_aug_amount      => gr_add_total(n).aug_amount      -- �W�� ���z
                ,in_aug_price       => gr_add_total(n).aug_price       -- �W�� �i�ڒ艿
                ,in_aug_to_amount   => gr_add_total(n).aug_to_amount   -- �W�� ���󍇌v
                ,in_aug_quant_t     => gr_add_total(n).aug_quant_t     -- �W�� ����(�v�Z�p)
                ,in_aug_s_cost      => gr_add_total(n).aug_s_cost      -- �W�� �W������(�v�Z�p)
                ,in_aug_calc        => gr_add_total(n).aug_calc        -- �W�� �i�ڒ艿*����(�v�Z�p)
                ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
                ,in_sep_quant       => gr_add_total(n).sep_quant       -- �X�� ����
                ,in_sep_amount      => gr_add_total(n).sep_amount      -- �X�� ���z
                ,in_sep_price       => gr_add_total(n).sep_price       -- �X�� �i�ڒ艿
                ,in_sep_to_amount   => gr_add_total(n).sep_to_amount   -- �X�� ���󍇌v
                ,in_sep_quant_t     => gr_add_total(n).sep_quant_t     -- �X�� ����(�v�Z�p)
                ,in_sep_s_cost      => gr_add_total(n).sep_s_cost      -- �X�� �W������(�v�Z�p)
                ,in_sep_calc        => gr_add_total(n).sep_calc        -- �X�� �i�ڒ艿*����(�v�Z�p)
                ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
                ,in_oct_quant       => gr_add_total(n).oct_quant       -- �P�O�� ����
                ,in_oct_amount      => gr_add_total(n).oct_amount      -- �P�O�� ���z
                ,in_oct_price       => gr_add_total(n).oct_price       -- �P�O�� �i�ڒ艿
                ,in_oct_to_amount   => gr_add_total(n).oct_to_amount   -- �P�O�� ���󍇌v
                ,in_oct_quant_t     => gr_add_total(n).oct_quant_t     -- �P�O�� ����(�v�Z�p)
                ,in_oct_s_cost      => gr_add_total(n).oct_s_cost      -- �P�O�� �W������(�v�Z�p)
                ,in_oct_calc        => gr_add_total(n).oct_calc        -- �P�O�� �i�ڒ艿*����(�v�Z�p)
                ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
                ,in_nov_quant       => gr_add_total(n).nov_quant       -- �P�P�� ����
                ,in_nov_amount      => gr_add_total(n).nov_amount      -- �P�P�� ���z
                ,in_nov_price       => gr_add_total(n).nov_price       -- �P�P�� �i�ڒ艿
                ,in_nov_to_amount   => gr_add_total(n).nov_to_amount   -- �P�P�� ���󍇌v
                ,in_nov_quant_t     => gr_add_total(n).nov_quant_t     -- �P�P�� ����(�v�Z�p)
                ,in_nov_s_cost      => gr_add_total(n).nov_s_cost      -- �P�P�� �W������(�v�Z�p)
                ,in_nov_calc        => gr_add_total(n).nov_calc        -- �P�P�� �i�ڒ艿*����(�v�Z�p)
                ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
                ,in_dec_quant       => gr_add_total(n).dec_quant       -- �P�Q�� ����
                ,in_dec_amount      => gr_add_total(n).dec_amount      -- �P�Q�� ���z
                ,in_dec_price       => gr_add_total(n).dec_price       -- �P�Q�� �i�ڒ艿
                ,in_dec_to_amount   => gr_add_total(n).dec_to_amount   -- �P�Q�� ���󍇌v
                ,in_dec_quant_t     => gr_add_total(n).dec_quant_t     -- �P�Q�� ����(�v�Z�p)
                ,in_dec_s_cost      => gr_add_total(n).dec_s_cost      -- �P�Q�� �W������(�v�Z�p)
                ,in_dec_calc        => gr_add_total(n).dec_calc        -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
                ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
                ,in_jan_quant       => gr_add_total(n).jan_quant       -- �P�� ����
                ,in_jan_amount      => gr_add_total(n).jan_amount      -- �P�� ���z
                ,in_jan_price       => gr_add_total(n).jan_price       -- �P�� �i�ڒ艿
                ,in_jan_to_amount   => gr_add_total(n).jan_to_amount   -- �P�� ���󍇌v
                ,in_jan_quant_t     => gr_add_total(n).jan_quant_t     -- �P�� ����(�v�Z�p)
                ,in_jan_s_cost      => gr_add_total(n).jan_s_cost      -- �P�� �W������(�v�Z�p)
                ,in_jan_calc        => gr_add_total(n).jan_calc        -- �P�� �i�ڒ艿*����(�v�Z�p)
                ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
                ,in_feb_quant       => gr_add_total(n).feb_quant       -- �Q�� ����
                ,in_feb_amount      => gr_add_total(n).feb_amount      -- �Q�� ���z
                ,in_feb_price       => gr_add_total(n).feb_price       -- �Q�� �i�ڒ艿
                ,in_feb_to_amount   => gr_add_total(n).feb_to_amount   -- �Q�� ���󍇌v
                ,in_feb_quant_t     => gr_add_total(n).feb_quant_t     -- �Q�� ����(�v�Z�p)
                ,in_feb_s_cost      => gr_add_total(n).feb_s_cost      -- �Q�� �W������(�v�Z�p)
                ,in_feb_calc        => gr_add_total(n).feb_calc        -- �Q�� �i�ڒ艿*����(�v�Z�p)
                ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
                ,in_mar_quant       => gr_add_total(n).mar_quant       -- �R�� ����
                ,in_mar_amount      => gr_add_total(n).mar_amount      -- �R�� ���z
                ,in_mar_price       => gr_add_total(n).mar_price       -- �R�� �i�ڒ艿
                ,in_mar_to_amount   => gr_add_total(n).mar_to_amount   -- �R�� ���󍇌v
                ,in_mar_quant_t     => gr_add_total(n).mar_quant_t     -- �R�� ����(�v�Z�p)
                ,in_mar_s_cost      => gr_add_total(n).mar_s_cost      -- �R�� �W������(�v�Z�p)
                ,in_mar_calc        => gr_add_total(n).mar_calc        -- �R�� �i�ڒ艿*����(�v�Z�p)
                ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
                ,in_apr_quant       => gr_add_total(n).apr_quant       -- �S�� ����
                ,in_apr_amount      => gr_add_total(n).apr_amount      -- �S�� ���z
                ,in_apr_price       => gr_add_total(n).apr_price       -- �S�� �i�ڒ艿
                ,in_apr_to_amount   => gr_add_total(n).apr_to_amount   -- �S�� ���󍇌v
                ,in_apr_quant_t     => gr_add_total(n).apr_quant_t     -- �S�� ����(�v�Z�p)
                ,in_apr_s_cost      => gr_add_total(n).apr_s_cost      -- �S�� �W������(�v�Z�p)
                ,in_apr_calc        => gr_add_total(n).apr_calc        -- �S�� �i�ڒ艿*����(�v�Z�p)
                ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
                ,in_year_quant      => gr_add_total(n).year_quant        -- �N�v ����
                ,in_year_amount     => gr_add_total(n).year_amount       -- �N�v ���z
                ,in_year_price      => gr_add_total(n).year_price        -- �N�v �i�ڒ艿
                ,in_year_to_amount  => gr_add_total(n).year_to_amount    -- �N�v ���󍇌v
                ,in_year_quant_t    => gr_add_total(n).year_quant_t      -- �N�v ����(�v�Z�p)
                ,in_year_s_cost     => gr_add_total(n).year_s_cost       -- �N�v �W������(�v�Z�p)
                ,in_year_calc       => gr_add_total(n).year_calc         -- �N�v �i�ڒ艿*����(�v�Z�p)
                ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
                ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
            END LOOP gun_loop;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
--
            -- -----------------------------------------------------
            --  (�S���_)�Q�R�[�h�I���f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  (�S���_)�Q�R�[�h�I���k�f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start
/*
            --------------------------------------------------------
            -- ���_�v�f�[�^�^�O�o�� 
            --------------------------------------------------------
            prc_create_xml_data_s_k_t
            (
              iv_label_name     => gv_name_ktn                    -- ���_�v�p�^�O��
              ,in_may_quant      => gr_add_total(3).may_quant      -- �T�� ����
              ,in_may_amount     => gr_add_total(3).may_amount     -- �T�� ���z
              ,in_may_price      => gr_add_total(3).may_price      -- �T�� �i�ڒ艿
              ,in_may_to_amount  => gr_add_total(3).may_to_amount  -- �T�� ���󍇌v
              ,in_may_quant_t    => gr_add_total(3).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_may_s_cost     => gr_add_total(3).may_s_cost     -- �T�� �W������(�v�Z�p)
              ,in_may_calc       => gr_add_total(3).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
              ,in_may_minus_flg   => gr_add_total(3).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_may_ht_zero_flg => gr_add_total(3).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jun_quant      => gr_add_total(3).jun_quant      -- �U�� ����
              ,in_jun_amount     => gr_add_total(3).jun_amount     -- �U�� ���z
              ,in_jun_price      => gr_add_total(3).jun_price      -- �U�� �i�ڒ艿
              ,in_jun_to_amount  => gr_add_total(3).jun_to_amount  -- �U�� ���󍇌v
              ,in_jun_quant_t    => gr_add_total(3).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jun_s_cost     => gr_add_total(3).jun_s_cost     -- �U�� �W������(�v�Z�p)
              ,in_jun_calc       => gr_add_total(3).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
              ,in_jun_minus_flg   => gr_add_total(3).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jun_ht_zero_flg => gr_add_total(3).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jul_quant      => gr_add_total(3).jul_quant      -- �V�� ����
              ,in_jul_amount     => gr_add_total(3).jul_amount     -- �V�� ���z
              ,in_jul_price      => gr_add_total(3).jul_price      -- �V�� �i�ڒ艿
              ,in_jul_to_amount  => gr_add_total(3).jul_to_amount  -- �V�� ���󍇌v
              ,in_jul_quant_t    => gr_add_total(3).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jul_s_cost     => gr_add_total(3).jul_s_cost     -- �V�� �W������(�v�Z�p)
              ,in_jul_calc       => gr_add_total(3).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
              ,in_jul_minus_flg   => gr_add_total(3).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jul_ht_zero_flg => gr_add_total(3).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_aug_quant      => gr_add_total(3).aug_quant      -- �W�� ����
              ,in_aug_amount     => gr_add_total(3).aug_amount     -- �W�� ���z
              ,in_aug_price      => gr_add_total(3).aug_price      -- �W�� �i�ڒ艿
              ,in_aug_to_amount  => gr_add_total(3).aug_to_amount  -- �W�� ���󍇌v
              ,in_aug_quant_t    => gr_add_total(3).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_aug_s_cost     => gr_add_total(3).aug_s_cost     -- �W�� �W������(�v�Z�p)
              ,in_aug_calc       => gr_add_total(3).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
              ,in_aug_minus_flg   => gr_add_total(3).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_aug_ht_zero_flg => gr_add_total(3).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_sep_quant      => gr_add_total(3).sep_quant      -- �X�� ����
              ,in_sep_amount     => gr_add_total(3).sep_amount     -- �X�� ���z
              ,in_sep_price      => gr_add_total(3).sep_price      -- �X�� �i�ڒ艿
              ,in_sep_to_amount  => gr_add_total(3).sep_to_amount  -- �X�� ���󍇌v
              ,in_sep_quant_t    => gr_add_total(3).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_sep_s_cost     => gr_add_total(3).sep_s_cost     -- �X�� �W������(�v�Z�p)
              ,in_sep_calc       => gr_add_total(3).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
              ,in_sep_minus_flg   => gr_add_total(3).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_sep_ht_zero_flg => gr_add_total(3).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_oct_quant      => gr_add_total(3).oct_quant      -- �P�O�� ����
              ,in_oct_amount     => gr_add_total(3).oct_amount     -- �P�O�� ���z
              ,in_oct_price      => gr_add_total(3).oct_price      -- �P�O�� �i�ڒ艿
              ,in_oct_to_amount  => gr_add_total(3).oct_to_amount  -- �P�O�� ���󍇌v
              ,in_oct_quant_t    => gr_add_total(3).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_oct_s_cost     => gr_add_total(3).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
              ,in_oct_calc       => gr_add_total(3).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
              ,in_oct_minus_flg   => gr_add_total(3).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_oct_ht_zero_flg => gr_add_total(3).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_nov_quant      => gr_add_total(3).nov_quant      -- �P�P�� ����
              ,in_nov_amount     => gr_add_total(3).nov_amount     -- �P�P�� ���z
              ,in_nov_price      => gr_add_total(3).nov_price      -- �P�P�� �i�ڒ艿
              ,in_nov_to_amount  => gr_add_total(3).nov_to_amount  -- �P�P�� ���󍇌v
              ,in_nov_quant_t    => gr_add_total(3).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_nov_s_cost     => gr_add_total(3).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
              ,in_nov_calc       => gr_add_total(3).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
              ,in_nov_minus_flg   => gr_add_total(3).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_nov_ht_zero_flg => gr_add_total(3).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_dec_quant      => gr_add_total(3).dec_quant      -- �P�Q�� ����
              ,in_dec_amount     => gr_add_total(3).dec_amount     -- �P�Q�� ���z
              ,in_dec_price      => gr_add_total(3).dec_price      -- �P�Q�� �i�ڒ艿
              ,in_dec_to_amount  => gr_add_total(3).dec_to_amount  -- �P�Q�� ���󍇌v
              ,in_dec_quant_t    => gr_add_total(3).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_dec_s_cost     => gr_add_total(3).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
              ,in_dec_calc       => gr_add_total(3).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_dec_minus_flg   => gr_add_total(3).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_dec_ht_zero_flg => gr_add_total(3).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jan_quant      => gr_add_total(3).jan_quant      -- �P�� ����
              ,in_jan_amount     => gr_add_total(3).jan_amount     -- �P�� ���z
              ,in_jan_price      => gr_add_total(3).jan_price      -- �P�� �i�ڒ艿
              ,in_jan_to_amount  => gr_add_total(3).jan_to_amount  -- �P�� ���󍇌v
              ,in_jan_quant_t    => gr_add_total(3).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jan_s_cost     => gr_add_total(3).jan_s_cost     -- �P�� �W������(�v�Z�p)
              ,in_jan_calc       => gr_add_total(3).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
              ,in_jan_minus_flg   => gr_add_total(3).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jan_ht_zero_flg => gr_add_total(3).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_feb_quant      => gr_add_total(3).feb_quant      -- �Q�� ����
              ,in_feb_amount     => gr_add_total(3).feb_amount     -- �Q�� ���z
              ,in_feb_price      => gr_add_total(3).feb_price      -- �Q�� �i�ڒ艿
              ,in_feb_to_amount  => gr_add_total(3).feb_to_amount  -- �Q�� ���󍇌v
              ,in_feb_quant_t    => gr_add_total(3).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_feb_s_cost     => gr_add_total(3).feb_s_cost     -- �Q�� �W������(�v�Z�p)
              ,in_feb_calc       => gr_add_total(3).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_feb_minus_flg   => gr_add_total(3).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_feb_ht_zero_flg => gr_add_total(3).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_mar_quant      => gr_add_total(3).mar_quant      -- �R�� ����
              ,in_mar_amount     => gr_add_total(3).mar_amount     -- �R�� ���z
              ,in_mar_price      => gr_add_total(3).mar_price      -- �R�� �i�ڒ艿
              ,in_mar_to_amount  => gr_add_total(3).mar_to_amount  -- �R�� ���󍇌v
              ,in_mar_quant_t    => gr_add_total(3).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_mar_s_cost     => gr_add_total(3).mar_s_cost     -- �R�� �W������(�v�Z�p)
              ,in_mar_calc       => gr_add_total(3).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
              ,in_mar_minus_flg   => gr_add_total(3).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_mar_ht_zero_flg => gr_add_total(3).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_apr_quant      => gr_add_total(3).apr_quant      -- �S�� ����
              ,in_apr_amount     => gr_add_total(3).apr_amount     -- �S�� ���z
              ,in_apr_price      => gr_add_total(3).apr_price      -- �S�� �i�ڒ艿
              ,in_apr_to_amount  => gr_add_total(3).apr_to_amount  -- �S�� ���󍇌v
              ,in_apr_quant_t    => gr_add_total(3).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_apr_s_cost     => gr_add_total(3).apr_s_cost     -- �S�� �W������(�v�Z�p)
              ,in_apr_calc       => gr_add_total(3).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
              ,in_apr_minus_flg   => gr_add_total(3).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_apr_ht_zero_flg => gr_add_total(3).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_year_quant     => gr_add_total(3).year_quant     -- �N�v ����
              ,in_year_amount    => gr_add_total(3).year_amount    -- �N�v ���z
              ,in_year_price     => gr_add_total(3).year_price     -- �N�v �i�ڒ艿
              ,in_year_to_amount => gr_add_total(3).year_to_amount -- �N�v ���󍇌v
              ,in_year_quant_t   => gr_add_total(3).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_year_s_cost    => gr_add_total(3).year_s_cost    -- �N�v �W������(�v�Z�p)
              ,in_year_calc      => gr_add_total(3).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
              ,in_year_minus_flg   => gr_add_total(3).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_year_ht_zero_flg => gr_add_total(3).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- -----------------------------------------------------
            --  ���_�I���f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  ���_�I���k�f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            --------------------------------------------------------
            -- ���i�敪�v�f�[�^�^�O�o�� 
            --------------------------------------------------------
            prc_create_xml_data_s_k_t
            (
              iv_label_name     => gv_name_skbn                   -- ���i�敪�v�p�^�O��
              ,in_may_quant      => gr_add_total(4).may_quant      -- �T�� ����
              ,in_may_amount     => gr_add_total(4).may_amount     -- �T�� ���z
              ,in_may_price      => gr_add_total(4).may_price      -- �T�� �i�ڒ艿
              ,in_may_to_amount  => gr_add_total(4).may_to_amount  -- �T�� ���󍇌v
              ,in_may_quant_t    => gr_add_total(4).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_may_s_cost     => gr_add_total(4).may_s_cost     -- �T�� �W������(�v�Z�p)
              ,in_may_calc       => gr_add_total(4).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
              ,in_may_minus_flg   => gr_add_total(4).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_may_ht_zero_flg => gr_add_total(4).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jun_quant      => gr_add_total(4).jun_quant      -- �U�� ����
              ,in_jun_amount     => gr_add_total(4).jun_amount     -- �U�� ���z
              ,in_jun_price      => gr_add_total(4).jun_price      -- �U�� �i�ڒ艿
              ,in_jun_to_amount  => gr_add_total(4).jun_to_amount  -- �U�� ���󍇌v
              ,in_jun_quant_t    => gr_add_total(4).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jun_s_cost     => gr_add_total(4).jun_s_cost     -- �U�� �W������(�v�Z�p)
              ,in_jun_calc       => gr_add_total(4).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
              ,in_jun_minus_flg   => gr_add_total(4).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jun_ht_zero_flg => gr_add_total(4).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jul_quant      => gr_add_total(4).jul_quant      -- �V�� ����
              ,in_jul_amount     => gr_add_total(4).jul_amount     -- �V�� ���z
              ,in_jul_price      => gr_add_total(4).jul_price      -- �V�� �i�ڒ艿
              ,in_jul_to_amount  => gr_add_total(4).jul_to_amount  -- �V�� ���󍇌v
              ,in_jul_quant_t    => gr_add_total(4).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jul_s_cost     => gr_add_total(4).jul_s_cost     -- �V�� �W������(�v�Z�p)
              ,in_jul_calc       => gr_add_total(4).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
              ,in_jul_minus_flg   => gr_add_total(4).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jul_ht_zero_flg => gr_add_total(4).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_aug_quant      => gr_add_total(4).aug_quant      -- �W�� ����
              ,in_aug_amount     => gr_add_total(4).aug_amount     -- �W�� ���z
              ,in_aug_price      => gr_add_total(4).aug_price      -- �W�� �i�ڒ艿
              ,in_aug_to_amount  => gr_add_total(4).aug_to_amount  -- �W�� ���󍇌v
              ,in_aug_quant_t    => gr_add_total(4).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_aug_s_cost     => gr_add_total(4).aug_s_cost     -- �W�� �W������(�v�Z�p)
              ,in_aug_calc       => gr_add_total(4).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
              ,in_aug_minus_flg   => gr_add_total(4).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_aug_ht_zero_flg => gr_add_total(4).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_sep_quant      => gr_add_total(4).sep_quant      -- �X�� ����
              ,in_sep_amount     => gr_add_total(4).sep_amount     -- �X�� ���z
              ,in_sep_price      => gr_add_total(4).sep_price      -- �X�� �i�ڒ艿
              ,in_sep_to_amount  => gr_add_total(4).sep_to_amount  -- �X�� ���󍇌v
              ,in_sep_quant_t    => gr_add_total(4).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_sep_s_cost     => gr_add_total(4).sep_s_cost     -- �X�� �W������(�v�Z�p)
              ,in_sep_calc       => gr_add_total(4).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
              ,in_sep_minus_flg   => gr_add_total(4).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_sep_ht_zero_flg => gr_add_total(4).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_oct_quant      => gr_add_total(4).oct_quant      -- �P�O�� ����
              ,in_oct_amount     => gr_add_total(4).oct_amount     -- �P�O�� ���z
              ,in_oct_price      => gr_add_total(4).oct_price      -- �P�O�� �i�ڒ艿
              ,in_oct_to_amount  => gr_add_total(4).oct_to_amount  -- �P�O�� ���󍇌v
              ,in_oct_quant_t    => gr_add_total(4).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_oct_s_cost     => gr_add_total(4).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
              ,in_oct_calc       => gr_add_total(4).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
              ,in_oct_minus_flg   => gr_add_total(4).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_oct_ht_zero_flg => gr_add_total(4).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_nov_quant      => gr_add_total(4).nov_quant      -- �P�P�� ����
              ,in_nov_amount     => gr_add_total(4).nov_amount     -- �P�P�� ���z
              ,in_nov_price      => gr_add_total(4).nov_price      -- �P�P�� �i�ڒ艿
              ,in_nov_to_amount  => gr_add_total(4).nov_to_amount  -- �P�P�� ���󍇌v
              ,in_nov_quant_t    => gr_add_total(4).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_nov_s_cost     => gr_add_total(4).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
              ,in_nov_calc       => gr_add_total(4).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
              ,in_nov_minus_flg   => gr_add_total(4).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_nov_ht_zero_flg => gr_add_total(4).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_dec_quant      => gr_add_total(4).dec_quant      -- �P�Q�� ����
              ,in_dec_amount     => gr_add_total(4).dec_amount     -- �P�Q�� ���z
              ,in_dec_price      => gr_add_total(4).dec_price      -- �P�Q�� �i�ڒ艿
              ,in_dec_to_amount  => gr_add_total(4).dec_to_amount  -- �P�Q�� ���󍇌v
              ,in_dec_quant_t    => gr_add_total(4).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_dec_s_cost     => gr_add_total(4).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
              ,in_dec_calc       => gr_add_total(4).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_dec_minus_flg   => gr_add_total(4).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_dec_ht_zero_flg => gr_add_total(4).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jan_quant      => gr_add_total(4).jan_quant      -- �P�� ����
              ,in_jan_amount     => gr_add_total(4).jan_amount     -- �P�� ���z
              ,in_jan_price      => gr_add_total(4).jan_price      -- �P�� �i�ڒ艿
              ,in_jan_to_amount  => gr_add_total(4).jan_to_amount  -- �P�� ���󍇌v
              ,in_jan_quant_t    => gr_add_total(4).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jan_s_cost     => gr_add_total(4).jan_s_cost     -- �P�� �W������(�v�Z�p)
              ,in_jan_calc       => gr_add_total(4).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
              ,in_jan_minus_flg   => gr_add_total(4).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jan_ht_zero_flg => gr_add_total(4).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_feb_quant      => gr_add_total(4).feb_quant      -- �Q�� ����
              ,in_feb_amount     => gr_add_total(4).feb_amount     -- �Q�� ���z
              ,in_feb_price      => gr_add_total(4).feb_price      -- �Q�� �i�ڒ艿
              ,in_feb_to_amount  => gr_add_total(4).feb_to_amount  -- �Q�� ���󍇌v
              ,in_feb_quant_t    => gr_add_total(4).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_feb_s_cost     => gr_add_total(4).feb_s_cost     -- �Q�� �W������(�v�Z�p)
              ,in_feb_calc       => gr_add_total(4).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_feb_minus_flg   => gr_add_total(4).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_feb_ht_zero_flg => gr_add_total(4).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_mar_quant      => gr_add_total(4).mar_quant      -- �R�� ����
              ,in_mar_amount     => gr_add_total(4).mar_amount     -- �R�� ���z
              ,in_mar_price      => gr_add_total(4).mar_price      -- �R�� �i�ڒ艿
              ,in_mar_to_amount  => gr_add_total(4).mar_to_amount  -- �R�� ���󍇌v
              ,in_mar_quant_t    => gr_add_total(4).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_mar_s_cost     => gr_add_total(4).mar_s_cost     -- �R�� �W������(�v�Z�p)
              ,in_mar_calc       => gr_add_total(4).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
              ,in_mar_minus_flg   => gr_add_total(4).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_mar_ht_zero_flg => gr_add_total(4).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_apr_quant      => gr_add_total(4).apr_quant      -- �S�� ����
              ,in_apr_amount     => gr_add_total(4).apr_amount     -- �S�� ���z
              ,in_apr_price      => gr_add_total(4).apr_price      -- �S�� �i�ڒ艿
              ,in_apr_to_amount  => gr_add_total(4).apr_to_amount  -- �S�� ���󍇌v
              ,in_apr_quant_t    => gr_add_total(4).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_apr_s_cost     => gr_add_total(4).apr_s_cost     -- �S�� �W������(�v�Z�p)
              ,in_apr_calc       => gr_add_total(4).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
              ,in_apr_minus_flg   => gr_add_total(4).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_apr_ht_zero_flg => gr_add_total(4).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_year_quant     => gr_add_total(4).year_quant     -- �N�v ����
              ,in_year_amount    => gr_add_total(4).year_amount    -- �N�v ���z
              ,in_year_price     => gr_add_total(4).year_price     -- �N�v �i�ڒ艿
              ,in_year_to_amount => gr_add_total(4).year_to_amount -- �N�v ���󍇌v
              ,in_year_quant_t   => gr_add_total(4).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_year_s_cost    => gr_add_total(4).year_s_cost    -- �N�v �W������(�v�Z�p)
              ,in_year_calc      => gr_add_total(4).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
              ,in_year_minus_flg   => gr_add_total(4).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_year_ht_zero_flg => gr_add_total(4).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- -----------------------------------------------------
            --  ���i�敪�I���f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
*/
--
            --------------------------------------------------------
            -- (�S���_)(3)���_�v/(4)���i�敪�v�f�[�^�^�O�o�� 
            --------------------------------------------------------
            <<kyoten_skbn_loop>>
            FOR n IN 3..4 LOOP        -- ���_�v/���i�敪�v
--
              -- ���_�v�̏ꍇ
              IF ( n = 3) THEN
                lv_param_label := gv_name_ktn;
              -- ���i�敪�v�̏ꍇ
              ELSE
                lv_param_label := gv_name_skbn;
              END IF;
--
              prc_create_xml_data_s_k_t
              (
                iv_label_name       => lv_param_label                   -- ���i�敪�v�p�^�O��
                ,in_may_quant       => gr_add_total(n).may_quant      -- �T�� ����
                ,in_may_amount      => gr_add_total(n).may_amount     -- �T�� ���z
                ,in_may_price       => gr_add_total(n).may_price      -- �T�� �i�ڒ艿
                ,in_may_to_amount   => gr_add_total(n).may_to_amount  -- �T�� ���󍇌v
                ,in_may_quant_t     => gr_add_total(n).may_quant_t    -- �T�� ����(�v�Z�p)
                ,in_may_s_cost      => gr_add_total(n).may_s_cost     -- �T�� �W������(�v�Z�p)
                ,in_may_calc        => gr_add_total(n).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
                ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
                ,in_jun_quant       => gr_add_total(n).jun_quant      -- �U�� ����
                ,in_jun_amount      => gr_add_total(n).jun_amount     -- �U�� ���z
                ,in_jun_price       => gr_add_total(n).jun_price      -- �U�� �i�ڒ艿
                ,in_jun_to_amount   => gr_add_total(n).jun_to_amount  -- �U�� ���󍇌v
                ,in_jun_quant_t     => gr_add_total(n).jun_quant_t    -- �U�� ����(�v�Z�p)
                ,in_jun_s_cost      => gr_add_total(n).jun_s_cost     -- �U�� �W������(�v�Z�p)
                ,in_jun_calc        => gr_add_total(n).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
                ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
                ,in_jul_quant       => gr_add_total(n).jul_quant      -- �V�� ����
                ,in_jul_amount      => gr_add_total(n).jul_amount     -- �V�� ���z
                ,in_jul_price       => gr_add_total(n).jul_price      -- �V�� �i�ڒ艿
                ,in_jul_to_amount   => gr_add_total(n).jul_to_amount  -- �V�� ���󍇌v
                ,in_jul_quant_t     => gr_add_total(n).jul_quant_t    -- �V�� ����(�v�Z�p)
                ,in_jul_s_cost      => gr_add_total(n).jul_s_cost     -- �V�� �W������(�v�Z�p)
                ,in_jul_calc        => gr_add_total(n).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
                ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
                ,in_aug_quant       => gr_add_total(n).aug_quant      -- �W�� ����
                ,in_aug_amount      => gr_add_total(n).aug_amount     -- �W�� ���z
                ,in_aug_price       => gr_add_total(n).aug_price      -- �W�� �i�ڒ艿
                ,in_aug_to_amount   => gr_add_total(n).aug_to_amount  -- �W�� ���󍇌v
                ,in_aug_quant_t     => gr_add_total(n).aug_quant_t    -- �W�� ����(�v�Z�p)
                ,in_aug_s_cost      => gr_add_total(n).aug_s_cost     -- �W�� �W������(�v�Z�p)
                ,in_aug_calc        => gr_add_total(n).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
                ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
                ,in_sep_quant       => gr_add_total(n).sep_quant      -- �X�� ����
                ,in_sep_amount      => gr_add_total(n).sep_amount     -- �X�� ���z
                ,in_sep_price       => gr_add_total(n).sep_price      -- �X�� �i�ڒ艿
                ,in_sep_to_amount   => gr_add_total(n).sep_to_amount  -- �X�� ���󍇌v
                ,in_sep_quant_t     => gr_add_total(n).sep_quant_t    -- �X�� ����(�v�Z�p)
                ,in_sep_s_cost      => gr_add_total(n).sep_s_cost     -- �X�� �W������(�v�Z�p)
                ,in_sep_calc        => gr_add_total(n).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
                ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
                ,in_oct_quant       => gr_add_total(n).oct_quant      -- �P�O�� ����
                ,in_oct_amount      => gr_add_total(n).oct_amount     -- �P�O�� ���z
                ,in_oct_price       => gr_add_total(n).oct_price      -- �P�O�� �i�ڒ艿
                ,in_oct_to_amount   => gr_add_total(n).oct_to_amount  -- �P�O�� ���󍇌v
                ,in_oct_quant_t     => gr_add_total(n).oct_quant_t    -- �P�O�� ����(�v�Z�p)
                ,in_oct_s_cost      => gr_add_total(n).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
                ,in_oct_calc        => gr_add_total(n).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
                ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
                ,in_nov_quant       => gr_add_total(n).nov_quant      -- �P�P�� ����
                ,in_nov_amount      => gr_add_total(n).nov_amount     -- �P�P�� ���z
                ,in_nov_price       => gr_add_total(n).nov_price      -- �P�P�� �i�ڒ艿
                ,in_nov_to_amount   => gr_add_total(n).nov_to_amount  -- �P�P�� ���󍇌v
                ,in_nov_quant_t     => gr_add_total(n).nov_quant_t    -- �P�P�� ����(�v�Z�p)
                ,in_nov_s_cost      => gr_add_total(n).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
                ,in_nov_calc        => gr_add_total(n).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
                ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
                ,in_dec_quant       => gr_add_total(n).dec_quant      -- �P�Q�� ����
                ,in_dec_amount      => gr_add_total(n).dec_amount     -- �P�Q�� ���z
                ,in_dec_price       => gr_add_total(n).dec_price      -- �P�Q�� �i�ڒ艿
                ,in_dec_to_amount   => gr_add_total(n).dec_to_amount  -- �P�Q�� ���󍇌v
                ,in_dec_quant_t     => gr_add_total(n).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
                ,in_dec_s_cost      => gr_add_total(n).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
                ,in_dec_calc        => gr_add_total(n).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
                ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
                ,in_jan_quant       => gr_add_total(n).jan_quant      -- �P�� ����
                ,in_jan_amount      => gr_add_total(n).jan_amount     -- �P�� ���z
                ,in_jan_price       => gr_add_total(n).jan_price      -- �P�� �i�ڒ艿
                ,in_jan_to_amount   => gr_add_total(n).jan_to_amount  -- �P�� ���󍇌v
                ,in_jan_quant_t     => gr_add_total(n).jan_quant_t    -- �P�� ����(�v�Z�p)
                ,in_jan_s_cost      => gr_add_total(n).jan_s_cost     -- �P�� �W������(�v�Z�p)
                ,in_jan_calc        => gr_add_total(n).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
                ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
                ,in_feb_quant       => gr_add_total(n).feb_quant      -- �Q�� ����
                ,in_feb_amount      => gr_add_total(n).feb_amount     -- �Q�� ���z
                ,in_feb_price       => gr_add_total(n).feb_price      -- �Q�� �i�ڒ艿
                ,in_feb_to_amount   => gr_add_total(n).feb_to_amount  -- �Q�� ���󍇌v
                ,in_feb_quant_t     => gr_add_total(n).feb_quant_t    -- �Q�� ����(�v�Z�p)
                ,in_feb_s_cost      => gr_add_total(n).feb_s_cost     -- �Q�� �W������(�v�Z�p)
                ,in_feb_calc        => gr_add_total(n).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
                ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
                ,in_mar_quant       => gr_add_total(n).mar_quant      -- �R�� ����
                ,in_mar_amount      => gr_add_total(n).mar_amount     -- �R�� ���z
                ,in_mar_price       => gr_add_total(n).mar_price      -- �R�� �i�ڒ艿
                ,in_mar_to_amount   => gr_add_total(n).mar_to_amount  -- �R�� ���󍇌v
                ,in_mar_quant_t     => gr_add_total(n).mar_quant_t    -- �R�� ����(�v�Z�p)
                ,in_mar_s_cost      => gr_add_total(n).mar_s_cost     -- �R�� �W������(�v�Z�p)
                ,in_mar_calc        => gr_add_total(n).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
                ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
                ,in_apr_quant       => gr_add_total(n).apr_quant      -- �S�� ����
                ,in_apr_amount      => gr_add_total(n).apr_amount     -- �S�� ���z
                ,in_apr_price       => gr_add_total(n).apr_price      -- �S�� �i�ڒ艿
                ,in_apr_to_amount   => gr_add_total(n).apr_to_amount  -- �S�� ���󍇌v
                ,in_apr_quant_t     => gr_add_total(n).apr_quant_t    -- �S�� ����(�v�Z�p)
                ,in_apr_s_cost      => gr_add_total(n).apr_s_cost     -- �S�� �W������(�v�Z�p)
                ,in_apr_calc        => gr_add_total(n).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
                ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
                ,in_year_quant      => gr_add_total(n).year_quant     -- �N�v ����
                ,in_year_amount     => gr_add_total(n).year_amount    -- �N�v ���z
                ,in_year_price      => gr_add_total(n).year_price     -- �N�v �i�ڒ艿
                ,in_year_to_amount  => gr_add_total(n).year_to_amount -- �N�v ���󍇌v
                ,in_year_quant_t    => gr_add_total(n).year_quant_t   -- �N�v ����(�v�Z�p)
                ,in_year_s_cost     => gr_add_total(n).year_s_cost    -- �N�v �W������(�v�Z�p)
                ,in_year_calc       => gr_add_total(n).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
                ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
                ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
              -- ���_�v�̏ꍇ
              IF ( n = 3) THEN
                -- -----------------------------------------------------
                --  ���_�I���f�^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
    --
                -- -----------------------------------------------------
                --  ���_�I���k�f�^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
              -- ���i�敪�v�̏ꍇ
              ELSE
                -- -----------------------------------------------------
                --  ���i�敪�I���f�^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
              END IF;
--
            END LOOP kyoten_skbn_loop;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
--
          END IF;
--
          -- -----------------------------------------------------
          --  (�S���_)���i�敪�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_skbn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (�S���_)���i�敪(�R�[�h) �^�O
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).skbn;
--
          -- -----------------------------------------------------
          -- (�S���_)���i�敪(����) �^�O
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          ----------------------------------------------
          -- (�S���_)���͂o�w���i�敪�x��NULL�̏ꍇ   --
          ----------------------------------------------
          IF (gr_param.prod_div IS NULL) THEN
            -- ���o�f�[�^��'1'�̏ꍇ
            IF (gr_sale_plan(i).skbn = gv_prod_div_leaf) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := lv_name_leaf;  -- '���[�t'
            -- ���o�f�[�^��'2'�̏ꍇ
            ELSIF (gr_sale_plan(i).skbn = gv_prod_div_drink) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := lv_name_drink; -- '�h�����N'
            END IF;
          -- ���͂o�w���i�敪�x���w�肳��Ă���ꍇ
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).skbn_name;
          END IF;
--
          -- -----------------------------------------------------
          -- (�S���_)���_�敪�J�n�k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ktn_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (�S���_)���_�敪�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (�S���_)���_�敪(���_�R�[�h) �^�O
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := '';              -- NULL�\��
--
          -- -----------------------------------------------------
          -- (�S���_)���_�敪(���_����) �^�O
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gv_name_all_ktn; -- '�S���_'
--
          -- -----------------------------------------------------
          -- (�S���_)�Q�R�[�h�J�nL�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (�S���_)�Q�R�[�h�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (�S���_)�i�ڊJ�n�k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- �e�u���C�N�L�[�X�V
          lv_skbn_break := gr_sale_plan(i).skbn;              -- ���i�敪
          lv_gun_break  := gr_sale_plan(i).gun;               -- �Q�R�[�h
          lv_dtl_break  := lv_break_init;                     -- �i�ڃR�[�h
          lv_sttl_break := SUBSTRB(gr_sale_plan(i).gun,1,3);  -- ���Q�v
          lv_lttl_break := SUBSTRB(gr_sale_plan(i).gun,1,1);  -- ��Q�v
--
          ----------------------------------------
          -- (�S���_)�e�W�v���ڏ�����                   --
          ----------------------------------------
          -- �f�[�^���P���ڂ̏ꍇ
          IF (i = 1) THEN 
            <<add_total_loop>>
            FOR l IN 1..5 LOOP        -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
              gr_add_total(l).may_quant       := gn_0; -- �T�� ����
              gr_add_total(l).may_amount      := gn_0; -- �T�� ���z
              gr_add_total(l).may_price       := gn_0; -- �T�� �i�ڒ艿
              gr_add_total(l).may_to_amount   := gn_0; -- �T�� ���󍇌v
              gr_add_total(l).may_quant_t     := gn_0; -- �T�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).may_s_cost      := gn_0; -- �T�� �W������(�v)
              gr_add_total(l).may_calc        := gn_0; -- �T�� �i�ڒ艿*����(�v)
              gr_add_total(l).may_minus_flg   := 'N';  -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).may_ht_zero_flg := 'N';  -- �T�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).jun_quant       := gn_0; -- �U�� ����
              gr_add_total(l).jun_amount      := gn_0; -- �U�� ���z
              gr_add_total(l).jun_price       := gn_0; -- �U�� �i�ڒ艿
              gr_add_total(l).jun_to_amount   := gn_0; -- �U�� ���󍇌v
              gr_add_total(l).jun_quant_t     := gn_0; -- �U�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).jun_s_cost      := gn_0; -- �U�� �W������(�v)
              gr_add_total(l).jun_calc        := gn_0; -- �U�� �i�ڒ艿*����(�v)
              gr_add_total(l).jun_minus_flg   := 'N';  -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).jun_ht_zero_flg := 'N';  -- �U�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).jul_quant       := gn_0; -- �V�� ����
              gr_add_total(l).jul_amount      := gn_0; -- �V�� ���z
              gr_add_total(l).jul_price       := gn_0; -- �V�� �i�ڒ艿
              gr_add_total(l).jul_to_amount   := gn_0; -- �V�� ���󍇌v
              gr_add_total(l).jul_quant_t     := gn_0; -- �V�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).jul_s_cost      := gn_0; -- �V�� �W������(�v)
              gr_add_total(l).jul_calc        := gn_0; -- �V�� �i�ڒ艿*����(�v)
              gr_add_total(l).jul_minus_flg   := 'N';  -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).jul_ht_zero_flg := 'N';  -- �V�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).aug_quant       := gn_0; -- �W�� ����
              gr_add_total(l).aug_amount      := gn_0; -- �W�� ���z
              gr_add_total(l).aug_price       := gn_0; -- �W�� �i�ڒ艿
              gr_add_total(l).aug_to_amount   := gn_0; -- �W�� ���󍇌v
              gr_add_total(l).aug_quant_t     := gn_0; -- �W�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).aug_s_cost      := gn_0; -- �W�� �W������(�v)
              gr_add_total(l).aug_calc        := gn_0; -- �W�� �i�ڒ艿*����(�v)
              gr_add_total(l).aug_minus_flg   := 'N';  -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).aug_ht_zero_flg := 'N';  -- �W�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).sep_quant       := gn_0; -- �X�� ����
              gr_add_total(l).sep_amount      := gn_0; -- �X�� ���z
              gr_add_total(l).sep_price       := gn_0; -- �X�� �i�ڒ艿
              gr_add_total(l).sep_to_amount   := gn_0; -- �X�� ���󍇌v
              gr_add_total(l).sep_quant_t     := gn_0; -- �X�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).sep_s_cost      := gn_0; -- �X�� �W������(�v)
              gr_add_total(l).sep_calc        := gn_0; -- �X�� �i�ڒ艿*����(�v)
              gr_add_total(l).sep_minus_flg   := 'N';  -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).sep_ht_zero_flg := 'N';  -- �X�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).oct_quant       := gn_0; -- �P�O�� ����
              gr_add_total(l).oct_amount      := gn_0; -- �P�O�� ���z
              gr_add_total(l).oct_price       := gn_0; -- �P�O�� �i�ڒ艿
              gr_add_total(l).oct_to_amount   := gn_0; -- �P�O�� ���󍇌v
              gr_add_total(l).oct_quant_t     := gn_0; -- �P�O�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).oct_s_cost      := gn_0; -- �P�O�� �W������(�v)
              gr_add_total(l).oct_calc        := gn_0; -- �P�O�� �i�ڒ艿*����(�v)
              gr_add_total(l).oct_minus_flg   := 'N';  -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).oct_ht_zero_flg := 'N';  -- �P�O�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).nov_quant       := gn_0; -- �P�P�� ����
              gr_add_total(l).nov_amount      := gn_0; -- �P�P�� ���z
              gr_add_total(l).nov_price       := gn_0; -- �P�P�� �i�ڒ艿
              gr_add_total(l).nov_to_amount   := gn_0; -- �P�P�� ���󍇌v
              gr_add_total(l).nov_quant_t     := gn_0; -- �P�P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).nov_s_cost      := gn_0; -- �P�P�� �W������(�v)
              gr_add_total(l).nov_calc        := gn_0; -- �P�P�� �i�ڒ艿*����(�v)
              gr_add_total(l).nov_minus_flg   := 'N';  -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).nov_ht_zero_flg := 'N';  -- �P�P�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).dec_quant       := gn_0; -- �P�Q�� ����
              gr_add_total(l).dec_amount      := gn_0; -- �P�Q�� ���z
              gr_add_total(l).dec_price       := gn_0; -- �P�Q�� �i�ڒ艿
              gr_add_total(l).dec_to_amount   := gn_0; -- �P�Q�� ���󍇌v
              gr_add_total(l).dec_quant_t     := gn_0; -- �P�Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).dec_s_cost      := gn_0; -- �P�Q�� �W������(�v)
              gr_add_total(l).dec_calc        := gn_0; -- �P�Q�� �i�ڒ艿*����(�v)
              gr_add_total(l).dec_minus_flg   := 'N';  -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).dec_ht_zero_flg := 'N';  -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).jan_quant       := gn_0; -- �P�� ����
              gr_add_total(l).jan_amount      := gn_0; -- �P�� ���z
              gr_add_total(l).jan_price       := gn_0; -- �P�� �i�ڒ艿
              gr_add_total(l).jan_to_amount   := gn_0; -- �P�� ���󍇌v
              gr_add_total(l).jan_quant_t     := gn_0; -- �P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).jan_s_cost      := gn_0; -- �P�� �W������(�v)
              gr_add_total(l).jan_calc        := gn_0; -- �P�� �i�ڒ艿*����(�v)
              gr_add_total(l).jan_minus_flg   := 'N';  -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).jan_ht_zero_flg := 'N';  -- �P�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).feb_quant       := gn_0; -- �Q�� ����
              gr_add_total(l).feb_amount      := gn_0; -- �Q�� ���z
              gr_add_total(l).feb_price       := gn_0; -- �Q�� �i�ڒ艿
              gr_add_total(l).feb_to_amount   := gn_0; -- �Q�� ���󍇌v
              gr_add_total(l).feb_quant_t     := gn_0; -- �Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).feb_s_cost      := gn_0; -- �Q�� �W������(�v)
              gr_add_total(l).feb_calc        := gn_0; -- �Q�� �i�ڒ艿*����(�v)
              gr_add_total(l).feb_minus_flg   := 'N';  -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).feb_ht_zero_flg := 'N';  -- �Q�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).mar_quant       := gn_0; -- �R�� ����
              gr_add_total(l).mar_amount      := gn_0; -- �R�� ���z
              gr_add_total(l).mar_price       := gn_0; -- �R�� �i�ڒ艿
              gr_add_total(l).mar_to_amount   := gn_0; -- �R�� ���󍇌v
              gr_add_total(l).mar_quant_t     := gn_0; -- �R�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).mar_s_cost      := gn_0; -- �R�� �W������(�v)
              gr_add_total(l).mar_calc        := gn_0; -- �R�� �i�ڒ艿*����(�v)
              gr_add_total(l).mar_minus_flg   := 'N';  -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).mar_ht_zero_flg := 'N';  -- �R�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).apr_quant       := gn_0; -- �S�� ����
              gr_add_total(l).apr_amount      := gn_0; -- �S�� ���z
              gr_add_total(l).apr_price       := gn_0; -- �S�� �i�ڒ艿
              gr_add_total(l).apr_to_amount   := gn_0; -- �S�� ���󍇌v
              gr_add_total(l).apr_quant_t     := gn_0; -- �S�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).apr_s_cost      := gn_0; -- �S�� �W������(�v)
              gr_add_total(l).apr_calc        := gn_0; -- �S�� �i�ڒ艿*����(�v)
              gr_add_total(l).apr_minus_flg   := 'N';  -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).apr_ht_zero_flg := 'N';  -- �S�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).year_quant      := gn_0; -- �N�v ����
              gr_add_total(l).year_amount     := gn_0; -- �N�v ���z
              gr_add_total(l).year_price      := gn_0; -- �N�v �i�ڒ艿
              gr_add_total(l).year_to_amount  := gn_0; -- �N�v ���󍇌v
              gr_add_total(l).year_quant_t    := gn_0; -- �N�v ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).year_s_cost     := gn_0; -- �N�v �W������(�v)
              gr_add_total(l).year_calc       := gn_0; -- �N�v �i�ڒ艿*����(�v)
              gr_add_total(l).year_minus_flg   := 'N'; -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).year_ht_zero_flg := 'N'; -- �N�v �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            END LOOP add_total_loop;
          -- �f�[�^�Q���ڈȍ~�̏ꍇ
          ELSE
            <<add_total_loop>>
            FOR l IN 1..4 LOOP        -- ���Q�v/��Q�v/���_�v/���i�敪�v
              gr_add_total(l).may_quant       := gn_0; -- �T�� ����
              gr_add_total(l).may_amount      := gn_0; -- �T�� ���z
              gr_add_total(l).may_price       := gn_0; -- �T�� �i�ڒ艿
              gr_add_total(l).may_to_amount   := gn_0; -- �T�� ���󍇌v
              gr_add_total(l).may_quant_t     := gn_0; -- �T�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).may_s_cost      := gn_0; -- �T�� �W������(�v)
              gr_add_total(l).may_calc        := gn_0; -- �T�� �i�ڒ艿*����(�v)
              gr_add_total(l).may_minus_flg   := 'N';  -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).may_ht_zero_flg := 'N';  -- �T�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).jun_quant       := gn_0; -- �U�� ����
              gr_add_total(l).jun_amount      := gn_0; -- �U�� ���z
              gr_add_total(l).jun_price       := gn_0; -- �U�� �i�ڒ艿
              gr_add_total(l).jun_to_amount   := gn_0; -- �U�� ���󍇌v
              gr_add_total(l).jun_quant_t     := gn_0; -- �U�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).jun_s_cost      := gn_0; -- �U�� �W������(�v)
              gr_add_total(l).jun_calc        := gn_0; -- �U�� �i�ڒ艿*����(�v)
              gr_add_total(l).jun_minus_flg   := 'N';  -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).jun_ht_zero_flg := 'N';  -- �U�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).jul_quant       := gn_0; -- �V�� ����
              gr_add_total(l).jul_amount      := gn_0; -- �V�� ���z
              gr_add_total(l).jul_price       := gn_0; -- �V�� �i�ڒ艿
              gr_add_total(l).jul_to_amount   := gn_0; -- �V�� ���󍇌v
              gr_add_total(l).jul_quant_t     := gn_0; -- �V�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).jul_s_cost      := gn_0; -- �V�� �W������(�v)
              gr_add_total(l).jul_calc        := gn_0; -- �V�� �i�ڒ艿*����(�v)
              gr_add_total(l).jul_minus_flg   := 'N';  -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).jul_ht_zero_flg := 'N';  -- �V�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).aug_quant       := gn_0; -- �W�� ����
              gr_add_total(l).aug_amount      := gn_0; -- �W�� ���z
              gr_add_total(l).aug_price       := gn_0; -- �W�� �i�ڒ艿
              gr_add_total(l).aug_to_amount   := gn_0; -- �W�� ���󍇌v
              gr_add_total(l).aug_quant_t     := gn_0; -- �W�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).aug_s_cost      := gn_0; -- �W�� �W������(�v)
              gr_add_total(l).aug_calc        := gn_0; -- �W�� �i�ڒ艿*����(�v)
              gr_add_total(l).aug_minus_flg   := 'N';  -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).aug_ht_zero_flg := 'N';  -- �W�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).sep_quant       := gn_0; -- �X�� ����
              gr_add_total(l).sep_amount      := gn_0; -- �X�� ���z
              gr_add_total(l).sep_price       := gn_0; -- �X�� �i�ڒ艿
              gr_add_total(l).sep_to_amount   := gn_0; -- �X�� ���󍇌v
              gr_add_total(l).sep_quant_t     := gn_0; -- �X�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).sep_s_cost      := gn_0; -- �X�� �W������(�v)
              gr_add_total(l).sep_calc        := gn_0; -- �X�� �i�ڒ艿*����(�v)
              gr_add_total(l).sep_minus_flg   := 'N';  -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).sep_ht_zero_flg := 'N';  -- �X�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).oct_quant       := gn_0; -- �P�O�� ����
              gr_add_total(l).oct_amount      := gn_0; -- �P�O�� ���z
              gr_add_total(l).oct_price       := gn_0; -- �P�O�� �i�ڒ艿
              gr_add_total(l).oct_to_amount   := gn_0; -- �P�O�� ���󍇌v
              gr_add_total(l).oct_quant_t     := gn_0; -- �P�O�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).oct_s_cost      := gn_0; -- �P�O�� �W������(�v)
              gr_add_total(l).oct_calc        := gn_0; -- �P�O�� �i�ڒ艿*����(�v)
              gr_add_total(l).oct_minus_flg   := 'N';  -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).oct_ht_zero_flg := 'N';  -- �P�O�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).nov_quant       := gn_0; -- �P�P�� ����
              gr_add_total(l).nov_amount      := gn_0; -- �P�P�� ���z
              gr_add_total(l).nov_price       := gn_0; -- �P�P�� �i�ڒ艿
              gr_add_total(l).nov_to_amount   := gn_0; -- �P�P�� ���󍇌v
              gr_add_total(l).nov_quant_t     := gn_0; -- �P�P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).nov_s_cost      := gn_0; -- �P�P�� �W������(�v)
              gr_add_total(l).nov_calc        := gn_0; -- �P�P�� �i�ڒ艿*����(�v)
              gr_add_total(l).nov_minus_flg   := 'N';  -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).nov_ht_zero_flg := 'N';  -- �P�P�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).dec_quant       := gn_0; -- �P�Q�� ����
              gr_add_total(l).dec_amount      := gn_0; -- �P�Q�� ���z
              gr_add_total(l).dec_price       := gn_0; -- �P�Q�� �i�ڒ艿
              gr_add_total(l).dec_to_amount   := gn_0; -- �P�Q�� ���󍇌v
              gr_add_total(l).dec_quant_t     := gn_0; -- �P�Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).dec_s_cost      := gn_0; -- �P�Q�� �W������(�v)
              gr_add_total(l).dec_calc        := gn_0; -- �P�Q�� �i�ڒ艿*����(�v)
              gr_add_total(l).dec_minus_flg   := 'N';  -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).dec_ht_zero_flg := 'N';  -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).jan_quant       := gn_0; -- �P�� ����
              gr_add_total(l).jan_amount      := gn_0; -- �P�� ���z
              gr_add_total(l).jan_price       := gn_0; -- �P�� �i�ڒ艿
              gr_add_total(l).jan_to_amount   := gn_0; -- �P�� ���󍇌v
              gr_add_total(l).jan_quant_t     := gn_0; -- �P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).jan_s_cost      := gn_0; -- �P�� �W������(�v)
              gr_add_total(l).jan_calc        := gn_0; -- �P�� �i�ڒ艿*����(�v)
              gr_add_total(l).jan_minus_flg   := 'N';  -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).jan_ht_zero_flg := 'N';  -- �P�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).feb_quant       := gn_0; -- �Q�� ����
              gr_add_total(l).feb_amount      := gn_0; -- �Q�� ���z
              gr_add_total(l).feb_price       := gn_0; -- �Q�� �i�ڒ艿
              gr_add_total(l).feb_to_amount   := gn_0; -- �Q�� ���󍇌v
              gr_add_total(l).feb_quant_t     := gn_0; -- �Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).feb_s_cost      := gn_0; -- �Q�� �W������(�v)
              gr_add_total(l).feb_calc        := gn_0; -- �Q�� �i�ڒ艿*����(�v)
              gr_add_total(l).feb_minus_flg   := 'N';  -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).feb_ht_zero_flg := 'N';  -- �Q�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).mar_quant       := gn_0; -- �R�� ����
              gr_add_total(l).mar_amount      := gn_0; -- �R�� ���z
              gr_add_total(l).mar_price       := gn_0; -- �R�� �i�ڒ艿
              gr_add_total(l).mar_to_amount   := gn_0; -- �R�� ���󍇌v
              gr_add_total(l).mar_quant_t     := gn_0; -- �R�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).mar_s_cost      := gn_0; -- �R�� �W������(�v)
              gr_add_total(l).mar_calc        := gn_0; -- �R�� �i�ڒ艿*����(�v)
              gr_add_total(l).mar_minus_flg   := 'N';  -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).mar_ht_zero_flg := 'N';  -- �R�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).apr_quant       := gn_0; -- �S�� ����
              gr_add_total(l).apr_amount      := gn_0; -- �S�� ���z
              gr_add_total(l).apr_price       := gn_0; -- �S�� �i�ڒ艿
              gr_add_total(l).apr_to_amount   := gn_0; -- �S�� ���󍇌v
              gr_add_total(l).apr_quant_t     := gn_0; -- �S�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).apr_s_cost      := gn_0; -- �S�� �W������(�v)
              gr_add_total(l).apr_calc        := gn_0; -- �S�� �i�ڒ艿*����(�v)
              gr_add_total(l).apr_minus_flg   := 'N';  -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).apr_ht_zero_flg := 'N';  -- �S�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).year_quant      := gn_0; -- �N�v ����
              gr_add_total(l).year_amount     := gn_0; -- �N�v ���z
              gr_add_total(l).year_price      := gn_0; -- �N�v �i�ڒ艿
              gr_add_total(l).year_to_amount  := gn_0; -- �N�v ���󍇌v
              gr_add_total(l).year_quant_t    := gn_0; -- �N�v ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).year_s_cost     := gn_0; -- �N�v �W������(�v)
              gr_add_total(l).year_calc       := gn_0; -- �N�v �i�ڒ艿*����(�v)
              gr_add_total(l).year_minus_flg   := 'N'; -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).year_ht_zero_flg := 'N'; -- �N�v �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            END LOOP add_total_loop;
          END IF;
--
          -- �N�v������
          ln_year_quant_sum  := gn_0;           -- ����
          ln_year_amount_sum := gn_0;           -- ���z
          ln_year_to_am_sum  := gn_0;           -- ���󍇌v
          ln_year_price_sum  := gn_0;           -- �i�ڒ艿
--
          -- XML�o�̓t���O������
          <<xml_out_loop>>
          FOR n IN 1..12 LOOP
            gr_xml_out(n).out_fg   := lv_no;
          END LOOP xml_out_loop;
--
        END IF;
--
        -- ====================================================
        -- (�S���_)�Q�R�[�h�u���C�N
        -- ====================================================
        -- �Q�R�[�h���؂�ւ�����Ƃ�
        IF (gr_sale_plan(i).gun <> lv_gun_break) THEN
          ---------------------------------------------------------------
          -- (�S���_)�e�����o�f�[�^�����݂��Ȃ��ꍇ�A0�\���ɂ�XML�o��  --
          ---------------------------------------------------------------
          <<xml_out_0_loop>>
          FOR m IN 1..12 LOOP
            IF (gr_xml_out(m).out_fg = lv_no) THEN
              prc_create_xml_data_dtl_n
                (
                  iv_label_name     => gr_xml_out(m).tag_name                      -- �o�̓^�O��
                 ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          END LOOP xml_out_0_loop;
--
          -- -----------------------------------------------------
          -- (�S���_)�N�v ���ʃf�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
          -- -----------------------------------------------------
          -- (�S���_)�N�v ���z�f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
          -- -----------------------------------------------------
          -- (�S���_)�N�v �e�����f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          ----------------------------------------------
          -- (�S���_)�e���v�Z (���z�|���󍇌v������)  --
          ----------------------------------------------
          ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
          -- �O���Z��𔻒�
          IF (ln_year_amount_sum <> gn_0) THEN
          -- �l��[0]�o�Ȃ���Όv�Z
          gt_xml_data_table(gl_xml_idx).tag_value := 
                    ROUND((ln_arari / ln_year_amount_sum * 100),2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
          END IF;
--
          -- -----------------------------------------------------
          -- (�S���_)�N�v �|���f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          --------------------------------------
          -- �O���Z���荀�ڂ֔���l��}��     --
          --------------------------------------
          ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> gn_0) THEN
          -- �l��[0]�o�Ȃ���Όv�Z
          ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_kake_par := gn_0;
          END IF;
--
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
          IF ((ln_year_price_sum = 0)
            OR (ln_kake_par < 0)) THEN
            ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
          END IF;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).year_quant     :=
               gr_add_total(r).year_quant     + ln_year_quant_sum;        -- ����
            gr_add_total(r).year_amount    :=
               gr_add_total(r).year_amount    + ln_year_amount_sum;       -- ���z
            gr_add_total(r).year_price     :=
               gr_add_total(r).year_price     + ln_year_price_sum;        -- �i�ڒ艿
            gr_add_total(r).year_to_amount :=
               gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- ���󍇌v
            gr_add_total(r).year_quant_t   :=
               gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- ����(�v)
          END LOOP add_total_loop;
--
          -- -----------------------------------------------------
          -- (�S���_)�i�ڏI���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (�S���_)�i�ڏI���k�f�^�O�o��
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- ====================================================
          -- (�S���_)���Q�v�u���C�N
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan(i).gun,1,3) <> lv_sttl_break) THEN
            --------------------------------------------------------
            -- (�S���_)XML�f�[�^�쐬 - ���[�f�[�^�o�� ���Q�v
            --------------------------------------------------------
            prc_create_xml_data_st_lt
            (
               iv_label_name     => gv_name_st                     -- ���Q�v�p�^�O��
              ,iv_name           => gv_label_st                    -- ���Q�v�^�C�g��
              ,in_may_quant      => gr_add_total(1).may_quant      -- �T�� ����
              ,in_may_amount     => gr_add_total(1).may_amount     -- �T�� ���z
              ,in_may_price      => gr_add_total(1).may_price      -- �T�� �i�ڒ艿
              ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- �T�� ���󍇌v
              ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_may_s_cost     => gr_add_total(1).may_s_cost     -- �T�� �W������(�v�Z�p)
              ,in_may_calc       => gr_add_total(1).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
              ,in_may_minus_flg   => gr_add_total(1).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_may_ht_zero_flg => gr_add_total(1).may_ht_zero_flg -- �T�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jun_quant      => gr_add_total(1).jun_quant      -- �U�� ����
              ,in_jun_amount     => gr_add_total(1).jun_amount     -- �U�� ���z
              ,in_jun_price      => gr_add_total(1).jun_price      -- �U�� �i�ڒ艿
              ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- �U�� ���󍇌v
              ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jun_s_cost     => gr_add_total(1).jun_s_cost     -- �U�� �W������(�v�Z�p)
              ,in_jun_calc       => gr_add_total(1).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
              ,in_jun_minus_flg   => gr_add_total(1).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jun_ht_zero_flg => gr_add_total(1).jun_ht_zero_flg -- �U�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jul_quant      => gr_add_total(1).jul_quant      -- �V�� ����
              ,in_jul_amount     => gr_add_total(1).jul_amount     -- �V�� ���z
              ,in_jul_price      => gr_add_total(1).jul_price      -- �V�� �i�ڒ艿
              ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- �V�� ���󍇌v
              ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jul_s_cost     => gr_add_total(1).jul_s_cost     -- �V�� �W������(�v�Z�p)
              ,in_jul_calc       => gr_add_total(1).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
              ,in_jul_minus_flg   => gr_add_total(1).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jul_ht_zero_flg => gr_add_total(1).jul_ht_zero_flg -- �V�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_aug_quant      => gr_add_total(1).aug_quant      -- �W�� ����
              ,in_aug_amount     => gr_add_total(1).aug_amount     -- �W�� ���z
              ,in_aug_price      => gr_add_total(1).aug_price      -- �W�� �i�ڒ艿
              ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- �W�� ���󍇌v
              ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_aug_s_cost     => gr_add_total(1).aug_s_cost     -- �W�� �W������(�v�Z�p)
              ,in_aug_calc       => gr_add_total(1).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
              ,in_aug_minus_flg   => gr_add_total(1).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_aug_ht_zero_flg => gr_add_total(1).aug_ht_zero_flg -- �W�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_sep_quant      => gr_add_total(1).sep_quant      -- �X�� ����
              ,in_sep_amount     => gr_add_total(1).sep_amount     -- �X�� ���z
              ,in_sep_price      => gr_add_total(1).sep_price      -- �X�� �i�ڒ艿
              ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- �X�� ���󍇌v
              ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_sep_s_cost     => gr_add_total(1).sep_s_cost     -- �X�� �W������(�v�Z�p)
              ,in_sep_calc       => gr_add_total(1).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
              ,in_sep_minus_flg   => gr_add_total(1).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_sep_ht_zero_flg => gr_add_total(1).sep_ht_zero_flg -- �X�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_oct_quant      => gr_add_total(1).oct_quant      -- �P�O�� ����
              ,in_oct_amount     => gr_add_total(1).oct_amount     -- �P�O�� ���z
              ,in_oct_price      => gr_add_total(1).oct_price      -- �P�O�� �i�ڒ艿
              ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- �P�O�� ���󍇌v
              ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_oct_s_cost     => gr_add_total(1).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
              ,in_oct_calc       => gr_add_total(1).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
              ,in_oct_minus_flg   => gr_add_total(1).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_oct_ht_zero_flg => gr_add_total(1).oct_ht_zero_flg -- �P�O�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_nov_quant      => gr_add_total(1).nov_quant      -- �P�P�� ����
              ,in_nov_amount     => gr_add_total(1).nov_amount     -- �P�P�� ���z
              ,in_nov_price      => gr_add_total(1).nov_price      -- �P�P�� �i�ڒ艿
              ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- �P�P�� ���󍇌v
              ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_nov_s_cost     => gr_add_total(1).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
              ,in_nov_calc       => gr_add_total(1).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
              ,in_nov_minus_flg   => gr_add_total(1).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_nov_ht_zero_flg => gr_add_total(1).nov_ht_zero_flg -- �P�P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_dec_quant      => gr_add_total(1).dec_quant      -- �P�Q�� ����
              ,in_dec_amount     => gr_add_total(1).dec_amount     -- �P�Q�� ���z
              ,in_dec_price      => gr_add_total(1).dec_price      -- �P�Q�� �i�ڒ艿
              ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- �P�Q�� ���󍇌v
              ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_dec_s_cost     => gr_add_total(1).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
              ,in_dec_calc       => gr_add_total(1).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_dec_minus_flg   => gr_add_total(1).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_dec_ht_zero_flg => gr_add_total(1).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jan_quant      => gr_add_total(1).jan_quant      -- �P�� ����
              ,in_jan_amount     => gr_add_total(1).jan_amount     -- �P�� ���z
              ,in_jan_price      => gr_add_total(1).jan_price      -- �P�� �i�ڒ艿
              ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- �P�� ���󍇌v
              ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jan_s_cost     => gr_add_total(1).jan_s_cost     -- �P�� �W������(�v�Z�p)
              ,in_jan_calc       => gr_add_total(1).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
              ,in_jan_minus_flg   => gr_add_total(1).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jan_ht_zero_flg => gr_add_total(1).jan_ht_zero_flg -- �P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_feb_quant      => gr_add_total(1).feb_quant      -- �Q�� ����
              ,in_feb_amount     => gr_add_total(1).feb_amount     -- �Q�� ���z
              ,in_feb_price      => gr_add_total(1).feb_price      -- �Q�� �i�ڒ艿
              ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- �Q�� ���󍇌v
              ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_feb_s_cost     => gr_add_total(1).feb_s_cost     -- �Q�� �W������(�v�Z�p)
              ,in_feb_calc       => gr_add_total(1).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_feb_minus_flg   => gr_add_total(1).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_feb_ht_zero_flg => gr_add_total(1).feb_ht_zero_flg -- �Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_mar_quant      => gr_add_total(1).mar_quant      -- �R�� ����
              ,in_mar_amount     => gr_add_total(1).mar_amount     -- �R�� ���z
              ,in_mar_price      => gr_add_total(1).mar_price      -- �R�� �i�ڒ艿
              ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- �R�� ���󍇌v
              ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_mar_s_cost     => gr_add_total(1).mar_s_cost     -- �R�� �W������(�v�Z�p)
              ,in_mar_calc       => gr_add_total(1).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
              ,in_mar_minus_flg   => gr_add_total(1).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_mar_ht_zero_flg => gr_add_total(1).mar_ht_zero_flg -- �R�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_apr_quant      => gr_add_total(1).apr_quant      -- �S�� ����
              ,in_apr_amount     => gr_add_total(1).apr_amount     -- �S�� ���z
              ,in_apr_price      => gr_add_total(1).apr_price      -- �S�� �i�ڒ艿
              ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- �S�� ���󍇌v
              ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_apr_s_cost     => gr_add_total(1).apr_s_cost     -- �S�� �W������(�v�Z�p)
              ,in_apr_calc       => gr_add_total(1).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
              ,in_apr_minus_flg   => gr_add_total(1).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_apr_ht_zero_flg => gr_add_total(1).apr_ht_zero_flg -- �S�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_year_quant     => gr_add_total(1).year_quant     -- �N�v ����
              ,in_year_amount    => gr_add_total(1).year_amount    -- �N�v ���z
              ,in_year_price     => gr_add_total(1).year_price     -- �N�v �i�ڒ艿
              ,in_year_to_amount => gr_add_total(1).year_to_amount -- �N�v ���󍇌v
              ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_year_s_cost    => gr_add_total(1).year_s_cost    -- �N�v �W������(�v�Z�p)
              ,in_year_calc      => gr_add_total(1).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
              ,in_year_minus_flg   => gr_add_total(1).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_year_ht_zero_flg => gr_add_total(1).year_ht_zero_flg -- �N�v �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ���Q�v�u���C�N�L�[�X�V
            lv_sttl_break := SUBSTRB(gr_sale_plan(i).gun,1,3);
--
            -- ���Q�v�W�v���ڏ�����
            gr_add_total(1).may_quant       := gn_0; -- �T�� ����
            gr_add_total(1).may_amount      := gn_0; -- �T�� ���z
            gr_add_total(1).may_price       := gn_0; -- �T�� �i�ڒ艿
            gr_add_total(1).may_to_amount   := gn_0; -- �T�� ���󍇌v
            gr_add_total(1).may_quant_t     := gn_0; -- �T�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).may_s_cost      := gn_0; -- �T�� �W������(�v)
            gr_add_total(1).may_calc        := gn_0; -- �T�� �i�ڒ艿*����(�v)
            gr_add_total(1).may_minus_flg   := 'N';  -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).may_ht_zero_flg := 'N';  -- �T�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).jun_quant       := gn_0; -- �U�� ����
            gr_add_total(1).jun_amount      := gn_0; -- �U�� ���z
            gr_add_total(1).jun_price       := gn_0; -- �U�� �i�ڒ艿
            gr_add_total(1).jun_to_amount   := gn_0; -- �U�� ���󍇌v
            gr_add_total(1).jun_quant_t     := gn_0; -- �U�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).jun_s_cost      := gn_0; -- �U�� �W������(�v)
            gr_add_total(1).jun_calc        := gn_0; -- �U�� �i�ڒ艿*����(�v)
            gr_add_total(1).jun_minus_flg   := 'N';  -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).jun_ht_zero_flg := 'N';  -- �U�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).jul_quant       := gn_0; -- �V�� ����
            gr_add_total(1).jul_amount      := gn_0; -- �V�� ���z
            gr_add_total(1).jul_price       := gn_0; -- �V�� �i�ڒ艿
            gr_add_total(1).jul_to_amount   := gn_0; -- �V�� ���󍇌v
            gr_add_total(1).jul_quant_t     := gn_0; -- �V�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).jul_s_cost      := gn_0; -- �V�� �W������(�v)
            gr_add_total(1).jul_calc        := gn_0; -- �V�� �i�ڒ艿*����(�v)
            gr_add_total(1).jul_minus_flg   := 'N';  -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).jul_ht_zero_flg := 'N';  -- �V�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).aug_quant       := gn_0; -- �W�� ����
            gr_add_total(1).aug_amount      := gn_0; -- �W�� ���z
            gr_add_total(1).aug_price       := gn_0; -- �W�� �i�ڒ艿
            gr_add_total(1).aug_to_amount   := gn_0; -- �W�� ���󍇌v
            gr_add_total(1).aug_quant_t     := gn_0; -- �W�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).aug_s_cost      := gn_0; -- �W�� �W������(�v)
            gr_add_total(1).aug_calc        := gn_0; -- �W�� �i�ڒ艿*����(�v)
            gr_add_total(1).aug_minus_flg   := 'N';  -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).aug_ht_zero_flg := 'N';  -- �W�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).sep_quant       := gn_0; -- �X�� ����
            gr_add_total(1).sep_amount      := gn_0; -- �X�� ���z
            gr_add_total(1).sep_price       := gn_0; -- �X�� �i�ڒ艿
            gr_add_total(1).sep_to_amount   := gn_0; -- �X�� ���󍇌v
            gr_add_total(1).sep_quant_t     := gn_0; -- �X�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).sep_s_cost      := gn_0; -- �X�� �W������(�v)
            gr_add_total(1).sep_calc        := gn_0; -- �X�� �i�ڒ艿*����(�v)
            gr_add_total(1).sep_minus_flg   := 'N';  -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).sep_ht_zero_flg := 'N';  -- �X�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).oct_quant       := gn_0; -- �P�O�� ����
            gr_add_total(1).oct_amount      := gn_0; -- �P�O�� ���z
            gr_add_total(1).oct_price       := gn_0; -- �P�O�� �i�ڒ艿
            gr_add_total(1).oct_to_amount   := gn_0; -- �P�O�� ���󍇌v
            gr_add_total(1).oct_quant_t     := gn_0; -- �P�O�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).oct_s_cost      := gn_0; -- �P�O�� �W������(�v)
            gr_add_total(1).oct_calc        := gn_0; -- �P�O�� �i�ڒ艿*����(�v)
            gr_add_total(1).oct_minus_flg   := 'N';  -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).oct_ht_zero_flg := 'N';  -- �P�O�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).nov_quant       := gn_0; -- �P�P�� ����
            gr_add_total(1).nov_amount      := gn_0; -- �P�P�� ���z
            gr_add_total(1).nov_price       := gn_0; -- �P�P�� �i�ڒ艿
            gr_add_total(1).nov_to_amount   := gn_0; -- �P�P�� ���󍇌v
            gr_add_total(1).nov_quant_t     := gn_0; -- �P�P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).nov_s_cost      := gn_0; -- �P�P�� �W������(�v)
            gr_add_total(1).nov_calc        := gn_0; -- �P�P�� �i�ڒ艿*����(�v)
            gr_add_total(1).nov_minus_flg   := 'N';  -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).nov_ht_zero_flg := 'N';  -- �P�P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).dec_quant       := gn_0; -- �P�Q�� ����
            gr_add_total(1).dec_amount      := gn_0; -- �P�Q�� ���z
            gr_add_total(1).dec_price       := gn_0; -- �P�Q�� �i�ڒ艿
            gr_add_total(1).dec_to_amount   := gn_0; -- �P�Q�� ���󍇌v
            gr_add_total(1).dec_quant_t     := gn_0; -- �P�Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).dec_s_cost      := gn_0; -- �P�Q�� �W������(�v)
            gr_add_total(1).dec_calc        := gn_0; -- �P�Q�� �i�ڒ艿*����(�v)
            gr_add_total(1).dec_minus_flg   := 'N';  -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).dec_ht_zero_flg := 'N';  -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).jan_quant       := gn_0; -- �P�� ����
            gr_add_total(1).jan_amount      := gn_0; -- �P�� ���z
            gr_add_total(1).jan_price       := gn_0; -- �P�� �i�ڒ艿
            gr_add_total(1).jan_to_amount   := gn_0; -- �P�� ���󍇌v
            gr_add_total(1).jan_quant_t     := gn_0; -- �P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).jan_s_cost      := gn_0; -- �P�� �W������(�v)
            gr_add_total(1).jan_calc        := gn_0; -- �P�� �i�ڒ艿*����(�v)
            gr_add_total(1).jan_minus_flg   := 'N';  -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).jan_ht_zero_flg := 'N';  -- �P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).feb_quant       := gn_0; -- �Q�� ����
            gr_add_total(1).feb_amount      := gn_0; -- �Q�� ���z
            gr_add_total(1).feb_price       := gn_0; -- �Q�� �i�ڒ艿
            gr_add_total(1).feb_to_amount   := gn_0; -- �Q�� ���󍇌v
            gr_add_total(1).feb_quant_t     := gn_0; -- �Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).feb_s_cost      := gn_0; -- �Q�� �W������(�v)
            gr_add_total(1).feb_calc        := gn_0; -- �Q�� �i�ڒ艿*����(�v)
            gr_add_total(1).feb_minus_flg   := 'N';  -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).feb_ht_zero_flg := 'N';  -- �Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).mar_quant       := gn_0; -- �R�� ����
            gr_add_total(1).mar_amount      := gn_0; -- �R�� ���z
            gr_add_total(1).mar_price       := gn_0; -- �R�� �i�ڒ艿
            gr_add_total(1).mar_to_amount   := gn_0; -- �R�� ���󍇌v
            gr_add_total(1).mar_quant_t     := gn_0; -- �R�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).mar_s_cost      := gn_0; -- �R�� �W������(�v)
            gr_add_total(1).mar_calc        := gn_0; -- �R�� �i�ڒ艿*����(�v)
            gr_add_total(1).mar_minus_flg   := 'N';  -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).mar_ht_zero_flg := 'N';  -- �R�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).apr_quant       := gn_0; -- �S�� ����
            gr_add_total(1).apr_amount      := gn_0; -- �S�� ���z
            gr_add_total(1).apr_price       := gn_0; -- �S�� �i�ڒ艿
            gr_add_total(1).apr_to_amount   := gn_0; -- �S�� ���󍇌v
            gr_add_total(1).apr_quant_t     := gn_0; -- �S�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).apr_s_cost      := gn_0; -- �S�� �W������(�v)
            gr_add_total(1).apr_calc        := gn_0; -- �S�� �i�ڒ艿*����(�v)
            gr_add_total(1).apr_minus_flg   := 'N';  -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).apr_ht_zero_flg := 'N';  -- �S�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).year_quant      := gn_0; -- �N�v ����
            gr_add_total(1).year_amount     := gn_0; -- �N�v ���z
            gr_add_total(1).year_price      := gn_0; -- �N�v �i�ڒ艿
            gr_add_total(1).year_to_amount  := gn_0; -- �N�v ���󍇌v
            gr_add_total(1).year_quant_t    := gn_0; -- �N�v ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).year_s_cost     := gn_0; -- �N�v �W������(�v)
            gr_add_total(1).year_calc       := gn_0; -- �N�v �i�ڒ艿*����(�v)
            gr_add_total(1).year_minus_flg   := 'N'; -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).year_ht_zero_flg := 'N'; -- �N�v �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END IF;
--
          -- ====================================================
          -- (�S���_)��Q�v�u���C�N
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan(i).gun,1,1) <> lv_lttl_break) THEN
            --------------------------------------------------------
            -- (�S���_)��Q�v�f�[�^�o�� 
            --------------------------------------------------------
            prc_create_xml_data_st_lt
            (
               iv_label_name     => gv_name_lt                     -- ��Q�v�p�^�O��
              ,iv_name           => gv_label_lt                    -- ��Q�v�^�C�g��
              ,in_may_quant      => gr_add_total(2).may_quant      -- �T�� ����
              ,in_may_amount     => gr_add_total(2).may_amount     -- �T�� ���z
              ,in_may_price      => gr_add_total(2).may_price      -- �T�� �i�ڒ艿
              ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- �T�� ���󍇌v
              ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_may_s_cost     => gr_add_total(2).may_s_cost     -- �T�� �W������(�v�Z�p)
              ,in_may_calc       => gr_add_total(2).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
              ,in_may_minus_flg   => gr_add_total(2).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_may_ht_zero_flg => gr_add_total(2).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jun_quant      => gr_add_total(2).jun_quant      -- �U�� ����
              ,in_jun_amount     => gr_add_total(2).jun_amount     -- �U�� ���z
              ,in_jun_price      => gr_add_total(2).jun_price      -- �U�� �i�ڒ艿
              ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- �U�� ���󍇌v
              ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jun_s_cost     => gr_add_total(2).jun_s_cost     -- �U�� �W������(�v�Z�p)
              ,in_jun_calc       => gr_add_total(2).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
              ,in_jun_minus_flg   => gr_add_total(2).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jun_ht_zero_flg => gr_add_total(2).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jul_quant      => gr_add_total(2).jul_quant      -- �V�� ����
              ,in_jul_amount     => gr_add_total(2).jul_amount     -- �V�� ���z
              ,in_jul_price      => gr_add_total(2).jul_price      -- �V�� �i�ڒ艿
              ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- �V�� ���󍇌v
              ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jul_s_cost     => gr_add_total(2).jul_s_cost     -- �V�� �W������(�v�Z�p)
              ,in_jul_calc       => gr_add_total(2).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
              ,in_jul_minus_flg   => gr_add_total(2).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jul_ht_zero_flg => gr_add_total(2).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_aug_quant      => gr_add_total(2).aug_quant      -- �W�� ����
              ,in_aug_amount     => gr_add_total(2).aug_amount     -- �W�� ���z
              ,in_aug_price      => gr_add_total(2).aug_price      -- �W�� �i�ڒ艿
              ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- �W�� ���󍇌v
              ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_aug_s_cost     => gr_add_total(2).aug_s_cost     -- �W�� �W������(�v�Z�p)
              ,in_aug_calc       => gr_add_total(2).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
              ,in_aug_minus_flg   => gr_add_total(2).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_aug_ht_zero_flg => gr_add_total(2).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_sep_quant      => gr_add_total(2).sep_quant      -- �X�� ����
              ,in_sep_amount     => gr_add_total(2).sep_amount     -- �X�� ���z
              ,in_sep_price      => gr_add_total(2).sep_price      -- �X�� �i�ڒ艿
              ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- �X�� ���󍇌v
              ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_sep_s_cost     => gr_add_total(2).sep_s_cost     -- �X�� �W������(�v�Z�p)
              ,in_sep_calc       => gr_add_total(2).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
              ,in_sep_minus_flg   => gr_add_total(2).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_sep_ht_zero_flg => gr_add_total(2).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_oct_quant      => gr_add_total(2).oct_quant      -- �P�O�� ����
              ,in_oct_amount     => gr_add_total(2).oct_amount     -- �P�O�� ���z
              ,in_oct_price      => gr_add_total(2).oct_price      -- �P�O�� �i�ڒ艿
              ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- �P�O�� ���󍇌v
              ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_oct_s_cost     => gr_add_total(2).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
              ,in_oct_calc       => gr_add_total(2).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
              ,in_oct_minus_flg   => gr_add_total(2).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_oct_ht_zero_flg => gr_add_total(2).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_nov_quant      => gr_add_total(2).nov_quant      -- �P�P�� ����
              ,in_nov_amount     => gr_add_total(2).nov_amount     -- �P�P�� ���z
              ,in_nov_price      => gr_add_total(2).nov_price      -- �P�P�� �i�ڒ艿
              ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- �P�P�� ���󍇌v
              ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_nov_s_cost     => gr_add_total(2).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
              ,in_nov_calc       => gr_add_total(2).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
              ,in_nov_minus_flg   => gr_add_total(2).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_nov_ht_zero_flg => gr_add_total(2).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_dec_quant      => gr_add_total(2).dec_quant      -- �P�Q�� ����
              ,in_dec_amount     => gr_add_total(2).dec_amount     -- �P�Q�� ���z
              ,in_dec_price      => gr_add_total(2).dec_price      -- �P�Q�� �i�ڒ艿
              ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- �P�Q�� ���󍇌v
              ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_dec_s_cost     => gr_add_total(2).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
              ,in_dec_calc       => gr_add_total(2).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_dec_minus_flg   => gr_add_total(2).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_dec_ht_zero_flg => gr_add_total(2).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jan_quant      => gr_add_total(2).jan_quant      -- �P�� ����
              ,in_jan_amount     => gr_add_total(2).jan_amount     -- �P�� ���z
              ,in_jan_price      => gr_add_total(2).jan_price      -- �P�� �i�ڒ艿
              ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- �P�� ���󍇌v
              ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jan_s_cost     => gr_add_total(2).jan_s_cost     -- �P�� �W������(�v�Z�p)
              ,in_jan_calc       => gr_add_total(2).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
              ,in_jan_minus_flg   => gr_add_total(2).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jan_ht_zero_flg => gr_add_total(2).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_feb_quant      => gr_add_total(2).feb_quant      -- �Q�� ����
              ,in_feb_amount     => gr_add_total(2).feb_amount     -- �Q�� ���z
              ,in_feb_price      => gr_add_total(2).feb_price      -- �Q�� �i�ڒ艿
              ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- �Q�� ���󍇌v
              ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_feb_s_cost     => gr_add_total(2).feb_s_cost     -- �Q�� �W������(�v�Z�p)
              ,in_feb_calc       => gr_add_total(2).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_feb_minus_flg   => gr_add_total(2).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_feb_ht_zero_flg => gr_add_total(2).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_mar_quant      => gr_add_total(2).mar_quant      -- �R�� ����
              ,in_mar_amount     => gr_add_total(2).mar_amount     -- �R�� ���z
              ,in_mar_price      => gr_add_total(2).mar_price      -- �R�� �i�ڒ艿
              ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- �R�� ���󍇌v
              ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_mar_s_cost     => gr_add_total(2).mar_s_cost     -- �R�� �W������(�v�Z�p)
              ,in_mar_calc       => gr_add_total(2).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
              ,in_mar_minus_flg   => gr_add_total(2).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_mar_ht_zero_flg => gr_add_total(2).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_apr_quant      => gr_add_total(2).apr_quant      -- �S�� ����
              ,in_apr_amount     => gr_add_total(2).apr_amount     -- �S�� ���z
              ,in_apr_price      => gr_add_total(2).apr_price      -- �S�� �i�ڒ艿
              ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- �S�� ���󍇌v
              ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_apr_s_cost     => gr_add_total(2).apr_s_cost     -- �S�� �W������(�v�Z�p)
              ,in_apr_calc       => gr_add_total(2).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
              ,in_apr_minus_flg   => gr_add_total(2).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_apr_ht_zero_flg => gr_add_total(2).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_year_quant     => gr_add_total(2).year_quant     -- �N�v ����
              ,in_year_amount    => gr_add_total(2).year_amount    -- �N�v ���z
              ,in_year_price     => gr_add_total(2).year_price     -- �N�v �i�ڒ艿
              ,in_year_to_amount => gr_add_total(2).year_to_amount -- �N�v ���󍇌v
              ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_year_s_cost    => gr_add_total(2).year_s_cost    -- �N�v �W������(�v�Z�p)
              ,in_year_calc      => gr_add_total(2).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
              ,in_year_minus_flg   => gr_add_total(2).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_year_ht_zero_flg => gr_add_total(2).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ��Q�v�u���C�N�L�[�X�V
            lv_lttl_break := SUBSTRB(gr_sale_plan(i).gun,1,1);
--
            -- ��Q�v�W�v�p���ڏ�����
            gr_add_total(2).may_quant       := gn_0; -- �T�� ����
            gr_add_total(2).may_amount      := gn_0; -- �T�� ���z
            gr_add_total(2).may_price       := gn_0; -- �T�� �i�ڒ艿
            gr_add_total(2).may_to_amount   := gn_0; -- �T�� ���󍇌v
            gr_add_total(2).may_quant_t     := gn_0; -- �T�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).may_s_cost      := gn_0; -- �T�� �W������(�v)
            gr_add_total(2).may_calc        := gn_0; -- �T�� �i�ڒ艿*����(�v)
            gr_add_total(2).may_minus_flg   := 'N';  -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).may_ht_zero_flg := 'N';  -- �T�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).jun_quant       := gn_0; -- �U�� ����
            gr_add_total(2).jun_amount      := gn_0; -- �U�� ���z
            gr_add_total(2).jun_price       := gn_0; -- �U�� �i�ڒ艿
            gr_add_total(2).jun_to_amount   := gn_0; -- �U�� ���󍇌v
            gr_add_total(2).jun_quant_t     := gn_0; -- �U�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).jun_s_cost      := gn_0; -- �U�� �W������(�v)
            gr_add_total(2).jun_calc        := gn_0; -- �U�� �i�ڒ艿*����(�v)
            gr_add_total(2).jun_minus_flg   := 'N';  -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).jun_ht_zero_flg := 'N';  -- �U�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).jul_quant       := gn_0; -- �V�� ����
            gr_add_total(2).jul_amount      := gn_0; -- �V�� ���z
            gr_add_total(2).jul_price       := gn_0; -- �V�� �i�ڒ艿
            gr_add_total(2).jul_to_amount   := gn_0; -- �V�� ���󍇌v
            gr_add_total(2).jul_quant_t     := gn_0; -- �V�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).jul_s_cost      := gn_0; -- �V�� �W������(�v)
            gr_add_total(2).jul_calc        := gn_0; -- �V�� �i�ڒ艿*����(�v)
            gr_add_total(2).jul_minus_flg   := 'N';  -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).jul_ht_zero_flg := 'N';  -- �V�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).aug_quant       := gn_0; -- �W�� ����
            gr_add_total(2).aug_amount      := gn_0; -- �W�� ���z
            gr_add_total(2).aug_price       := gn_0; -- �W�� �i�ڒ艿
            gr_add_total(2).aug_to_amount   := gn_0; -- �W�� ���󍇌v
            gr_add_total(2).aug_quant_t     := gn_0; -- �W�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).aug_s_cost      := gn_0; -- �W�� �W������(�v)
            gr_add_total(2).aug_calc        := gn_0; -- �W�� �i�ڒ艿*����(�v)
            gr_add_total(2).aug_minus_flg   := 'N';  -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).aug_ht_zero_flg := 'N';  -- �W�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).sep_quant       := gn_0; -- �X�� ����
            gr_add_total(2).sep_amount      := gn_0; -- �X�� ���z
            gr_add_total(2).sep_price       := gn_0; -- �X�� �i�ڒ艿
            gr_add_total(2).sep_to_amount   := gn_0; -- �X�� ���󍇌v
            gr_add_total(2).sep_quant_t     := gn_0; -- �X�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).sep_s_cost      := gn_0; -- �X�� �W������(�v)
            gr_add_total(2).sep_calc        := gn_0; -- �X�� �i�ڒ艿*����(�v)
            gr_add_total(2).sep_minus_flg   := 'N';  -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).sep_ht_zero_flg := 'N';  -- �X�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).oct_quant       := gn_0; -- �P�O�� ����
            gr_add_total(2).oct_amount      := gn_0; -- �P�O�� ���z
            gr_add_total(2).oct_price       := gn_0; -- �P�O�� �i�ڒ艿
            gr_add_total(2).oct_to_amount   := gn_0; -- �P�O�� ���󍇌v
            gr_add_total(2).oct_quant_t     := gn_0; -- �P�O�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).oct_s_cost      := gn_0; -- �P�O�� �W������(�v)
            gr_add_total(2).oct_calc        := gn_0; -- �P�O�� �i�ڒ艿*����(�v)
            gr_add_total(2).oct_minus_flg   := 'N';  -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).oct_ht_zero_flg := 'N';  -- �P�O�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).nov_quant       := gn_0; -- �P�P�� ����
            gr_add_total(2).nov_amount      := gn_0; -- �P�P�� ���z
            gr_add_total(2).nov_price       := gn_0; -- �P�P�� �i�ڒ艿
            gr_add_total(2).nov_to_amount   := gn_0; -- �P�P�� ���󍇌v
            gr_add_total(2).nov_quant_t     := gn_0; -- �P�P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).nov_s_cost      := gn_0; -- �P�P�� �W������(�v)
            gr_add_total(2).nov_calc        := gn_0; -- �P�P�� �i�ڒ艿*����(�v)
            gr_add_total(2).nov_minus_flg   := 'N';  -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).nov_ht_zero_flg := 'N';  -- �P�P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).dec_quant       := gn_0; -- �P�Q�� ����
            gr_add_total(2).dec_amount      := gn_0; -- �P�Q�� ���z
            gr_add_total(2).dec_price       := gn_0; -- �P�Q�� �i�ڒ艿
            gr_add_total(2).dec_to_amount   := gn_0; -- �P�Q�� ���󍇌v
            gr_add_total(2).dec_quant_t     := gn_0; -- �P�Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).dec_s_cost      := gn_0; -- �P�Q�� �W������(�v)
            gr_add_total(2).dec_calc        := gn_0; -- �P�Q�� �i�ڒ艿*����(�v)
            gr_add_total(2).dec_minus_flg   := 'N';  -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).dec_ht_zero_flg := 'N';  -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).jan_quant       := gn_0; -- �P�� ����
            gr_add_total(2).jan_amount      := gn_0; -- �P�� ���z
            gr_add_total(2).jan_price       := gn_0; -- �P�� �i�ڒ艿
            gr_add_total(2).jan_to_amount   := gn_0; -- �P�� ���󍇌v
            gr_add_total(2).jan_quant_t     := gn_0; -- �P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).jan_s_cost      := gn_0; -- �P�� �W������(�v)
            gr_add_total(2).jan_calc        := gn_0; -- �P�� �i�ڒ艿*����(�v)
            gr_add_total(2).jan_minus_flg   := 'N';  -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).jan_ht_zero_flg := 'N';  -- �P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).feb_quant       := gn_0; -- �Q�� ����
            gr_add_total(2).feb_amount      := gn_0; -- �Q�� ���z
            gr_add_total(2).feb_price       := gn_0; -- �Q�� �i�ڒ艿
            gr_add_total(2).feb_to_amount   := gn_0; -- �Q�� ���󍇌v
            gr_add_total(2).feb_quant_t     := gn_0; -- �Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).feb_s_cost      := gn_0; -- �Q�� �W������(�v)
            gr_add_total(2).feb_calc        := gn_0; -- �Q�� �i�ڒ艿*����(�v)
            gr_add_total(2).feb_minus_flg   := 'N';  -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).feb_ht_zero_flg := 'N';  -- �Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).mar_quant       := gn_0; -- �R�� ����
            gr_add_total(2).mar_amount      := gn_0; -- �R�� ���z
            gr_add_total(2).mar_price       := gn_0; -- �R�� �i�ڒ艿
            gr_add_total(2).mar_to_amount   := gn_0; -- �R�� ���󍇌v
            gr_add_total(2).mar_quant_t     := gn_0; -- �R�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).mar_s_cost      := gn_0; -- �R�� �W������(�v)
            gr_add_total(2).mar_calc        := gn_0; -- �R�� �i�ڒ艿*����(�v)
            gr_add_total(2).mar_minus_flg   := 'N';  -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).mar_ht_zero_flg := 'N';  -- �R�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).apr_quant       := gn_0; -- �S�� ����
            gr_add_total(2).apr_amount      := gn_0; -- �S�� ���z
            gr_add_total(2).apr_price       := gn_0; -- �S�� �i�ڒ艿
            gr_add_total(2).apr_to_amount   := gn_0; -- �S�� ���󍇌v
            gr_add_total(2).apr_quant_t     := gn_0; -- �S�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).apr_s_cost      := gn_0; -- �S�� �W������(�v)
            gr_add_total(2).apr_calc        := gn_0; -- �S�� �i�ڒ艿*����(�v)
            gr_add_total(2).apr_minus_flg   := 'N';  -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).apr_ht_zero_flg := 'N';  -- �S�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).year_quant      := gn_0; -- �N�v ����
            gr_add_total(2).year_amount     := gn_0; -- �N�v ���z
            gr_add_total(2).year_price      := gn_0; -- �N�v �i�ڒ艿
            gr_add_total(2).year_to_amount  := gn_0; -- �N�v ���󍇌v
            gr_add_total(2).year_quant_t    := gn_0; -- �N�v ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).year_s_cost     := gn_0; -- �N�v �W������(�v)
            gr_add_total(2).year_calc       := gn_0; -- �N�v �i�ڒ艿*����(�v)
            gr_add_total(2).year_minus_flg   := 'N'; -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).year_ht_zero_flg := 'N'; -- �N�v �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END IF;
--
          -- -----------------------------------------------------
          -- (�S���_)�Q�R�[�h�I���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (�S���_)�Q�R�[�h�I��L�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (�S���_)�Q�R�[�h�J�nL�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (�S���_)�Q�R�[�h�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (�S���_)�i�ڊJ�n�k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          --  �u���C�N�L�[�X�V
          lv_gun_break  := gr_sale_plan(i).gun;  -- �Q�R�[�h
          lv_dtl_break  := lv_break_init;        -- �i�ڃR�[�h
--
          -- �N�v������
          ln_year_quant_sum  := gn_0;            -- ����
          ln_year_amount_sum := gn_0;            -- ���z
          ln_year_to_am_sum  := gn_0;            -- ���󍇌v
          ln_year_price_sum  := gn_0;            -- �i�ڒ艿
--
          -- XML�o�̓t���O������
          <<xml_out_loop>>
          FOR n IN 1..12 LOOP
            gr_xml_out(n).out_fg   := lv_no;
          END LOOP xml_out_loop;
--
        END IF;
--
        -- ====================================================
        -- (�S���_)�i�ڃR�[�h�u���C�N
        -- ====================================================
        -- �ŏ��̃��R�[�h�̎��ƁA�i�ڂ��؂�ւ�����Ƃ��\��
        IF ((lv_dtl_break = lv_break_init)
          OR (lv_dtl_break <> gr_sale_plan(i).item_no)) THEN
          -- �ŏ��̃��R�[�h�ł́A�I���^�O�͕\�����Ȃ��B
          IF (lv_dtl_break <> lv_break_init) THEN
            ---------------------------------------------------------------
            -- (�S���_)�e�����o�f�[�^�����݂��Ȃ��ꍇ�A0�\���ɂ�XML�o��  --
            ---------------------------------------------------------------
            <<xml_out_0_loop>>
            FOR m IN 1..12 LOOP
              IF (gr_xml_out(m).out_fg = lv_no) THEN
                prc_create_xml_data_dtl_n
                  (
                    iv_label_name     => gr_xml_out(m).tag_name                      -- �o�̓^�O��
                   ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                   ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                   ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                  );
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
              END IF;
            END LOOP xml_out_0_loop;
--
            -- -----------------------------------------------------
            -- (�S���_)�N�v ���ʃf�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
            -- -----------------------------------------------------
            -- (�S���_)�N�v ���z�f�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
            -- -----------------------------------------------------
            -- (�S���_)�N�v �e�����f�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            --------------------------------------
            -- (�S���_)�e���v�Z (���z�|���󍇌v������)  --
            --------------------------------------
            ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
            -- �O���Z��𔻒�
            IF (ln_year_amount_sum <> gn_0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            gt_xml_data_table(gl_xml_idx).tag_value := 
                      ROUND((ln_arari / ln_year_amount_sum * 100),2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
            END IF;
--
            -- -----------------------------------------------------
            -- (�S���_)�N�v �|���f�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            --------------------------------------
            -- �O���Z���荀�ڂ֔���l��}��     --
            --------------------------------------
            ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
            -- �O���Z��𔻒�
            IF (ln_chk_0 <> gn_0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_kake_par := gn_0;
            END IF;
--
            -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
            IF ((ln_year_price_sum = 0)
              OR (ln_kake_par < 0)) THEN
              ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
            END IF;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
            -- �e�W�v���ڂփf�[�^�}��
            <<add_total_loop>>
            FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
              gr_add_total(r).year_quant     :=
                 gr_add_total(r).year_quant     + ln_year_quant_sum;        -- ����
              gr_add_total(r).year_amount    :=
                 gr_add_total(r).year_amount    + ln_year_amount_sum;       -- ���z
              gr_add_total(r).year_price     :=
                 gr_add_total(r).year_price     + ln_year_price_sum;        -- �i�ڒ艿
              gr_add_total(r).year_to_amount :=
                 gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- ���󍇌v
              gr_add_total(r).year_quant_t   :=
                 gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- ����(�v)
            END LOOP add_total_loop;
--
            -- -----------------------------------------------------
            -- (�S���_)�i�ڏI���f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- �N�v������
            ln_year_quant_sum  := gn_0;           -- ����
            ln_year_amount_sum := gn_0;           -- ���z
            ln_year_to_am_sum  := gn_0;           -- ���󍇌v
            ln_year_price_sum  := gn_0;           -- �i�ڒ艿
--
          END IF;
          -- -----------------------------------------------------
          -- (�S���_)�i�ڊJ�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (�S���_)�Q�R�[�h�f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'gun_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).gun;
--
          -- -----------------------------------------------------
          -- (�S���_)�i��(�R�[�h)�f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).item_no;
--
          -- -----------------------------------------------------
          -- (�S���_)�i��(����)�f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan(i).item_short_name;
--
          -- XML�o�̓t���O������
          <<xml_out_loop>>
          FOR n IN 1..12 LOOP
            gr_xml_out(n).out_fg   := lv_no;
          END LOOP xml_out_loop;
--
        END IF;
--
        -- ====================================================
        -- (�S���_)���׃f�[�^�o��
        -- ====================================================
        ------------------------------------
        -- (�S���_)���o�f�[�^���T���̏ꍇ --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_may_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_may                             -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                -- �N�v�p ����
             ,on_price          => ln_price                                -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_5>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).may_quant     :=
               gr_add_total(r).may_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- ����
            gr_add_total(r).may_amount    :=
               gr_add_total(r).may_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- ���z
            gr_add_total(r).may_price     :=
               gr_add_total(r).may_price     + ln_price;                                -- �i�ڒ艿
            gr_add_total(r).may_to_amount :=
               gr_add_total(r).may_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- ���󍇌v
            gr_add_total(r).may_quant_t   :=
               gr_add_total(r).may_quant_t   + ln_quant;                                -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).may_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).may_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).may_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).may_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                             -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).may_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).may_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_5;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(1).tag_name := gv_name_may;
          gr_xml_out(1).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(1).tag_name := gv_name_may;
        END IF;
--
        ------------------------------------
        -- (�S���_)���o�f�[�^���U���̏ꍇ --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_jun_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_jun                             -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                -- �N�v�p ����
             ,on_price          => ln_price                                -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                             -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);     -- ���󍇌v
          ln_year_price_sum  := ln_price;                                    -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_6>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).jun_quant     :=
               gr_add_total(r).jun_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- ����
            gr_add_total(r).jun_amount    :=
               gr_add_total(r).jun_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- ���z
            gr_add_total(r).jun_price     :=
               gr_add_total(r).jun_price     + ln_price;                                -- �i�ڒ艿
            gr_add_total(r).jun_to_amount :=
               gr_add_total(r).jun_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- ���󍇌v
            gr_add_total(r).jun_quant_t   :=
               gr_add_total(r).jun_quant_t   + ln_quant;                                -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).jun_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).jun_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).jun_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).jun_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                             -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).jun_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).jun_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_6;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(2).tag_name := gv_name_jun;
          gr_xml_out(2).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(2).tag_name := gv_name_jun;
        END IF;
--
        ------------------------------------
        -- (�S���_)���o�f�[�^���V���̏ꍇ --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_jul_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_jul                             -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                -- �N�v�p ����
             ,on_price          => ln_price                                -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_7>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).jul_quant     :=
               gr_add_total(r).jul_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- ����
            gr_add_total(r).jul_amount    :=
               gr_add_total(r).jul_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- ���z
            gr_add_total(r).jul_price     :=
               gr_add_total(r).jul_price     + ln_price;                                -- �i�ڒ艿
            gr_add_total(r).jul_to_amount :=
               gr_add_total(r).jul_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- ���󍇌v
            gr_add_total(r).jul_quant_t   :=
               gr_add_total(r).jul_quant_t   + ln_quant;                                -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).jul_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).jul_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).jul_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).jul_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                             -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).jul_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).jul_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_7;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(3).tag_name := gv_name_jul;
          gr_xml_out(3).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(3).tag_name := gv_name_jul;
        END IF;
--
        ------------------------------------
        -- (�S���_)���o�f�[�^���W���̏ꍇ --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_aug_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_aug                             -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                -- �N�v�p ����
             ,on_price          => ln_price                                -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_8>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).aug_quant     :=
               gr_add_total(r).aug_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- ����
            gr_add_total(r).aug_amount    :=
               gr_add_total(r).aug_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- ���z
            gr_add_total(r).aug_price     :=
               gr_add_total(r).aug_price     + ln_price;                                -- �i�ڒ艿
            gr_add_total(r).aug_to_amount :=
               gr_add_total(r).aug_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- ���󍇌v
            gr_add_total(r).aug_quant_t   :=
               gr_add_total(r).aug_quant_t   + ln_quant;                                -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).aug_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).aug_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).aug_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).aug_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                             -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).aug_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).aug_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_8;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(4).tag_name := gv_name_aug;
          gr_xml_out(4).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(4).tag_name := gv_name_aug;
        END IF;
--
        ------------------------------------
        -- (�S���_)���o�f�[�^���X���̏ꍇ --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_sep_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_sep                             -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                -- �N�v�p ����
             ,on_price          => ln_price                                -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_9>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).sep_quant     :=
               gr_add_total(r).sep_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- ����
            gr_add_total(r).sep_amount    :=
               gr_add_total(r).sep_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- ���z
            gr_add_total(r).sep_price     :=
               gr_add_total(r).sep_price     + ln_price;                                -- �i�ڒ艿
            gr_add_total(r).sep_to_amount :=
               gr_add_total(r).sep_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- ���󍇌v
            gr_add_total(r).sep_quant_t   :=
               gr_add_total(r).sep_quant_t   + ln_quant;                                -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).sep_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).sep_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).sep_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).sep_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).sep_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).sep_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_9;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(5).tag_name := gv_name_sep;
          gr_xml_out(5).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(5).tag_name := gv_name_sep;
        END IF;
--
        --------------------------------------
        -- (�S���_)���o�f�[�^���P�O���̏ꍇ --
        --------------------------------------
        IF (gr_sale_plan(i).month = lv_oct_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_oct                             -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                -- �N�v�p ����
             ,on_price          => ln_price                                -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_10>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).oct_quant     :=
               gr_add_total(r).oct_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- ����
            gr_add_total(r).oct_amount    :=
               gr_add_total(r).oct_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- ���z
            gr_add_total(r).oct_price     :=
               gr_add_total(r).oct_price     + ln_price;                                -- �i�ڒ艿
            gr_add_total(r).oct_to_amount :=
               gr_add_total(r).oct_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- ���󍇌v
            gr_add_total(r).oct_quant_t   :=
               gr_add_total(r).oct_quant_t   + ln_quant;                                -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).oct_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).oct_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).oct_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).oct_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).oct_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).oct_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_10;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(6).tag_name := gv_name_oct;
          gr_xml_out(6).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(6).tag_name := gv_name_oct;
        END IF;
--
        --------------------------------------
        -- (�S���_)���o�f�[�^���P�P���̏ꍇ --
        --------------------------------------
        IF (gr_sale_plan(i).month = lv_nov_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_nov                             -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                -- �N�v�p ����
             ,on_price          => ln_price                                -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_11>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).nov_quant     :=
               gr_add_total(r).nov_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- ����
            gr_add_total(r).nov_amount    :=
               gr_add_total(r).nov_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- ���z
            gr_add_total(r).nov_price     :=
               gr_add_total(r).nov_price     + ln_price;                                -- �i�ڒ艿
            gr_add_total(r).nov_to_amount :=
               gr_add_total(r).nov_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- ���󍇌v
            gr_add_total(r).nov_quant_t   :=
               gr_add_total(r).nov_quant_t   + ln_quant;                                -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).nov_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).nov_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).nov_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).nov_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).nov_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).nov_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_11;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(7).tag_name := gv_name_nov;
          gr_xml_out(7).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(7).tag_name := gv_name_nov;
        END IF;
--
        --------------------------------------
        -- (�S���_)���o�f�[�^���P�Q���̏ꍇ --
        --------------------------------------
        IF (gr_sale_plan(i).month = lv_dec_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_dec                             -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                -- �N�v�p ����
             ,on_price          => ln_price                                -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_12>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).dec_quant     :=
               gr_add_total(r).dec_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- ����
            gr_add_total(r).dec_amount    :=
               gr_add_total(r).dec_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- ���z
            gr_add_total(r).dec_price     :=
               gr_add_total(r).dec_price     + ln_price;                                -- �i�ڒ艿
            gr_add_total(r).dec_to_amount :=
               gr_add_total(r).dec_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- ���󍇌v
            gr_add_total(r).dec_quant_t   :=
               gr_add_total(r).dec_quant_t   + ln_quant;                                -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).dec_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).dec_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).dec_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).dec_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).dec_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).dec_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_12;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(8).tag_name := gv_name_dec;
          gr_xml_out(8).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(8).tag_name := gv_name_dec;
        END IF;
--
        ------------------------------------
        -- (�S���_)���o�f�[�^���P���̏ꍇ --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_jan_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_jan                             -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                -- �N�v�p ����
             ,on_price          => ln_price                                -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_1>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).jan_quant     :=
               gr_add_total(r).jan_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- ����
            gr_add_total(r).jan_amount    :=
               gr_add_total(r).jan_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- ���z
            gr_add_total(r).jan_price     :=
               gr_add_total(r).jan_price     + ln_price;                                -- �i�ڒ艿
            gr_add_total(r).jan_to_amount :=
               gr_add_total(r).jan_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- ���󍇌v
            gr_add_total(r).jan_quant_t   :=
               gr_add_total(r).jan_quant_t   + ln_quant;                                -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).jan_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).jan_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).jan_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).jan_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).jan_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).jan_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_1;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(9).tag_name := gv_name_jan;
          gr_xml_out(9).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(9).tag_name := gv_name_jan;
        END IF;
--
        ------------------------------------
        -- (�S���_)���o�f�[�^���Q���̏ꍇ --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_feb_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_feb                             -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                -- �N�v�p ����
             ,on_price          => ln_price                                -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_2>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).feb_quant     :=
               gr_add_total(r).feb_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- ����
            gr_add_total(r).feb_amount    :=
               gr_add_total(r).feb_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- ���z
            gr_add_total(r).feb_price     :=
               gr_add_total(r).feb_price     + ln_price;                                -- �i�ڒ艿
            gr_add_total(r).feb_to_amount :=
               gr_add_total(r).feb_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- ���󍇌v
            gr_add_total(r).feb_quant_t   :=
               gr_add_total(r).feb_quant_t   + ln_quant;                                -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).feb_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).feb_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).feb_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).feb_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).feb_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).feb_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_2;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(10).tag_name := gv_name_feb;
          gr_xml_out(10).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(10).tag_name := gv_name_feb;
        END IF;
--
        ------------------------------------
        -- (�S���_)���o�f�[�^���R���̏ꍇ --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_mar_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_mar                             -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                -- �N�v�p ����
             ,on_price          => ln_price                                -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_3>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).mar_quant     :=
               gr_add_total(r).mar_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- ����
            gr_add_total(r).mar_amount    :=
               gr_add_total(r).mar_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- ���z
            gr_add_total(r).mar_price     :=
               gr_add_total(r).mar_price     + ln_price;                                -- �i�ڒ艿
            gr_add_total(r).mar_to_amount :=
               gr_add_total(r).mar_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- ���󍇌v
            gr_add_total(r).mar_quant_t   :=
               gr_add_total(r).mar_quant_t   + ln_quant;                                -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).mar_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).mar_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).mar_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).mar_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).mar_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).mar_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_3;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(11).tag_name := gv_name_mar;
          gr_xml_out(11).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(11).tag_name := gv_name_mar;
        END IF;
--
        ------------------------------------
        -- (�S���_)���o�f�[�^���S���̏ꍇ --
        ------------------------------------
        IF (gr_sale_plan(i).month = lv_apr_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_apr                             -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                -- �N�v�p ����
             ,on_price          => ln_price                                -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_4>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).apr_quant     :=
               gr_add_total(r).apr_quant     + TO_NUMBER(gr_sale_plan(i).quant);        -- ����
            gr_add_total(r).apr_amount    :=
               gr_add_total(r).apr_amount    + TO_NUMBER(gr_sale_plan(i).amount);       -- ���z
            gr_add_total(r).apr_price     :=
               gr_add_total(r).apr_price     + ln_price;                                -- �i�ڒ艿
            gr_add_total(r).apr_to_amount :=
               gr_add_total(r).apr_to_amount + TO_NUMBER(gr_sale_plan(i).total_amount); -- ���󍇌v
            gr_add_total(r).apr_quant_t   :=
               gr_add_total(r).apr_quant_t   + ln_quant;                                -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).apr_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).apr_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).apr_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).apr_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan(i).total_amount) * TO_NUMBER(gr_sale_plan(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan(i).quant) < 0 ) THEN
              gr_add_total(r).apr_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).apr_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_4;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(12).tag_name := gv_name_apr;
          gr_xml_out(12).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(12).tag_name := gv_name_apr;
        END IF;
--
        ----------------------------------------------
        -- (�S���_)�u���C�N�L�[�X�V                 --
        ----------------------------------------------
        lv_dtl_break := gr_sale_plan(i).item_no;
--
      END LOOP main_data_loop;
--
      -- =====================================================
      -- (�S���_)�I������
      -- =====================================================
      ---------------------------------------------------------------
      -- (�S���_)�e�����o�f�[�^�����݂��Ȃ��ꍇ�A0�\���ɂ�XML�o��  --
      ---------------------------------------------------------------
      <<xml_out_0_loop>>
      FOR m IN 1..12 LOOP
        IF (gr_xml_out(m).out_fg = lv_no) THEN
          prc_create_xml_data_dtl_n
            (
              iv_label_name     => gr_xml_out(m).tag_name                      -- �o�̓^�O��
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END LOOP xml_out_0_loop;
--
      -- -----------------------------------------------------
      -- (�S���_)�N�v ���ʃf�[�^
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
      -- -----------------------------------------------------
      -- (�S���_)�N�v ���z�f�[�^
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
      -- -----------------------------------------------------
      -- (�S���_)�N�v �e�����f�[�^
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
      ----------------------------------------------
      -- (�S���_)�e���v�Z (���z�|���󍇌v������)  --
      ----------------------------------------------
      ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
      -- �O���Z��𔻒�
      IF (ln_year_amount_sum <> gn_0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        gt_xml_data_table(gl_xml_idx).tag_value := 
                  ROUND((ln_arari / ln_year_amount_sum * 100),2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
      END IF;
--
      -- -----------------------------------------------------
      -- (�S���_)�N�v �|���f�[�^
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
      --------------------------------------
      -- �O���Z���荀�ڂ֔���l��}��     --
      --------------------------------------
      ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
      -- �O���Z��𔻒�
      IF (ln_chk_0 <> gn_0) THEN
      -- �l��[0]�o�Ȃ���Όv�Z
      ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_kake_par := gn_0;
      END IF;
--
      -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
      IF ((ln_year_price_sum = 0)
        OR (ln_kake_par < 0)) THEN
        ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
      END IF;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
      -- �e�W�v���ڂփf�[�^�}��
      <<add_total_loop>>
      FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
        gr_add_total(r).year_quant     :=
           gr_add_total(r).year_quant     + ln_year_quant_sum;        -- ����
        gr_add_total(r).year_amount    :=
           gr_add_total(r).year_amount    + ln_year_amount_sum;       -- ���z
        gr_add_total(r).year_price     :=
           gr_add_total(r).year_price     + ln_year_price_sum;        -- �i�ڒ艿
        gr_add_total(r).year_to_amount :=
           gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- ���󍇌v
        gr_add_total(r).year_quant_t   :=
           gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- ����(�v)
--
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        -- ���ʂ��}�C�i�X�̏ꍇ(�N�Ԃł̑��݃`�F�b�N)
        IF ( ln_year_quant_sum < 0 ) THEN
          gr_add_total(r).year_minus_flg := 'Y';
        END IF;
--
        -- �i�ڒ艿��0�̏ꍇ(�N�Ԃł̑��݃`�F�b�N)
        IF ( ln_year_price_sum = 0 ) THEN
          gr_add_total(r).year_ht_zero_flg := 'Y';
        END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
      END LOOP add_total_loop;
--
      -- -----------------------------------------------------
      -- (�S���_)�i�ڏI���f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (�S���_)�i�ڏI���k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
      --------------------------------------------------------
      -- ���Q�v�f�[�^�^�O�o�� 
      --------------------------------------------------------
      prc_create_xml_data_st_lt
      (
        iv_label_name     => gv_name_st                     -- ���Q�v�p�^�O��
        ,iv_name           => gv_label_st                    -- ���Q�v�^�C�g��
        ,in_may_quant      => gr_add_total(1).may_quant      -- �T�� ����
        ,in_may_amount     => gr_add_total(1).may_amount     -- �T�� ���z
        ,in_may_price      => gr_add_total(1).may_price      -- �T�� �i�ڒ艿
        ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- �T�� ���󍇌v
        ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_may_s_cost     => gr_add_total(1).may_s_cost     -- �T�� �W������(�v�Z�p)
        ,in_may_calc       => gr_add_total(1).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
        ,in_may_minus_flg   => gr_add_total(1).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_may_ht_zero_flg => gr_add_total(1).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jun_quant      => gr_add_total(1).jun_quant      -- �U�� ����
        ,in_jun_amount     => gr_add_total(1).jun_amount     -- �U�� ���z
        ,in_jun_price      => gr_add_total(1).jun_price      -- �U�� �i�ڒ艿
        ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- �U�� ���󍇌v
        ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jun_s_cost     => gr_add_total(1).jun_s_cost     -- �U�� �W������(�v�Z�p)
        ,in_jun_calc       => gr_add_total(1).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
        ,in_jun_minus_flg   => gr_add_total(1).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jun_ht_zero_flg => gr_add_total(1).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jul_quant      => gr_add_total(1).jul_quant      -- �V�� ����
        ,in_jul_amount     => gr_add_total(1).jul_amount     -- �V�� ���z
        ,in_jul_price      => gr_add_total(1).jul_price      -- �V�� �i�ڒ艿
        ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- �V�� ���󍇌v
        ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jul_s_cost     => gr_add_total(1).jul_s_cost     -- �V�� �W������(�v�Z�p)
        ,in_jul_calc       => gr_add_total(1).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
        ,in_jul_minus_flg   => gr_add_total(1).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jul_ht_zero_flg => gr_add_total(1).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_aug_quant      => gr_add_total(1).aug_quant      -- �W�� ����
        ,in_aug_amount     => gr_add_total(1).aug_amount     -- �W�� ���z
        ,in_aug_price      => gr_add_total(1).aug_price      -- �W�� �i�ڒ艿
        ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- �W�� ���󍇌v
        ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_aug_s_cost     => gr_add_total(1).aug_s_cost     -- �W�� �W������(�v�Z�p)
        ,in_aug_calc       => gr_add_total(1).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
        ,in_aug_minus_flg   => gr_add_total(1).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_aug_ht_zero_flg => gr_add_total(1).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_sep_quant      => gr_add_total(1).sep_quant      -- �X�� ����
        ,in_sep_amount     => gr_add_total(1).sep_amount     -- �X�� ���z
        ,in_sep_price      => gr_add_total(1).sep_price      -- �X�� �i�ڒ艿
        ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- �X�� ���󍇌v
        ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_sep_s_cost     => gr_add_total(1).sep_s_cost     -- �X�� �W������(�v�Z�p)
        ,in_sep_calc       => gr_add_total(1).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
        ,in_sep_minus_flg   => gr_add_total(1).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_sep_ht_zero_flg => gr_add_total(1).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_oct_quant      => gr_add_total(1).oct_quant      -- �P�O�� ����
        ,in_oct_amount     => gr_add_total(1).oct_amount     -- �P�O�� ���z
        ,in_oct_price      => gr_add_total(1).oct_price      -- �P�O�� �i�ڒ艿
        ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- �P�O�� ���󍇌v
        ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_oct_s_cost     => gr_add_total(1).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
        ,in_oct_calc       => gr_add_total(1).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
        ,in_oct_minus_flg   => gr_add_total(1).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_oct_ht_zero_flg => gr_add_total(1).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_nov_quant      => gr_add_total(1).nov_quant      -- �P�P�� ����
        ,in_nov_amount     => gr_add_total(1).nov_amount     -- �P�P�� ���z
        ,in_nov_price      => gr_add_total(1).nov_price      -- �P�P�� �i�ڒ艿
        ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- �P�P�� ���󍇌v
        ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_nov_s_cost     => gr_add_total(1).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
        ,in_nov_calc       => gr_add_total(1).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
        ,in_nov_minus_flg   => gr_add_total(1).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_nov_ht_zero_flg => gr_add_total(1).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_dec_quant      => gr_add_total(1).dec_quant      -- �P�Q�� ����
        ,in_dec_amount     => gr_add_total(1).dec_amount     -- �P�Q�� ���z
        ,in_dec_price      => gr_add_total(1).dec_price      -- �P�Q�� �i�ڒ艿
        ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- �P�Q�� ���󍇌v
        ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_dec_s_cost     => gr_add_total(1).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
        ,in_dec_calc       => gr_add_total(1).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
        ,in_dec_minus_flg   => gr_add_total(1).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_dec_ht_zero_flg => gr_add_total(1).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jan_quant      => gr_add_total(1).jan_quant      -- �P�� ����
        ,in_jan_amount     => gr_add_total(1).jan_amount     -- �P�� ���z
        ,in_jan_price      => gr_add_total(1).jan_price      -- �P�� �i�ڒ艿
        ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- �P�� ���󍇌v
        ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jan_s_cost     => gr_add_total(1).jan_s_cost     -- �P�� �W������(�v�Z�p)
        ,in_jan_calc       => gr_add_total(1).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
        ,in_jan_minus_flg   => gr_add_total(1).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jan_ht_zero_flg => gr_add_total(1).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_feb_quant      => gr_add_total(1).feb_quant      -- �Q�� ����
        ,in_feb_amount     => gr_add_total(1).feb_amount     -- �Q�� ���z
        ,in_feb_price      => gr_add_total(1).feb_price      -- �Q�� �i�ڒ艿
        ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- �Q�� ���󍇌v
        ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_feb_s_cost     => gr_add_total(1).feb_s_cost     -- �Q�� �W������(�v�Z�p)
        ,in_feb_calc       => gr_add_total(1).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
        ,in_feb_minus_flg   => gr_add_total(1).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_feb_ht_zero_flg => gr_add_total(1).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_mar_quant      => gr_add_total(1).mar_quant      -- �R�� ����
        ,in_mar_amount     => gr_add_total(1).mar_amount     -- �R�� ���z
        ,in_mar_price      => gr_add_total(1).mar_price      -- �R�� �i�ڒ艿
        ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- �R�� ���󍇌v
        ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_mar_s_cost     => gr_add_total(1).mar_s_cost     -- �R�� �W������(�v�Z�p)
        ,in_mar_calc       => gr_add_total(1).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
        ,in_mar_minus_flg   => gr_add_total(1).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_mar_ht_zero_flg => gr_add_total(1).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_apr_quant      => gr_add_total(1).apr_quant      -- �S�� ����
        ,in_apr_amount     => gr_add_total(1).apr_amount     -- �S�� ���z
        ,in_apr_price      => gr_add_total(1).apr_price      -- �S�� �i�ڒ艿
        ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- �S�� ���󍇌v
        ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_apr_s_cost     => gr_add_total(1).apr_s_cost     -- �S�� �W������(�v�Z�p)
        ,in_apr_calc       => gr_add_total(1).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
        ,in_apr_minus_flg   => gr_add_total(1).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_apr_ht_zero_flg => gr_add_total(1).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_year_quant     => gr_add_total(1).year_quant     -- �N�v ����
        ,in_year_amount    => gr_add_total(1).year_amount    -- �N�v ���z
        ,in_year_price     => gr_add_total(1).year_price     -- �N�v �i�ڒ艿
        ,in_year_to_amount => gr_add_total(1).year_to_amount -- �N�v ���󍇌v
        ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_year_s_cost    => gr_add_total(1).year_s_cost    -- �N�v �W������(�v�Z�p)
        ,in_year_calc      => gr_add_total(1).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
        ,in_year_minus_flg   => gr_add_total(1).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_year_ht_zero_flg => gr_add_total(1).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      --------------------------------------------------------
      -- ��Q�v�f�[�^�^�O�o�� 
      --------------------------------------------------------
      prc_create_xml_data_st_lt
      (
         iv_label_name     => gv_name_lt                     -- ��Q�v�p�^�O��
        ,iv_name           => gv_label_lt                    -- ��Q�v�^�C�g��
        ,in_may_quant      => gr_add_total(2).may_quant      -- �T�� ����
        ,in_may_amount     => gr_add_total(2).may_amount     -- �T�� ���z
        ,in_may_price      => gr_add_total(2).may_price      -- �T�� �i�ڒ艿
        ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- �T�� ���󍇌v
        ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_may_s_cost     => gr_add_total(2).may_s_cost     -- �T�� �W������(�v�Z�p)
        ,in_may_calc       => gr_add_total(2).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
        ,in_may_minus_flg   => gr_add_total(2).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_may_ht_zero_flg => gr_add_total(2).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jun_quant      => gr_add_total(2).jun_quant      -- �U�� ����
        ,in_jun_amount     => gr_add_total(2).jun_amount     -- �U�� ���z
        ,in_jun_price      => gr_add_total(2).jun_price      -- �U�� �i�ڒ艿
        ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- �U�� ���󍇌v
        ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jun_s_cost     => gr_add_total(2).jun_s_cost     -- �U�� �W������(�v�Z�p)
        ,in_jun_calc       => gr_add_total(2).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
        ,in_jun_minus_flg   => gr_add_total(2).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jun_ht_zero_flg => gr_add_total(2).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jul_quant      => gr_add_total(2).jul_quant      -- �V�� ����
        ,in_jul_amount     => gr_add_total(2).jul_amount     -- �V�� ���z
        ,in_jul_price      => gr_add_total(2).jul_price      -- �V�� �i�ڒ艿
        ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- �V�� ���󍇌v
        ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jul_s_cost     => gr_add_total(2).jul_s_cost     -- �V�� �W������(�v�Z�p)
        ,in_jul_calc       => gr_add_total(2).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
        ,in_jul_minus_flg   => gr_add_total(2).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jul_ht_zero_flg => gr_add_total(2).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_aug_quant      => gr_add_total(2).aug_quant      -- �W�� ����
        ,in_aug_amount     => gr_add_total(2).aug_amount     -- �W�� ���z
        ,in_aug_price      => gr_add_total(2).aug_price      -- �W�� �i�ڒ艿
        ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- �W�� ���󍇌v
        ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_aug_s_cost     => gr_add_total(2).aug_s_cost     -- �W�� �W������(�v�Z�p)
        ,in_aug_calc       => gr_add_total(2).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
        ,in_aug_minus_flg   => gr_add_total(2).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_aug_ht_zero_flg => gr_add_total(2).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_sep_quant      => gr_add_total(2).sep_quant      -- �X�� ����
        ,in_sep_amount     => gr_add_total(2).sep_amount     -- �X�� ���z
        ,in_sep_price      => gr_add_total(2).sep_price      -- �X�� �i�ڒ艿
        ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- �X�� ���󍇌v
        ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_sep_s_cost     => gr_add_total(2).sep_s_cost     -- �X�� �W������(�v�Z�p)
        ,in_sep_calc       => gr_add_total(2).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
        ,in_sep_minus_flg   => gr_add_total(2).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_sep_ht_zero_flg => gr_add_total(2).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_oct_quant      => gr_add_total(2).oct_quant      -- �P�O�� ����
        ,in_oct_amount     => gr_add_total(2).oct_amount     -- �P�O�� ���z
        ,in_oct_price      => gr_add_total(2).oct_price      -- �P�O�� �i�ڒ艿
        ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- �P�O�� ���󍇌v
        ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_oct_s_cost     => gr_add_total(2).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
        ,in_oct_calc       => gr_add_total(2).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
        ,in_oct_minus_flg   => gr_add_total(2).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_oct_ht_zero_flg => gr_add_total(2).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_nov_quant      => gr_add_total(2).nov_quant      -- �P�P�� ����
        ,in_nov_amount     => gr_add_total(2).nov_amount     -- �P�P�� ���z
        ,in_nov_price      => gr_add_total(2).nov_price      -- �P�P�� �i�ڒ艿
        ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- �P�P�� ���󍇌v
        ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_nov_s_cost     => gr_add_total(2).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
        ,in_nov_calc       => gr_add_total(2).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
        ,in_nov_minus_flg   => gr_add_total(2).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_nov_ht_zero_flg => gr_add_total(2).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_dec_quant      => gr_add_total(2).dec_quant      -- �P�Q�� ����
        ,in_dec_amount     => gr_add_total(2).dec_amount     -- �P�Q�� ���z
        ,in_dec_price      => gr_add_total(2).dec_price      -- �P�Q�� �i�ڒ艿
        ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- �P�Q�� ���󍇌v
        ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_dec_s_cost     => gr_add_total(2).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
        ,in_dec_calc       => gr_add_total(2).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
        ,in_dec_minus_flg   => gr_add_total(2).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_dec_ht_zero_flg => gr_add_total(2).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jan_quant      => gr_add_total(2).jan_quant      -- �P�� ����
        ,in_jan_amount     => gr_add_total(2).jan_amount     -- �P�� ���z
        ,in_jan_price      => gr_add_total(2).jan_price      -- �P�� �i�ڒ艿
        ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- �P�� ���󍇌v
        ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jan_s_cost     => gr_add_total(2).jan_s_cost     -- �P�� �W������(�v�Z�p)
        ,in_jan_calc       => gr_add_total(2).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
        ,in_jan_minus_flg   => gr_add_total(2).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jan_ht_zero_flg => gr_add_total(2).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_feb_quant      => gr_add_total(2).feb_quant      -- �Q�� ����
        ,in_feb_amount     => gr_add_total(2).feb_amount     -- �Q�� ���z
        ,in_feb_price      => gr_add_total(2).feb_price      -- �Q�� �i�ڒ艿
        ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- �Q�� ���󍇌v
        ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_feb_s_cost     => gr_add_total(2).feb_s_cost     -- �Q�� �W������(�v�Z�p)
        ,in_feb_calc       => gr_add_total(2).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
        ,in_feb_minus_flg   => gr_add_total(2).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_feb_ht_zero_flg => gr_add_total(2).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_mar_quant      => gr_add_total(2).mar_quant      -- �R�� ����
        ,in_mar_amount     => gr_add_total(2).mar_amount     -- �R�� ���z
        ,in_mar_price      => gr_add_total(2).mar_price      -- �R�� �i�ڒ艿
        ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- �R�� ���󍇌v
        ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_mar_s_cost     => gr_add_total(2).mar_s_cost     -- �R�� �W������(�v�Z�p)
        ,in_mar_calc       => gr_add_total(2).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
        ,in_mar_minus_flg   => gr_add_total(2).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_mar_ht_zero_flg => gr_add_total(2).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_apr_quant      => gr_add_total(2).apr_quant      -- �S�� ����
        ,in_apr_amount     => gr_add_total(2).apr_amount     -- �S�� ���z
        ,in_apr_price      => gr_add_total(2).apr_price      -- �S�� �i�ڒ艿
        ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- �S�� ���󍇌v
        ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_apr_s_cost     => gr_add_total(2).apr_s_cost     -- �S�� �W������(�v�Z�p)
        ,in_apr_calc       => gr_add_total(2).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
        ,in_apr_minus_flg   => gr_add_total(2).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_apr_ht_zero_flg => gr_add_total(2).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_year_quant     => gr_add_total(2).year_quant     -- �N�v ����
        ,in_year_amount    => gr_add_total(2).year_amount    -- �N�v ���z
        ,in_year_price     => gr_add_total(2).year_price     -- �N�v �i�ڒ艿
        ,in_year_to_amount => gr_add_total(2).year_to_amount -- �N�v ���󍇌v
        ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_year_s_cost    => gr_add_total(2).year_s_cost    -- �N�v �W������(�v�Z�p)
        ,in_year_calc      => gr_add_total(2).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
        ,in_year_minus_flg   => gr_add_total(2).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_year_ht_zero_flg => gr_add_total(2).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
*/
--
      --------------------------------------------------------
      -- (�S���_)(1)���Q�v/(2)��Q�v�f�[�^�o�� 
      --------------------------------------------------------
      <<gun_loop>>
      FOR n IN 1..2 LOOP        -- ���Q�v/��Q�v
--
        -- ���Q�v�̏ꍇ
        IF ( n = 1) THEN
          lv_param_name  := gv_name_st;
          lv_param_label := gv_label_st;
        -- ��Q�v�̏ꍇ
        ELSE
          lv_param_name  := gv_name_lt;
          lv_param_label := gv_label_lt;
        END IF;
--
        prc_create_xml_data_st_lt
        (
            iv_label_name      => lv_param_name                   -- ��Q�v�p�^�O��
          ,iv_name            => lv_param_label                  -- ��Q�v�^�C�g��
          ,in_may_quant       => gr_add_total(n).may_quant       -- �T�� ����
          ,in_may_amount      => gr_add_total(n).may_amount      -- �T�� ���z
          ,in_may_price       => gr_add_total(n).may_price       -- �T�� �i�ڒ艿
          ,in_may_to_amount   => gr_add_total(n).may_to_amount   -- �T�� ���󍇌v
          ,in_may_quant_t     => gr_add_total(n).may_quant_t     -- �T�� ����(�v�Z�p)
          ,in_may_s_cost      => gr_add_total(n).may_s_cost      -- �T�� �W������(�v�Z�p)
          ,in_may_calc        => gr_add_total(n).may_calc        -- �T�� �i�ڒ艿*����(�v�Z�p)
          ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
          ,in_jun_quant       => gr_add_total(n).jun_quant       -- �U�� ����
          ,in_jun_amount      => gr_add_total(n).jun_amount      -- �U�� ���z
          ,in_jun_price       => gr_add_total(n).jun_price       -- �U�� �i�ڒ艿
          ,in_jun_to_amount   => gr_add_total(n).jun_to_amount   -- �U�� ���󍇌v
          ,in_jun_quant_t     => gr_add_total(n).jun_quant_t     -- �U�� ����(�v�Z�p)
          ,in_jun_s_cost      => gr_add_total(n).jun_s_cost      -- �U�� �W������(�v�Z�p)
          ,in_jun_calc        => gr_add_total(n).jun_calc        -- �U�� �i�ڒ艿*����(�v�Z�p)
          ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
          ,in_jul_quant       => gr_add_total(n).jul_quant       -- �V�� ����
          ,in_jul_amount      => gr_add_total(n).jul_amount      -- �V�� ���z
          ,in_jul_price       => gr_add_total(n).jul_price       -- �V�� �i�ڒ艿
          ,in_jul_to_amount   => gr_add_total(n).jul_to_amount   -- �V�� ���󍇌v
          ,in_jul_quant_t     => gr_add_total(n).jul_quant_t     -- �V�� ����(�v�Z�p)
          ,in_jul_s_cost      => gr_add_total(n).jul_s_cost      -- �V�� �W������(�v�Z�p)
          ,in_jul_calc        => gr_add_total(n).jul_calc        -- �V�� �i�ڒ艿*����(�v�Z�p)
          ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
          ,in_aug_quant       => gr_add_total(n).aug_quant       -- �W�� ����
          ,in_aug_amount      => gr_add_total(n).aug_amount      -- �W�� ���z
          ,in_aug_price       => gr_add_total(n).aug_price       -- �W�� �i�ڒ艿
          ,in_aug_to_amount   => gr_add_total(n).aug_to_amount   -- �W�� ���󍇌v
          ,in_aug_quant_t     => gr_add_total(n).aug_quant_t     -- �W�� ����(�v�Z�p)
          ,in_aug_s_cost      => gr_add_total(n).aug_s_cost      -- �W�� �W������(�v�Z�p)
          ,in_aug_calc        => gr_add_total(n).aug_calc        -- �W�� �i�ڒ艿*����(�v�Z�p)
          ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
          ,in_sep_quant       => gr_add_total(n).sep_quant       -- �X�� ����
          ,in_sep_amount      => gr_add_total(n).sep_amount      -- �X�� ���z
          ,in_sep_price       => gr_add_total(n).sep_price       -- �X�� �i�ڒ艿
          ,in_sep_to_amount   => gr_add_total(n).sep_to_amount   -- �X�� ���󍇌v
          ,in_sep_quant_t     => gr_add_total(n).sep_quant_t     -- �X�� ����(�v�Z�p)
          ,in_sep_s_cost      => gr_add_total(n).sep_s_cost      -- �X�� �W������(�v�Z�p)
          ,in_sep_calc        => gr_add_total(n).sep_calc        -- �X�� �i�ڒ艿*����(�v�Z�p)
          ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
          ,in_oct_quant       => gr_add_total(n).oct_quant       -- �P�O�� ����
          ,in_oct_amount      => gr_add_total(n).oct_amount      -- �P�O�� ���z
          ,in_oct_price       => gr_add_total(n).oct_price       -- �P�O�� �i�ڒ艿
          ,in_oct_to_amount   => gr_add_total(n).oct_to_amount   -- �P�O�� ���󍇌v
          ,in_oct_quant_t     => gr_add_total(n).oct_quant_t     -- �P�O�� ����(�v�Z�p)
          ,in_oct_s_cost      => gr_add_total(n).oct_s_cost      -- �P�O�� �W������(�v�Z�p)
          ,in_oct_calc        => gr_add_total(n).oct_calc        -- �P�O�� �i�ڒ艿*����(�v�Z�p)
          ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
          ,in_nov_quant       => gr_add_total(n).nov_quant       -- �P�P�� ����
          ,in_nov_amount      => gr_add_total(n).nov_amount      -- �P�P�� ���z
          ,in_nov_price       => gr_add_total(n).nov_price       -- �P�P�� �i�ڒ艿
          ,in_nov_to_amount   => gr_add_total(n).nov_to_amount   -- �P�P�� ���󍇌v
          ,in_nov_quant_t     => gr_add_total(n).nov_quant_t     -- �P�P�� ����(�v�Z�p)
          ,in_nov_s_cost      => gr_add_total(n).nov_s_cost      -- �P�P�� �W������(�v�Z�p)
          ,in_nov_calc        => gr_add_total(n).nov_calc        -- �P�P�� �i�ڒ艿*����(�v�Z�p)
          ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
          ,in_dec_quant       => gr_add_total(n).dec_quant       -- �P�Q�� ����
          ,in_dec_amount      => gr_add_total(n).dec_amount      -- �P�Q�� ���z
          ,in_dec_price       => gr_add_total(n).dec_price       -- �P�Q�� �i�ڒ艿
          ,in_dec_to_amount   => gr_add_total(n).dec_to_amount   -- �P�Q�� ���󍇌v
          ,in_dec_quant_t     => gr_add_total(n).dec_quant_t     -- �P�Q�� ����(�v�Z�p)
          ,in_dec_s_cost      => gr_add_total(n).dec_s_cost      -- �P�Q�� �W������(�v�Z�p)
          ,in_dec_calc        => gr_add_total(n).dec_calc        -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
          ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
          ,in_jan_quant       => gr_add_total(n).jan_quant       -- �P�� ����
          ,in_jan_amount      => gr_add_total(n).jan_amount      -- �P�� ���z
          ,in_jan_price       => gr_add_total(n).jan_price       -- �P�� �i�ڒ艿
          ,in_jan_to_amount   => gr_add_total(n).jan_to_amount   -- �P�� ���󍇌v
          ,in_jan_quant_t     => gr_add_total(n).jan_quant_t     -- �P�� ����(�v�Z�p)
          ,in_jan_s_cost      => gr_add_total(n).jan_s_cost      -- �P�� �W������(�v�Z�p)
          ,in_jan_calc        => gr_add_total(n).jan_calc        -- �P�� �i�ڒ艿*����(�v�Z�p)
          ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
          ,in_feb_quant       => gr_add_total(n).feb_quant       -- �Q�� ����
          ,in_feb_amount      => gr_add_total(n).feb_amount      -- �Q�� ���z
          ,in_feb_price       => gr_add_total(n).feb_price       -- �Q�� �i�ڒ艿
          ,in_feb_to_amount   => gr_add_total(n).feb_to_amount   -- �Q�� ���󍇌v
          ,in_feb_quant_t     => gr_add_total(n).feb_quant_t     -- �Q�� ����(�v�Z�p)
          ,in_feb_s_cost      => gr_add_total(n).feb_s_cost      -- �Q�� �W������(�v�Z�p)
          ,in_feb_calc        => gr_add_total(n).feb_calc        -- �Q�� �i�ڒ艿*����(�v�Z�p)
          ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
          ,in_mar_quant       => gr_add_total(n).mar_quant       -- �R�� ����
          ,in_mar_amount      => gr_add_total(n).mar_amount      -- �R�� ���z
          ,in_mar_price       => gr_add_total(n).mar_price       -- �R�� �i�ڒ艿
          ,in_mar_to_amount   => gr_add_total(n).mar_to_amount   -- �R�� ���󍇌v
          ,in_mar_quant_t     => gr_add_total(n).mar_quant_t     -- �R�� ����(�v�Z�p)
          ,in_mar_s_cost      => gr_add_total(n).mar_s_cost      -- �R�� �W������(�v�Z�p)
          ,in_mar_calc        => gr_add_total(n).mar_calc        -- �R�� �i�ڒ艿*����(�v�Z�p)
          ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
          ,in_apr_quant       => gr_add_total(n).apr_quant       -- �S�� ����
          ,in_apr_amount      => gr_add_total(n).apr_amount      -- �S�� ���z
          ,in_apr_price       => gr_add_total(n).apr_price       -- �S�� �i�ڒ艿
          ,in_apr_to_amount   => gr_add_total(n).apr_to_amount   -- �S�� ���󍇌v
          ,in_apr_quant_t     => gr_add_total(n).apr_quant_t     -- �S�� ����(�v�Z�p)
          ,in_apr_s_cost      => gr_add_total(n).apr_s_cost      -- �S�� �W������(�v�Z�p)
          ,in_apr_calc        => gr_add_total(n).apr_calc        -- �S�� �i�ڒ艿*����(�v�Z�p)
          ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
          ,in_year_quant      => gr_add_total(n).year_quant        -- �N�v ����
          ,in_year_amount     => gr_add_total(n).year_amount       -- �N�v ���z
          ,in_year_price      => gr_add_total(n).year_price        -- �N�v �i�ڒ艿
          ,in_year_to_amount  => gr_add_total(n).year_to_amount    -- �N�v ���󍇌v
          ,in_year_quant_t    => gr_add_total(n).year_quant_t      -- �N�v ����(�v�Z�p)
          ,in_year_s_cost     => gr_add_total(n).year_s_cost       -- �N�v �W������(�v�Z�p)
          ,in_year_calc       => gr_add_total(n).year_calc         -- �N�v �i�ڒ艿*����(�v�Z�p)
          ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
          ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP gun_loop;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
      -- -----------------------------------------------------
      -- (�S���_)�Q�R�[�h�I���f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (�S���_)�Q�R�[�h�I���k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
      --------------------------------------------------------
      -- ���_�v�f�[�^�^�O�o�� 
      --------------------------------------------------------
      prc_create_xml_data_s_k_t
      (
         iv_label_name     => gv_name_ktn                    -- ���_�v�p�^�O��
        ,in_may_quant      => gr_add_total(3).may_quant      -- �T�� ����
        ,in_may_amount     => gr_add_total(3).may_amount     -- �T�� ���z
        ,in_may_price      => gr_add_total(3).may_price      -- �T�� �i�ڒ艿
        ,in_may_to_amount  => gr_add_total(3).may_to_amount  -- �T�� ���󍇌v
        ,in_may_quant_t    => gr_add_total(3).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_may_s_cost     => gr_add_total(3).may_s_cost     -- �T�� �W������(�v�Z�p)
        ,in_may_calc       => gr_add_total(3).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
        ,in_may_minus_flg   => gr_add_total(3).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_may_ht_zero_flg => gr_add_total(3).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jun_quant      => gr_add_total(3).jun_quant      -- �U�� ����
        ,in_jun_amount     => gr_add_total(3).jun_amount     -- �U�� ���z
        ,in_jun_price      => gr_add_total(3).jun_price      -- �U�� �i�ڒ艿
        ,in_jun_to_amount  => gr_add_total(3).jun_to_amount  -- �U�� ���󍇌v
        ,in_jun_quant_t    => gr_add_total(3).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jun_s_cost     => gr_add_total(3).jun_s_cost     -- �U�� �W������(�v�Z�p)
        ,in_jun_calc       => gr_add_total(3).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
        ,in_jun_minus_flg   => gr_add_total(3).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jun_ht_zero_flg => gr_add_total(3).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jul_quant      => gr_add_total(3).jul_quant      -- �V�� ����
        ,in_jul_amount     => gr_add_total(3).jul_amount     -- �V�� ���z
        ,in_jul_price      => gr_add_total(3).jul_price      -- �V�� �i�ڒ艿
        ,in_jul_to_amount  => gr_add_total(3).jul_to_amount  -- �V�� ���󍇌v
        ,in_jul_quant_t    => gr_add_total(3).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jul_s_cost     => gr_add_total(3).jul_s_cost     -- �V�� �W������(�v�Z�p)
        ,in_jul_calc       => gr_add_total(3).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
        ,in_jul_minus_flg   => gr_add_total(3).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jul_ht_zero_flg => gr_add_total(3).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_aug_quant      => gr_add_total(3).aug_quant      -- �W�� ����
        ,in_aug_amount     => gr_add_total(3).aug_amount     -- �W�� ���z
        ,in_aug_price      => gr_add_total(3).aug_price      -- �W�� �i�ڒ艿
        ,in_aug_to_amount  => gr_add_total(3).aug_to_amount  -- �W�� ���󍇌v
        ,in_aug_quant_t    => gr_add_total(3).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_aug_s_cost     => gr_add_total(3).aug_s_cost     -- �W�� �W������(�v�Z�p)
        ,in_aug_calc       => gr_add_total(3).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
        ,in_aug_minus_flg   => gr_add_total(3).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_aug_ht_zero_flg => gr_add_total(3).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_sep_quant      => gr_add_total(3).sep_quant      -- �X�� ����
        ,in_sep_amount     => gr_add_total(3).sep_amount     -- �X�� ���z
        ,in_sep_price      => gr_add_total(3).sep_price      -- �X�� �i�ڒ艿
        ,in_sep_to_amount  => gr_add_total(3).sep_to_amount  -- �X�� ���󍇌v
        ,in_sep_quant_t    => gr_add_total(3).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_sep_s_cost     => gr_add_total(3).sep_s_cost     -- �X�� �W������(�v�Z�p)
        ,in_sep_calc       => gr_add_total(3).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
        ,in_sep_minus_flg   => gr_add_total(3).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_sep_ht_zero_flg => gr_add_total(3).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_oct_quant      => gr_add_total(3).oct_quant      -- �P�O�� ����
        ,in_oct_amount     => gr_add_total(3).oct_amount     -- �P�O�� ���z
        ,in_oct_price      => gr_add_total(3).oct_price      -- �P�O�� �i�ڒ艿
        ,in_oct_to_amount  => gr_add_total(3).oct_to_amount  -- �P�O�� ���󍇌v
        ,in_oct_quant_t    => gr_add_total(3).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_oct_s_cost     => gr_add_total(3).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
        ,in_oct_calc       => gr_add_total(3).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
        ,in_oct_minus_flg   => gr_add_total(3).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_oct_ht_zero_flg => gr_add_total(3).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_nov_quant      => gr_add_total(3).nov_quant      -- �P�P�� ����
        ,in_nov_amount     => gr_add_total(3).nov_amount     -- �P�P�� ���z
        ,in_nov_price      => gr_add_total(3).nov_price      -- �P�P�� �i�ڒ艿
        ,in_nov_to_amount  => gr_add_total(3).nov_to_amount  -- �P�P�� ���󍇌v
        ,in_nov_quant_t    => gr_add_total(3).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_nov_s_cost     => gr_add_total(3).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
        ,in_nov_calc       => gr_add_total(3).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
        ,in_nov_minus_flg   => gr_add_total(3).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_nov_ht_zero_flg => gr_add_total(3).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_dec_quant      => gr_add_total(3).dec_quant      -- �P�Q�� ����
        ,in_dec_amount     => gr_add_total(3).dec_amount     -- �P�Q�� ���z
        ,in_dec_price      => gr_add_total(3).dec_price      -- �P�Q�� �i�ڒ艿
        ,in_dec_to_amount  => gr_add_total(3).dec_to_amount  -- �P�Q�� ���󍇌v
        ,in_dec_quant_t    => gr_add_total(3).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_dec_s_cost     => gr_add_total(3).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
        ,in_dec_calc       => gr_add_total(3).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
        ,in_dec_minus_flg   => gr_add_total(3).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_dec_ht_zero_flg => gr_add_total(3).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jan_quant      => gr_add_total(3).jan_quant      -- �P�� ����
        ,in_jan_amount     => gr_add_total(3).jan_amount     -- �P�� ���z
        ,in_jan_price      => gr_add_total(3).jan_price      -- �P�� �i�ڒ艿
        ,in_jan_to_amount  => gr_add_total(3).jan_to_amount  -- �P�� ���󍇌v
        ,in_jan_quant_t    => gr_add_total(3).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jan_s_cost     => gr_add_total(3).jan_s_cost     -- �P�� �W������(�v�Z�p)
        ,in_jan_calc       => gr_add_total(3).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
        ,in_jan_minus_flg   => gr_add_total(3).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jan_ht_zero_flg => gr_add_total(3).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_feb_quant      => gr_add_total(3).feb_quant      -- �Q�� ����
        ,in_feb_amount     => gr_add_total(3).feb_amount     -- �Q�� ���z
        ,in_feb_price      => gr_add_total(3).feb_price      -- �Q�� �i�ڒ艿
        ,in_feb_to_amount  => gr_add_total(3).feb_to_amount  -- �Q�� ���󍇌v
        ,in_feb_quant_t    => gr_add_total(3).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_feb_s_cost     => gr_add_total(3).feb_s_cost     -- �Q�� �W������(�v�Z�p)
        ,in_feb_calc       => gr_add_total(3).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
        ,in_feb_minus_flg   => gr_add_total(3).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_feb_ht_zero_flg => gr_add_total(3).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_mar_quant      => gr_add_total(3).mar_quant      -- �R�� ����
        ,in_mar_amount     => gr_add_total(3).mar_amount     -- �R�� ���z
        ,in_mar_price      => gr_add_total(3).mar_price      -- �R�� �i�ڒ艿
        ,in_mar_to_amount  => gr_add_total(3).mar_to_amount  -- �R�� ���󍇌v
        ,in_mar_quant_t    => gr_add_total(3).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_mar_s_cost     => gr_add_total(3).mar_s_cost     -- �R�� �W������(�v�Z�p)
        ,in_mar_calc       => gr_add_total(3).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
        ,in_mar_minus_flg   => gr_add_total(3).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_mar_ht_zero_flg => gr_add_total(3).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_apr_quant      => gr_add_total(3).apr_quant      -- �S�� ����
        ,in_apr_amount     => gr_add_total(3).apr_amount     -- �S�� ���z
        ,in_apr_price      => gr_add_total(3).apr_price      -- �S�� �i�ڒ艿
        ,in_apr_to_amount  => gr_add_total(3).apr_to_amount  -- �S�� ���󍇌v
        ,in_apr_quant_t    => gr_add_total(3).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_apr_s_cost     => gr_add_total(3).apr_s_cost     -- �S�� �W������(�v�Z�p)
        ,in_apr_calc       => gr_add_total(3).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
        ,in_apr_minus_flg   => gr_add_total(3).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_apr_ht_zero_flg => gr_add_total(3).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_year_quant     => gr_add_total(3).year_quant     -- �N�v ����
        ,in_year_amount    => gr_add_total(3).year_amount    -- �N�v ���z
        ,in_year_price     => gr_add_total(3).year_price     -- �N�v �i�ڒ艿
        ,in_year_to_amount => gr_add_total(3).year_to_amount -- �N�v ���󍇌v
        ,in_year_quant_t   => gr_add_total(3).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_year_s_cost    => gr_add_total(3).year_s_cost    -- �N�v �W������(�v�Z�p)
        ,in_year_calc      => gr_add_total(3).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
        ,in_year_minus_flg   => gr_add_total(3).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_year_ht_zero_flg => gr_add_total(3).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- -----------------------------------------------------
      --  ���_�I���f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  ���_�I���k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      --------------------------------------------------------
      -- ���i�敪�v�f�[�^�^�O�o�� 
      --------------------------------------------------------
      prc_create_xml_data_s_k_t
      (
          iv_label_name     => gv_name_skbn                   -- ���i�敪�v�p�^�O��
        ,in_may_quant      => gr_add_total(4).may_quant      -- �T�� ����
        ,in_may_amount     => gr_add_total(4).may_amount     -- �T�� ���z
        ,in_may_price      => gr_add_total(4).may_price      -- �T�� �i�ڒ艿
        ,in_may_to_amount  => gr_add_total(4).may_to_amount  -- �T�� ���󍇌v
        ,in_may_quant_t    => gr_add_total(4).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_may_s_cost     => gr_add_total(4).may_s_cost     -- �T�� �W������(�v�Z�p)
        ,in_may_calc       => gr_add_total(4).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
        ,in_may_minus_flg   => gr_add_total(4).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_may_ht_zero_flg => gr_add_total(4).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jun_quant      => gr_add_total(4).jun_quant      -- �U�� ����
        ,in_jun_amount     => gr_add_total(4).jun_amount     -- �U�� ���z
        ,in_jun_price      => gr_add_total(4).jun_price      -- �U�� �i�ڒ艿
        ,in_jun_to_amount  => gr_add_total(4).jun_to_amount  -- �U�� ���󍇌v
        ,in_jun_quant_t    => gr_add_total(4).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jun_s_cost     => gr_add_total(4).jun_s_cost     -- �U�� �W������(�v�Z�p)
        ,in_jun_calc       => gr_add_total(4).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
        ,in_jun_minus_flg   => gr_add_total(4).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jun_ht_zero_flg => gr_add_total(4).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jul_quant      => gr_add_total(4).jul_quant      -- �V�� ����
        ,in_jul_amount     => gr_add_total(4).jul_amount     -- �V�� ���z
        ,in_jul_price      => gr_add_total(4).jul_price      -- �V�� �i�ڒ艿
        ,in_jul_to_amount  => gr_add_total(4).jul_to_amount  -- �V�� ���󍇌v
        ,in_jul_quant_t    => gr_add_total(4).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jul_s_cost     => gr_add_total(4).jul_s_cost     -- �V�� �W������(�v�Z�p)
        ,in_jul_calc       => gr_add_total(4).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
        ,in_jul_minus_flg   => gr_add_total(4).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jul_ht_zero_flg => gr_add_total(4).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_aug_quant      => gr_add_total(4).aug_quant      -- �W�� ����
        ,in_aug_amount     => gr_add_total(4).aug_amount     -- �W�� ���z
        ,in_aug_price      => gr_add_total(4).aug_price      -- �W�� �i�ڒ艿
        ,in_aug_to_amount  => gr_add_total(4).aug_to_amount  -- �W�� ���󍇌v
        ,in_aug_quant_t    => gr_add_total(4).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_aug_s_cost     => gr_add_total(4).aug_s_cost     -- �W�� �W������(�v�Z�p)
        ,in_aug_calc       => gr_add_total(4).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
        ,in_aug_minus_flg   => gr_add_total(4).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_aug_ht_zero_flg => gr_add_total(4).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_sep_quant      => gr_add_total(4).sep_quant      -- �X�� ����
        ,in_sep_amount     => gr_add_total(4).sep_amount     -- �X�� ���z
        ,in_sep_price      => gr_add_total(4).sep_price      -- �X�� �i�ڒ艿
        ,in_sep_to_amount  => gr_add_total(4).sep_to_amount  -- �X�� ���󍇌v
        ,in_sep_quant_t    => gr_add_total(4).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_sep_s_cost     => gr_add_total(4).sep_s_cost     -- �X�� �W������(�v�Z�p)
        ,in_sep_calc       => gr_add_total(4).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
        ,in_sep_minus_flg   => gr_add_total(4).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_sep_ht_zero_flg => gr_add_total(4).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_oct_quant      => gr_add_total(4).oct_quant      -- �P�O�� ����
        ,in_oct_amount     => gr_add_total(4).oct_amount     -- �P�O�� ���z
        ,in_oct_price      => gr_add_total(4).oct_price      -- �P�O�� �i�ڒ艿
        ,in_oct_to_amount  => gr_add_total(4).oct_to_amount  -- �P�O�� ���󍇌v
        ,in_oct_quant_t    => gr_add_total(4).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_oct_s_cost     => gr_add_total(4).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
        ,in_oct_calc       => gr_add_total(4).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
        ,in_oct_minus_flg   => gr_add_total(4).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_oct_ht_zero_flg => gr_add_total(4).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_nov_quant      => gr_add_total(4).nov_quant      -- �P�P�� ����
        ,in_nov_amount     => gr_add_total(4).nov_amount     -- �P�P�� ���z
        ,in_nov_price      => gr_add_total(4).nov_price      -- �P�P�� �i�ڒ艿
        ,in_nov_to_amount  => gr_add_total(4).nov_to_amount  -- �P�P�� ���󍇌v
        ,in_nov_quant_t    => gr_add_total(4).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_nov_s_cost     => gr_add_total(4).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
        ,in_nov_calc       => gr_add_total(4).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
        ,in_nov_minus_flg   => gr_add_total(4).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_nov_ht_zero_flg => gr_add_total(4).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_dec_quant      => gr_add_total(4).dec_quant      -- �P�Q�� ����
        ,in_dec_amount     => gr_add_total(4).dec_amount     -- �P�Q�� ���z
        ,in_dec_price      => gr_add_total(4).dec_price      -- �P�Q�� �i�ڒ艿
        ,in_dec_to_amount  => gr_add_total(4).dec_to_amount  -- �P�Q�� ���󍇌v
        ,in_dec_quant_t    => gr_add_total(4).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_dec_s_cost     => gr_add_total(4).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
        ,in_dec_calc       => gr_add_total(4).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
        ,in_dec_minus_flg   => gr_add_total(4).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_dec_ht_zero_flg => gr_add_total(4).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jan_quant      => gr_add_total(4).jan_quant      -- �P�� ����
        ,in_jan_amount     => gr_add_total(4).jan_amount     -- �P�� ���z
        ,in_jan_price      => gr_add_total(4).jan_price      -- �P�� �i�ڒ艿
        ,in_jan_to_amount  => gr_add_total(4).jan_to_amount  -- �P�� ���󍇌v
        ,in_jan_quant_t    => gr_add_total(4).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jan_s_cost     => gr_add_total(4).jan_s_cost     -- �P�� �W������(�v�Z�p)
        ,in_jan_calc       => gr_add_total(4).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
        ,in_jan_minus_flg   => gr_add_total(4).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jan_ht_zero_flg => gr_add_total(4).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_feb_quant      => gr_add_total(4).feb_quant      -- �Q�� ����
        ,in_feb_amount     => gr_add_total(4).feb_amount     -- �Q�� ���z
        ,in_feb_price      => gr_add_total(4).feb_price      -- �Q�� �i�ڒ艿
        ,in_feb_to_amount  => gr_add_total(4).feb_to_amount  -- �Q�� ���󍇌v
        ,in_feb_quant_t    => gr_add_total(4).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_feb_s_cost     => gr_add_total(4).feb_s_cost     -- �Q�� �W������(�v�Z�p)
        ,in_feb_calc       => gr_add_total(4).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
        ,in_feb_minus_flg   => gr_add_total(4).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_feb_ht_zero_flg => gr_add_total(4).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_mar_quant      => gr_add_total(4).mar_quant      -- �R�� ����
        ,in_mar_amount     => gr_add_total(4).mar_amount     -- �R�� ���z
        ,in_mar_price      => gr_add_total(4).mar_price      -- �R�� �i�ڒ艿
        ,in_mar_to_amount  => gr_add_total(4).mar_to_amount  -- �R�� ���󍇌v
        ,in_mar_quant_t    => gr_add_total(4).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_mar_s_cost     => gr_add_total(4).mar_s_cost     -- �R�� �W������(�v�Z�p)
        ,in_mar_calc       => gr_add_total(4).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
        ,in_mar_minus_flg   => gr_add_total(4).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_mar_ht_zero_flg => gr_add_total(4).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_apr_quant      => gr_add_total(4).apr_quant      -- �S�� ����
        ,in_apr_amount     => gr_add_total(4).apr_amount     -- �S�� ���z
        ,in_apr_price      => gr_add_total(4).apr_price      -- �S�� �i�ڒ艿
        ,in_apr_to_amount  => gr_add_total(4).apr_to_amount  -- �S�� ���󍇌v
        ,in_apr_quant_t    => gr_add_total(4).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_apr_s_cost     => gr_add_total(4).apr_s_cost     -- �S�� �W������(�v�Z�p)
        ,in_apr_calc       => gr_add_total(4).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
        ,in_apr_minus_flg   => gr_add_total(4).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_apr_ht_zero_flg => gr_add_total(4).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_year_quant     => gr_add_total(4).year_quant     -- �N�v ����
        ,in_year_amount    => gr_add_total(4).year_amount    -- �N�v ���z
        ,in_year_price     => gr_add_total(4).year_price     -- �N�v �i�ڒ艿
        ,in_year_to_amount => gr_add_total(4).year_to_amount -- �N�v ���󍇌v
        ,in_year_quant_t   => gr_add_total(4).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_year_s_cost    => gr_add_total(4).year_s_cost    -- �N�v �W������(�v�Z�p)
        ,in_year_calc      => gr_add_total(4).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
        ,in_year_minus_flg   => gr_add_total(4).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_year_ht_zero_flg => gr_add_total(4).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      --------------------------------------------------------
      -- �����v�f�[�^�^�O�o�� 
      --------------------------------------------------------
      prc_create_xml_data_s_k_t
      (
        iv_label_name     => gv_name_ttl                    -- �����v�p�^�O��
        ,in_may_quant      => gr_add_total(5).may_quant      -- �T�� ����
        ,in_may_amount     => gr_add_total(5).may_amount     -- �T�� ���z
        ,in_may_price      => gr_add_total(5).may_price      -- �T�� �i�ڒ艿
        ,in_may_to_amount  => gr_add_total(5).may_to_amount  -- �T�� ���󍇌v
        ,in_may_quant_t    => gr_add_total(5).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_may_s_cost     => gr_add_total(5).may_s_cost     -- �T�� �W������(�v�Z�p)
        ,in_may_calc       => gr_add_total(5).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
        ,in_may_minus_flg   => gr_add_total(5).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_may_ht_zero_flg => gr_add_total(5).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jun_quant      => gr_add_total(5).jun_quant      -- �U�� ����
        ,in_jun_amount     => gr_add_total(5).jun_amount     -- �U�� ���z
        ,in_jun_price      => gr_add_total(5).jun_price      -- �U�� �i�ڒ艿
        ,in_jun_to_amount  => gr_add_total(5).jun_to_amount  -- �U�� ���󍇌v
        ,in_jun_quant_t    => gr_add_total(5).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jun_s_cost     => gr_add_total(5).jun_s_cost     -- �U�� �W������(�v�Z�p)
        ,in_jun_calc       => gr_add_total(5).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
        ,in_jun_minus_flg   => gr_add_total(5).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jun_ht_zero_flg => gr_add_total(5).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jul_quant      => gr_add_total(5).jul_quant      -- �V�� ����
        ,in_jul_amount     => gr_add_total(5).jul_amount     -- �V�� ���z
        ,in_jul_price      => gr_add_total(5).jul_price      -- �V�� �i�ڒ艿
        ,in_jul_to_amount  => gr_add_total(5).jul_to_amount  -- �V�� ���󍇌v
        ,in_jul_quant_t    => gr_add_total(5).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jul_s_cost     => gr_add_total(5).jul_s_cost     -- �V�� �W������(�v�Z�p)
        ,in_jul_calc       => gr_add_total(5).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
        ,in_jul_minus_flg   => gr_add_total(5).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jul_ht_zero_flg => gr_add_total(5).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_aug_quant      => gr_add_total(5).aug_quant      -- �W�� ����
        ,in_aug_amount     => gr_add_total(5).aug_amount     -- �W�� ���z
        ,in_aug_price      => gr_add_total(5).aug_price      -- �W�� �i�ڒ艿
        ,in_aug_to_amount  => gr_add_total(5).aug_to_amount  -- �W�� ���󍇌v
        ,in_aug_quant_t    => gr_add_total(5).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_aug_s_cost     => gr_add_total(5).aug_s_cost     -- �W�� �W������(�v�Z�p)
        ,in_aug_calc       => gr_add_total(5).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
        ,in_aug_minus_flg   => gr_add_total(5).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_aug_ht_zero_flg => gr_add_total(5).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_sep_quant      => gr_add_total(5).sep_quant      -- �X�� ����
        ,in_sep_amount     => gr_add_total(5).sep_amount     -- �X�� ���z
        ,in_sep_price      => gr_add_total(5).sep_price      -- �X�� �i�ڒ艿
        ,in_sep_to_amount  => gr_add_total(5).sep_to_amount  -- �X�� ���󍇌v
        ,in_sep_quant_t    => gr_add_total(5).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_sep_s_cost     => gr_add_total(5).sep_s_cost     -- �X�� �W������(�v�Z�p)
        ,in_sep_calc       => gr_add_total(5).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
        ,in_sep_minus_flg   => gr_add_total(5).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_sep_ht_zero_flg => gr_add_total(5).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_oct_quant      => gr_add_total(5).oct_quant      -- �P�O�� ����
        ,in_oct_amount     => gr_add_total(5).oct_amount     -- �P�O�� ���z
        ,in_oct_price      => gr_add_total(5).oct_price      -- �P�O�� �i�ڒ艿
        ,in_oct_to_amount  => gr_add_total(5).oct_to_amount  -- �P�O�� ���󍇌v
        ,in_oct_quant_t    => gr_add_total(5).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_oct_s_cost     => gr_add_total(5).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
        ,in_oct_calc       => gr_add_total(5).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
        ,in_oct_minus_flg   => gr_add_total(5).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_oct_ht_zero_flg => gr_add_total(5).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_nov_quant      => gr_add_total(5).nov_quant      -- �P�P�� ����
        ,in_nov_amount     => gr_add_total(5).nov_amount     -- �P�P�� ���z
        ,in_nov_price      => gr_add_total(5).nov_price      -- �P�P�� �i�ڒ艿
        ,in_nov_to_amount  => gr_add_total(5).nov_to_amount  -- �P�P�� ���󍇌v
        ,in_nov_quant_t    => gr_add_total(5).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_nov_s_cost     => gr_add_total(5).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
        ,in_nov_calc       => gr_add_total(5).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
        ,in_nov_minus_flg   => gr_add_total(5).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_nov_ht_zero_flg => gr_add_total(5).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_dec_quant      => gr_add_total(5).dec_quant      -- �P�Q�� ����
        ,in_dec_amount     => gr_add_total(5).dec_amount     -- �P�Q�� ���z
        ,in_dec_price      => gr_add_total(5).dec_price      -- �P�Q�� �i�ڒ艿
        ,in_dec_to_amount  => gr_add_total(5).dec_to_amount  -- �P�Q�� ���󍇌v
        ,in_dec_quant_t    => gr_add_total(5).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_dec_s_cost     => gr_add_total(5).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
        ,in_dec_calc       => gr_add_total(5).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
        ,in_dec_minus_flg   => gr_add_total(5).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_dec_ht_zero_flg => gr_add_total(5).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_jan_quant      => gr_add_total(5).jan_quant      -- �P�� ����
        ,in_jan_amount     => gr_add_total(5).jan_amount     -- �P�� ���z
        ,in_jan_price      => gr_add_total(5).jan_price      -- �P�� �i�ڒ艿
        ,in_jan_to_amount  => gr_add_total(5).jan_to_amount  -- �P�� ���󍇌v
        ,in_jan_quant_t    => gr_add_total(5).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_jan_s_cost     => gr_add_total(5).jan_s_cost     -- �P�� �W������(�v�Z�p)
        ,in_jan_calc       => gr_add_total(5).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
        ,in_jan_minus_flg   => gr_add_total(5).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_jan_ht_zero_flg => gr_add_total(5).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_feb_quant      => gr_add_total(5).feb_quant      -- �Q�� ����
        ,in_feb_amount     => gr_add_total(5).feb_amount     -- �Q�� ���z
        ,in_feb_price      => gr_add_total(5).feb_price      -- �Q�� �i�ڒ艿
        ,in_feb_to_amount  => gr_add_total(5).feb_to_amount  -- �Q�� ���󍇌v
        ,in_feb_quant_t    => gr_add_total(5).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_feb_s_cost     => gr_add_total(5).feb_s_cost     -- �Q�� �W������(�v�Z�p)
        ,in_feb_calc       => gr_add_total(5).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
        ,in_feb_minus_flg   => gr_add_total(5).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_feb_ht_zero_flg => gr_add_total(5).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_mar_quant      => gr_add_total(5).mar_quant      -- �R�� ����
        ,in_mar_amount     => gr_add_total(5).mar_amount     -- �R�� ���z
        ,in_mar_price      => gr_add_total(5).mar_price      -- �R�� �i�ڒ艿
        ,in_mar_to_amount  => gr_add_total(5).mar_to_amount  -- �R�� ���󍇌v
        ,in_mar_quant_t    => gr_add_total(5).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_mar_s_cost     => gr_add_total(5).mar_s_cost     -- �R�� �W������(�v�Z�p)
        ,in_mar_calc       => gr_add_total(5).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
        ,in_mar_minus_flg   => gr_add_total(5).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_mar_ht_zero_flg => gr_add_total(5).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_apr_quant      => gr_add_total(5).apr_quant      -- �S�� ����
        ,in_apr_amount     => gr_add_total(5).apr_amount     -- �S�� ���z
        ,in_apr_price      => gr_add_total(5).apr_price      -- �S�� �i�ڒ艿
        ,in_apr_to_amount  => gr_add_total(5).apr_to_amount  -- �S�� ���󍇌v
        ,in_apr_quant_t    => gr_add_total(5).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_apr_s_cost     => gr_add_total(5).apr_s_cost     -- �S�� �W������(�v�Z�p)
        ,in_apr_calc       => gr_add_total(5).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
        ,in_apr_minus_flg   => gr_add_total(5).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_apr_ht_zero_flg => gr_add_total(5).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,in_year_quant     => gr_add_total(5).year_quant     -- �N�v ����
        ,in_year_amount    => gr_add_total(5).year_amount    -- �N�v ���z
        ,in_year_price     => gr_add_total(5).year_price     -- �N�v �i�ڒ艿
        ,in_year_to_amount => gr_add_total(5).year_to_amount -- �N�v ���󍇌v
        ,in_year_quant_t   => gr_add_total(5).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        ,in_year_s_cost    => gr_add_total(5).year_s_cost    -- �N�v �W������(�v�Z�p)
        ,in_year_calc      => gr_add_total(5).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
        ,in_year_minus_flg   => gr_add_total(5).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
        ,in_year_ht_zero_flg => gr_add_total(5).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
        ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
*/
      -----------------------------------------------------------
      -- (�S���_)(3)���_�v/(4)���i�敪�v/(5)�����v�f�[�^�^�O�o�� 
      -----------------------------------------------------------
      <<kyoten_skbn_total_loop>>
      FOR n IN 3..5 LOOP        -- ���_�v/���i�敪�v/�����v
--
        -- ���_�v�̏ꍇ
        IF ( n = 3 ) THEN
          lv_param_label := gv_name_ktn;
--
        -- ���i�敪�v�̏ꍇ
        ELSIF ( n = 4 ) THEn
          lv_param_label := gv_name_skbn;
--
        -- �����v
        ELSE
          lv_param_label := gv_name_ttl;
--
        END IF;
--
        prc_create_xml_data_s_k_t
        (
          iv_label_name       => lv_param_label                   -- ���i�敪�v�p�^�O��
          ,in_may_quant       => gr_add_total(n).may_quant      -- �T�� ����
          ,in_may_amount      => gr_add_total(n).may_amount     -- �T�� ���z
          ,in_may_price       => gr_add_total(n).may_price      -- �T�� �i�ڒ艿
          ,in_may_to_amount   => gr_add_total(n).may_to_amount  -- �T�� ���󍇌v
          ,in_may_quant_t     => gr_add_total(n).may_quant_t    -- �T�� ����(�v�Z�p)
          ,in_may_s_cost      => gr_add_total(n).may_s_cost     -- �T�� �W������(�v�Z�p)
          ,in_may_calc        => gr_add_total(n).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
          ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
          ,in_jun_quant       => gr_add_total(n).jun_quant      -- �U�� ����
          ,in_jun_amount      => gr_add_total(n).jun_amount     -- �U�� ���z
          ,in_jun_price       => gr_add_total(n).jun_price      -- �U�� �i�ڒ艿
          ,in_jun_to_amount   => gr_add_total(n).jun_to_amount  -- �U�� ���󍇌v
          ,in_jun_quant_t     => gr_add_total(n).jun_quant_t    -- �U�� ����(�v�Z�p)
          ,in_jun_s_cost      => gr_add_total(n).jun_s_cost     -- �U�� �W������(�v�Z�p)
          ,in_jun_calc        => gr_add_total(n).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
          ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
          ,in_jul_quant       => gr_add_total(n).jul_quant      -- �V�� ����
          ,in_jul_amount      => gr_add_total(n).jul_amount     -- �V�� ���z
          ,in_jul_price       => gr_add_total(n).jul_price      -- �V�� �i�ڒ艿
          ,in_jul_to_amount   => gr_add_total(n).jul_to_amount  -- �V�� ���󍇌v
          ,in_jul_quant_t     => gr_add_total(n).jul_quant_t    -- �V�� ����(�v�Z�p)
          ,in_jul_s_cost      => gr_add_total(n).jul_s_cost     -- �V�� �W������(�v�Z�p)
          ,in_jul_calc        => gr_add_total(n).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
          ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
          ,in_aug_quant       => gr_add_total(n).aug_quant      -- �W�� ����
          ,in_aug_amount      => gr_add_total(n).aug_amount     -- �W�� ���z
          ,in_aug_price       => gr_add_total(n).aug_price      -- �W�� �i�ڒ艿
          ,in_aug_to_amount   => gr_add_total(n).aug_to_amount  -- �W�� ���󍇌v
          ,in_aug_quant_t     => gr_add_total(n).aug_quant_t    -- �W�� ����(�v�Z�p)
          ,in_aug_s_cost      => gr_add_total(n).aug_s_cost     -- �W�� �W������(�v�Z�p)
          ,in_aug_calc        => gr_add_total(n).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
          ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
          ,in_sep_quant       => gr_add_total(n).sep_quant      -- �X�� ����
          ,in_sep_amount      => gr_add_total(n).sep_amount     -- �X�� ���z
          ,in_sep_price       => gr_add_total(n).sep_price      -- �X�� �i�ڒ艿
          ,in_sep_to_amount   => gr_add_total(n).sep_to_amount  -- �X�� ���󍇌v
          ,in_sep_quant_t     => gr_add_total(n).sep_quant_t    -- �X�� ����(�v�Z�p)
          ,in_sep_s_cost      => gr_add_total(n).sep_s_cost     -- �X�� �W������(�v�Z�p)
          ,in_sep_calc        => gr_add_total(n).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
          ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
          ,in_oct_quant       => gr_add_total(n).oct_quant      -- �P�O�� ����
          ,in_oct_amount      => gr_add_total(n).oct_amount     -- �P�O�� ���z
          ,in_oct_price       => gr_add_total(n).oct_price      -- �P�O�� �i�ڒ艿
          ,in_oct_to_amount   => gr_add_total(n).oct_to_amount  -- �P�O�� ���󍇌v
          ,in_oct_quant_t     => gr_add_total(n).oct_quant_t    -- �P�O�� ����(�v�Z�p)
          ,in_oct_s_cost      => gr_add_total(n).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
          ,in_oct_calc        => gr_add_total(n).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
          ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
          ,in_nov_quant       => gr_add_total(n).nov_quant      -- �P�P�� ����
          ,in_nov_amount      => gr_add_total(n).nov_amount     -- �P�P�� ���z
          ,in_nov_price       => gr_add_total(n).nov_price      -- �P�P�� �i�ڒ艿
          ,in_nov_to_amount   => gr_add_total(n).nov_to_amount  -- �P�P�� ���󍇌v
          ,in_nov_quant_t     => gr_add_total(n).nov_quant_t    -- �P�P�� ����(�v�Z�p)
          ,in_nov_s_cost      => gr_add_total(n).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
          ,in_nov_calc        => gr_add_total(n).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
          ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
          ,in_dec_quant       => gr_add_total(n).dec_quant      -- �P�Q�� ����
          ,in_dec_amount      => gr_add_total(n).dec_amount     -- �P�Q�� ���z
          ,in_dec_price       => gr_add_total(n).dec_price      -- �P�Q�� �i�ڒ艿
          ,in_dec_to_amount   => gr_add_total(n).dec_to_amount  -- �P�Q�� ���󍇌v
          ,in_dec_quant_t     => gr_add_total(n).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
          ,in_dec_s_cost      => gr_add_total(n).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
          ,in_dec_calc        => gr_add_total(n).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
          ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
          ,in_jan_quant       => gr_add_total(n).jan_quant      -- �P�� ����
          ,in_jan_amount      => gr_add_total(n).jan_amount     -- �P�� ���z
          ,in_jan_price       => gr_add_total(n).jan_price      -- �P�� �i�ڒ艿
          ,in_jan_to_amount   => gr_add_total(n).jan_to_amount  -- �P�� ���󍇌v
          ,in_jan_quant_t     => gr_add_total(n).jan_quant_t    -- �P�� ����(�v�Z�p)
          ,in_jan_s_cost      => gr_add_total(n).jan_s_cost     -- �P�� �W������(�v�Z�p)
          ,in_jan_calc        => gr_add_total(n).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
          ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
          ,in_feb_quant       => gr_add_total(n).feb_quant      -- �Q�� ����
          ,in_feb_amount      => gr_add_total(n).feb_amount     -- �Q�� ���z
          ,in_feb_price       => gr_add_total(n).feb_price      -- �Q�� �i�ڒ艿
          ,in_feb_to_amount   => gr_add_total(n).feb_to_amount  -- �Q�� ���󍇌v
          ,in_feb_quant_t     => gr_add_total(n).feb_quant_t    -- �Q�� ����(�v�Z�p)
          ,in_feb_s_cost      => gr_add_total(n).feb_s_cost     -- �Q�� �W������(�v�Z�p)
          ,in_feb_calc        => gr_add_total(n).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
          ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
          ,in_mar_quant       => gr_add_total(n).mar_quant      -- �R�� ����
          ,in_mar_amount      => gr_add_total(n).mar_amount     -- �R�� ���z
          ,in_mar_price       => gr_add_total(n).mar_price      -- �R�� �i�ڒ艿
          ,in_mar_to_amount   => gr_add_total(n).mar_to_amount  -- �R�� ���󍇌v
          ,in_mar_quant_t     => gr_add_total(n).mar_quant_t    -- �R�� ����(�v�Z�p)
          ,in_mar_s_cost      => gr_add_total(n).mar_s_cost     -- �R�� �W������(�v�Z�p)
          ,in_mar_calc        => gr_add_total(n).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
          ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
          ,in_apr_quant       => gr_add_total(n).apr_quant      -- �S�� ����
          ,in_apr_amount      => gr_add_total(n).apr_amount     -- �S�� ���z
          ,in_apr_price       => gr_add_total(n).apr_price      -- �S�� �i�ڒ艿
          ,in_apr_to_amount   => gr_add_total(n).apr_to_amount  -- �S�� ���󍇌v
          ,in_apr_quant_t     => gr_add_total(n).apr_quant_t    -- �S�� ����(�v�Z�p)
          ,in_apr_s_cost      => gr_add_total(n).apr_s_cost     -- �S�� �W������(�v�Z�p)
          ,in_apr_calc        => gr_add_total(n).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
          ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
          ,in_year_quant      => gr_add_total(n).year_quant     -- �N�v ����
          ,in_year_amount     => gr_add_total(n).year_amount    -- �N�v ���z
          ,in_year_price      => gr_add_total(n).year_price     -- �N�v �i�ڒ艿
          ,in_year_to_amount  => gr_add_total(n).year_to_amount -- �N�v ���󍇌v
          ,in_year_quant_t    => gr_add_total(n).year_quant_t   -- �N�v ����(�v�Z�p)
          ,in_year_s_cost     => gr_add_total(n).year_s_cost    -- �N�v �W������(�v�Z�p)
          ,in_year_calc       => gr_add_total(n).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
          ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
          ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ���_�v�̏ꍇ
        IF ( n = 3) THEN
          -- -----------------------------------------------------
          -- (�S���_)���_�I���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (�S���_)���_�I���k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        END IF;
    --
      END LOOP kyoten_skbn_total_loop;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
--
      -- -----------------------------------------------------
      -- (�S���_)���i�敪�I���f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (�S���_)���i�敪�I���k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_skbn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (�S���_)�f�[�^�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (�S���_)���[�g�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/root';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
--     ==========================================================
--     -- ���͂o�w�o�͎�ʁx���u���_���Ɓv�̏ꍇ               --
--     ==========================================================
    ELSE
      -- ========================================================
      -- (���_����)�f�[�^���o - �̔��v�掞�n��\��񒊏o (C-1-2) 
      -- ========================================================
      prc_sale_plan_1
        (
          ot_sale_plan_1    => gr_sale_plan_1     -- �擾���R�[�h�Q
         ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      -- �擾�f�[�^���O���̏ꍇ
      ELSIF (gr_sale_plan_1.COUNT = 0) THEN
        RAISE no_data_expt;
      END IF;
--
      -- =====================================================
      -- (���_����)���ڃf�[�^���o�E�^�O�o�͏���
      -- =====================================================
      -- -----------------------------------------------------
      -- �f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- ���i�敪�J�n�k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_skbn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--

      -- =====================================================
      -- (���_����)���ڃf�[�^���o�E�o�͏���
      -- =====================================================
      <<main_data_loop_1>>
      FOR i IN 1..gr_sale_plan_1.COUNT LOOP
        -- ====================================================
        --  (���_����)���i�敪�u���C�N
        -- ====================================================
        -- ���i�敪���؂�ւ�����Ƃ�
        IF (gr_sale_plan_1(i).skbn <> lv_skbn_break) THEN
          -- ====================================================
          --  (���_����)���i�敪�I���f�^�O�o�͔���
          -- ====================================================
          -- �ŏ��̃��R�[�h�̎��͏o�͂���
          IF (lv_skbn_break <> lv_break_init) THEN
            -----------------------------------------------------------------
            -- (���_����)�e�����o�f�[�^�����݂��Ȃ��ꍇ�A0�\���ɂ�XML�o��  --
            -----------------------------------------------------------------
            <<xml_out_0_loop>>
            FOR m IN 1..12 LOOP
              IF (gr_xml_out(m).out_fg = lv_no) THEN
                prc_create_xml_data_dtl_n
                  (
                    iv_label_name     => gr_xml_out(m).tag_name                      -- �o�̓^�O��
                   ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                   ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                   ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                  );
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
              END IF;
            END LOOP xml_out_0_loop;
--
            -- -----------------------------------------------------
            -- (���_����)�N�v ���ʃf�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
            -- -----------------------------------------------------
            -- (���_����)�N�v ���z�f�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
            -- -----------------------------------------------------
            -- (���_����)�N�v �e�����f�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            ------------------------------------------------
            -- (���_����)�e���v�Z (���z�|���󍇌v������)  --
            ------------------------------------------------
            ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
            -- �O���Z��𔻒�
            IF (ln_year_amount_sum <> gn_0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            gt_xml_data_table(gl_xml_idx).tag_value := 
                      ROUND((ln_arari / ln_year_amount_sum * 100),2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
            END IF;
--
            -- -----------------------------------------------------
            -- (���_����)�N�v �|���f�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            --------------------------------------
            -- �O���Z���荀�ڂ֔���l��}��     --
            --------------------------------------
            ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
            -- �O���Z��𔻒�
            IF (ln_chk_0 <> gn_0) THEN
            -- �l��[0]�o�Ȃ���Όv�Z
            ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              ln_kake_par := gn_0;
            END IF;
--
            -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
            IF ((ln_year_price_sum = 0)
              OR (ln_kake_par < 0)) THEN
              ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
            END IF;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
            -- �e�W�v���ڂփf�[�^�}��
            <<add_total_loop>>
            FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
              gr_add_total(r).year_quant     :=
                 gr_add_total(r).year_quant     + ln_year_quant_sum;        -- ����
              gr_add_total(r).year_amount    :=
                 gr_add_total(r).year_amount    + ln_year_amount_sum;       -- ���z
              gr_add_total(r).year_price     :=
                 gr_add_total(r).year_price     + ln_year_price_sum;        -- �i�ڒ艿
              gr_add_total(r).year_to_amount :=
                 gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- ���󍇌v
              gr_add_total(r).year_quant_t   :=
                 gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- ����(�v)
            END LOOP add_total_loop;
--
            -- -----------------------------------------------------
            --  (���_����)�i�ڏI���f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  (���_����)�i�ڏI���k�f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start
/*
            --------------------------------------------------------
            -- ���Q�v�f�[�^�o�� 
            --------------------------------------------------------
            prc_create_xml_data_st_lt
              (
                iv_label_name     => gv_name_st                     -- ���Q�v�p�^�O��
               ,iv_name           => gv_label_st                    -- ���Q�v�^�C�g��
               ,in_may_quant      => gr_add_total(1).may_quant      -- �T�� ����
               ,in_may_amount     => gr_add_total(1).may_amount     -- �T�� ���z
               ,in_may_price      => gr_add_total(1).may_price      -- �T�� �i�ڒ艿
               ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- �T�� ���󍇌v
               ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- �T�� ����(�v�Z�p)
               ,in_jun_quant      => gr_add_total(1).jun_quant      -- �U�� ����
               ,in_jun_amount     => gr_add_total(1).jun_amount     -- �U�� ���z
               ,in_jun_price      => gr_add_total(1).jun_price      -- �U�� �i�ڒ艿
               ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- �U�� ���󍇌v
               ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- �U�� ����(�v�Z�p)
               ,in_jul_quant      => gr_add_total(1).jul_quant      -- �V�� ����
               ,in_jul_amount     => gr_add_total(1).jul_amount     -- �V�� ���z
               ,in_jul_price      => gr_add_total(1).jul_price      -- �V�� �i�ڒ艿
               ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- �V�� ���󍇌v
               ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- �V�� ����(�v�Z�p)
               ,in_aug_quant      => gr_add_total(1).aug_quant      -- �W�� ����
               ,in_aug_amount     => gr_add_total(1).aug_amount     -- �W�� ���z
               ,in_aug_price      => gr_add_total(1).aug_price      -- �W�� �i�ڒ艿
               ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- �W�� ���󍇌v
               ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- �W�� ����(�v�Z�p)
               ,in_sep_quant      => gr_add_total(1).sep_quant      -- �X�� ����
               ,in_sep_amount     => gr_add_total(1).sep_amount     -- �X�� ���z
               ,in_sep_price      => gr_add_total(1).sep_price      -- �X�� �i�ڒ艿
               ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- �X�� ���󍇌v
               ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- �X�� ����(�v�Z�p)
               ,in_oct_quant      => gr_add_total(1).oct_quant      -- �P�O�� ����
               ,in_oct_amount     => gr_add_total(1).oct_amount     -- �P�O�� ���z
               ,in_oct_price      => gr_add_total(1).oct_price      -- �P�O�� �i�ڒ艿
               ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- �P�O�� ���󍇌v
               ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- �P�O�� ����(�v�Z�p)
               ,in_nov_quant      => gr_add_total(1).nov_quant      -- �P�P�� ����
               ,in_nov_amount     => gr_add_total(1).nov_amount     -- �P�P�� ���z
               ,in_nov_price      => gr_add_total(1).nov_price      -- �P�P�� �i�ڒ艿
               ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- �P�P�� ���󍇌v
               ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- �P�P�� ����(�v�Z�p)
               ,in_dec_quant      => gr_add_total(1).dec_quant      -- �P�Q�� ����
               ,in_dec_amount     => gr_add_total(1).dec_amount     -- �P�Q�� ���z
               ,in_dec_price      => gr_add_total(1).dec_price      -- �P�Q�� �i�ڒ艿
               ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- �P�Q�� ���󍇌v
               ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
               ,in_jan_quant      => gr_add_total(1).jan_quant      -- �P�� ����
               ,in_jan_amount     => gr_add_total(1).jan_amount     -- �P�� ���z
               ,in_jan_price      => gr_add_total(1).jan_price      -- �P�� �i�ڒ艿
               ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- �P�� ���󍇌v
               ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- �P�� ����(�v�Z�p)
               ,in_feb_quant      => gr_add_total(1).feb_quant      -- �Q�� ����
               ,in_feb_amount     => gr_add_total(1).feb_amount     -- �Q�� ���z
               ,in_feb_price      => gr_add_total(1).feb_price      -- �Q�� �i�ڒ艿
               ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- �Q�� ���󍇌v
               ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- �Q�� ����(�v�Z�p)
               ,in_mar_quant      => gr_add_total(1).mar_quant      -- �R�� ����
               ,in_mar_amount     => gr_add_total(1).mar_amount     -- �R�� ���z
               ,in_mar_price      => gr_add_total(1).mar_price      -- �R�� �i�ڒ艿
               ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- �R�� ���󍇌v
               ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- �R�� ����(�v�Z�p)
               ,in_apr_quant      => gr_add_total(1).apr_quant      -- �S�� ����
               ,in_apr_amount     => gr_add_total(1).apr_amount     -- �S�� ���z
               ,in_apr_price      => gr_add_total(1).apr_price      -- �S�� �i�ڒ艿
               ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- �S�� ���󍇌v
               ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- �S�� ����(�v�Z�p)
               ,in_year_quant     => gr_add_total(1).year_quant     -- �N�v ����
               ,in_year_amount    => gr_add_total(1).year_amount    -- �N�v ���z
               ,in_year_price     => gr_add_total(1).year_price     -- �N�v �i�ڒ艿
               ,in_year_to_amount => gr_add_total(1).year_to_amount -- �N�v ���󍇌v
               ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- �N�v ����(�v�Z�p)
               ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
               ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
               ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            --------------------------------------------------------
            -- ��Q�v�f�[�^�o�� 
            --------------------------------------------------------
            prc_create_xml_data_st_lt
              (
                iv_label_name     => gv_name_lt                     -- ��Q�v�p�^�O��
               ,iv_name           => gv_label_lt                    -- ��Q�v�^�C�g��
               ,in_may_quant      => gr_add_total(2).may_quant      -- �T�� ����
               ,in_may_amount     => gr_add_total(2).may_amount     -- �T�� ���z
               ,in_may_price      => gr_add_total(2).may_price      -- �T�� �i�ڒ艿
               ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- �T�� ���󍇌v
               ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- �T�� ����(�v�Z�p)
               ,in_jun_quant      => gr_add_total(2).jun_quant      -- �U�� ����
               ,in_jun_amount     => gr_add_total(2).jun_amount     -- �U�� ���z
               ,in_jun_price      => gr_add_total(2).jun_price      -- �U�� �i�ڒ艿
               ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- �U�� ���󍇌v
               ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- �U�� ����(�v�Z�p)
               ,in_jul_quant      => gr_add_total(2).jul_quant      -- �V�� ����
               ,in_jul_amount     => gr_add_total(2).jul_amount     -- �V�� ���z
               ,in_jul_price      => gr_add_total(2).jul_price      -- �V�� �i�ڒ艿
               ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- �V�� ���󍇌v
               ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- �V�� ����(�v�Z�p)
               ,in_aug_quant      => gr_add_total(2).aug_quant      -- �W�� ����
               ,in_aug_amount     => gr_add_total(2).aug_amount     -- �W�� ���z
               ,in_aug_price      => gr_add_total(2).aug_price      -- �W�� �i�ڒ艿
               ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- �W�� ���󍇌v
               ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- �W�� ����(�v�Z�p)
               ,in_sep_quant      => gr_add_total(2).sep_quant      -- �X�� ����
               ,in_sep_amount     => gr_add_total(2).sep_amount     -- �X�� ���z
               ,in_sep_price      => gr_add_total(2).sep_price      -- �X�� �i�ڒ艿
               ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- �X�� ���󍇌v
               ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- �X�� ����(�v�Z�p)
               ,in_oct_quant      => gr_add_total(2).oct_quant      -- �P�O�� ����
               ,in_oct_amount     => gr_add_total(2).oct_amount     -- �P�O�� ���z
               ,in_oct_price      => gr_add_total(2).oct_price      -- �P�O�� �i�ڒ艿
               ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- �P�O�� ���󍇌v
               ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- �P�O�� ����(�v�Z�p)
               ,in_nov_quant      => gr_add_total(2).nov_quant      -- �P�P�� ����
               ,in_nov_amount     => gr_add_total(2).nov_amount     -- �P�P�� ���z
               ,in_nov_price      => gr_add_total(2).nov_price      -- �P�P�� �i�ڒ艿
               ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- �P�P�� ���󍇌v
               ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- �P�P�� ����(�v�Z�p)
               ,in_dec_quant      => gr_add_total(2).dec_quant      -- �P�Q�� ����
               ,in_dec_amount     => gr_add_total(2).dec_amount     -- �P�Q�� ���z
               ,in_dec_price      => gr_add_total(2).dec_price      -- �P�Q�� �i�ڒ艿
               ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- �P�Q�� ���󍇌v
               ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
               ,in_jan_quant      => gr_add_total(2).jan_quant      -- �P�� ����
               ,in_jan_amount     => gr_add_total(2).jan_amount     -- �P�� ���z
               ,in_jan_price      => gr_add_total(2).jan_price      -- �P�� �i�ڒ艿
               ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- �P�� ���󍇌v
               ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- �P�� ����(�v�Z�p)
               ,in_feb_quant      => gr_add_total(2).feb_quant      -- �Q�� ����
               ,in_feb_amount     => gr_add_total(2).feb_amount     -- �Q�� ���z
               ,in_feb_price      => gr_add_total(2).feb_price      -- �Q�� �i�ڒ艿
               ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- �Q�� ���󍇌v
               ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- �Q�� ����(�v�Z�p)
               ,in_mar_quant      => gr_add_total(2).mar_quant      -- �R�� ����
               ,in_mar_amount     => gr_add_total(2).mar_amount     -- �R�� ���z
               ,in_mar_price      => gr_add_total(2).mar_price      -- �R�� �i�ڒ艿
               ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- �R�� ���󍇌v
               ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- �R�� ����(�v�Z�p)
               ,in_apr_quant      => gr_add_total(2).apr_quant      -- �S�� ����
               ,in_apr_amount     => gr_add_total(2).apr_amount     -- �S�� ���z
               ,in_apr_price      => gr_add_total(2).apr_price      -- �S�� �i�ڒ艿
               ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- �S�� ���󍇌v
               ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- �S�� ����(�v�Z�p)
               ,in_year_quant     => gr_add_total(2).year_quant     -- �N�v ����
               ,in_year_amount    => gr_add_total(2).year_amount    -- �N�v ���z
               ,in_year_price     => gr_add_total(2).year_price     -- �N�v �i�ڒ艿
               ,in_year_to_amount => gr_add_total(2).year_to_amount -- �N�v ���󍇌v
               ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- �N�v ����(�v�Z�p)
               ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
               ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
               ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
*/
            --------------------------------------------------------
            -- (���_����)(1)���Q�v/(2)��Q�v�f�[�^�o�� 
            --------------------------------------------------------
            <<gun_loop>>
            FOR n IN 1..2 LOOP        -- ���Q�v/��Q�v
--
              -- ���Q�v�̏ꍇ
              IF ( n = 1) THEN
                lv_param_name  := gv_name_st;
                lv_param_label := gv_label_st;
              -- ��Q�v�̏ꍇ
              ELSE
                lv_param_name  := gv_name_lt;
                lv_param_label := gv_label_lt;
              END IF;
--
              prc_create_xml_data_st_lt
              (
                 iv_label_name      => lv_param_name                   -- ��Q�v�p�^�O��
                ,iv_name            => lv_param_label                  -- ��Q�v�^�C�g��
                ,in_may_quant       => gr_add_total(n).may_quant       -- �T�� ����
                ,in_may_amount      => gr_add_total(n).may_amount      -- �T�� ���z
                ,in_may_price       => gr_add_total(n).may_price       -- �T�� �i�ڒ艿
                ,in_may_to_amount   => gr_add_total(n).may_to_amount   -- �T�� ���󍇌v
                ,in_may_quant_t     => gr_add_total(n).may_quant_t     -- �T�� ����(�v�Z�p)
                ,in_may_s_cost      => gr_add_total(n).may_s_cost      -- �T�� �W������(�v�Z�p)
                ,in_may_calc        => gr_add_total(n).may_calc        -- �T�� �i�ڒ艿*����(�v�Z�p)
                ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
                ,in_jun_quant       => gr_add_total(n).jun_quant       -- �U�� ����
                ,in_jun_amount      => gr_add_total(n).jun_amount      -- �U�� ���z
                ,in_jun_price       => gr_add_total(n).jun_price       -- �U�� �i�ڒ艿
                ,in_jun_to_amount   => gr_add_total(n).jun_to_amount   -- �U�� ���󍇌v
                ,in_jun_quant_t     => gr_add_total(n).jun_quant_t     -- �U�� ����(�v�Z�p)
                ,in_jun_s_cost      => gr_add_total(n).jun_s_cost      -- �U�� �W������(�v�Z�p)
                ,in_jun_calc        => gr_add_total(n).jun_calc        -- �U�� �i�ڒ艿*����(�v�Z�p)
                ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
                ,in_jul_quant       => gr_add_total(n).jul_quant       -- �V�� ����
                ,in_jul_amount      => gr_add_total(n).jul_amount      -- �V�� ���z
                ,in_jul_price       => gr_add_total(n).jul_price       -- �V�� �i�ڒ艿
                ,in_jul_to_amount   => gr_add_total(n).jul_to_amount   -- �V�� ���󍇌v
                ,in_jul_quant_t     => gr_add_total(n).jul_quant_t     -- �V�� ����(�v�Z�p)
                ,in_jul_s_cost      => gr_add_total(n).jul_s_cost      -- �V�� �W������(�v�Z�p)
                ,in_jul_calc        => gr_add_total(n).jul_calc        -- �V�� �i�ڒ艿*����(�v�Z�p)
                ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
                ,in_aug_quant       => gr_add_total(n).aug_quant       -- �W�� ����
                ,in_aug_amount      => gr_add_total(n).aug_amount      -- �W�� ���z
                ,in_aug_price       => gr_add_total(n).aug_price       -- �W�� �i�ڒ艿
                ,in_aug_to_amount   => gr_add_total(n).aug_to_amount   -- �W�� ���󍇌v
                ,in_aug_quant_t     => gr_add_total(n).aug_quant_t     -- �W�� ����(�v�Z�p)
                ,in_aug_s_cost      => gr_add_total(n).aug_s_cost      -- �W�� �W������(�v�Z�p)
                ,in_aug_calc        => gr_add_total(n).aug_calc        -- �W�� �i�ڒ艿*����(�v�Z�p)
                ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
                ,in_sep_quant       => gr_add_total(n).sep_quant       -- �X�� ����
                ,in_sep_amount      => gr_add_total(n).sep_amount      -- �X�� ���z
                ,in_sep_price       => gr_add_total(n).sep_price       -- �X�� �i�ڒ艿
                ,in_sep_to_amount   => gr_add_total(n).sep_to_amount   -- �X�� ���󍇌v
                ,in_sep_quant_t     => gr_add_total(n).sep_quant_t     -- �X�� ����(�v�Z�p)
                ,in_sep_s_cost      => gr_add_total(n).sep_s_cost      -- �X�� �W������(�v�Z�p)
                ,in_sep_calc        => gr_add_total(n).sep_calc        -- �X�� �i�ڒ艿*����(�v�Z�p)
                ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
                ,in_oct_quant       => gr_add_total(n).oct_quant       -- �P�O�� ����
                ,in_oct_amount      => gr_add_total(n).oct_amount      -- �P�O�� ���z
                ,in_oct_price       => gr_add_total(n).oct_price       -- �P�O�� �i�ڒ艿
                ,in_oct_to_amount   => gr_add_total(n).oct_to_amount   -- �P�O�� ���󍇌v
                ,in_oct_quant_t     => gr_add_total(n).oct_quant_t     -- �P�O�� ����(�v�Z�p)
                ,in_oct_s_cost      => gr_add_total(n).oct_s_cost      -- �P�O�� �W������(�v�Z�p)
                ,in_oct_calc        => gr_add_total(n).oct_calc        -- �P�O�� �i�ڒ艿*����(�v�Z�p)
                ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
                ,in_nov_quant       => gr_add_total(n).nov_quant       -- �P�P�� ����
                ,in_nov_amount      => gr_add_total(n).nov_amount      -- �P�P�� ���z
                ,in_nov_price       => gr_add_total(n).nov_price       -- �P�P�� �i�ڒ艿
                ,in_nov_to_amount   => gr_add_total(n).nov_to_amount   -- �P�P�� ���󍇌v
                ,in_nov_quant_t     => gr_add_total(n).nov_quant_t     -- �P�P�� ����(�v�Z�p)
                ,in_nov_s_cost      => gr_add_total(n).nov_s_cost      -- �P�P�� �W������(�v�Z�p)
                ,in_nov_calc        => gr_add_total(n).nov_calc        -- �P�P�� �i�ڒ艿*����(�v�Z�p)
                ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
                ,in_dec_quant       => gr_add_total(n).dec_quant       -- �P�Q�� ����
                ,in_dec_amount      => gr_add_total(n).dec_amount      -- �P�Q�� ���z
                ,in_dec_price       => gr_add_total(n).dec_price       -- �P�Q�� �i�ڒ艿
                ,in_dec_to_amount   => gr_add_total(n).dec_to_amount   -- �P�Q�� ���󍇌v
                ,in_dec_quant_t     => gr_add_total(n).dec_quant_t     -- �P�Q�� ����(�v�Z�p)
                ,in_dec_s_cost      => gr_add_total(n).dec_s_cost      -- �P�Q�� �W������(�v�Z�p)
                ,in_dec_calc        => gr_add_total(n).dec_calc        -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
                ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
                ,in_jan_quant       => gr_add_total(n).jan_quant       -- �P�� ����
                ,in_jan_amount      => gr_add_total(n).jan_amount      -- �P�� ���z
                ,in_jan_price       => gr_add_total(n).jan_price       -- �P�� �i�ڒ艿
                ,in_jan_to_amount   => gr_add_total(n).jan_to_amount   -- �P�� ���󍇌v
                ,in_jan_quant_t     => gr_add_total(n).jan_quant_t     -- �P�� ����(�v�Z�p)
                ,in_jan_s_cost      => gr_add_total(n).jan_s_cost      -- �P�� �W������(�v�Z�p)
                ,in_jan_calc        => gr_add_total(n).jan_calc        -- �P�� �i�ڒ艿*����(�v�Z�p)
                ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
                ,in_feb_quant       => gr_add_total(n).feb_quant       -- �Q�� ����
                ,in_feb_amount      => gr_add_total(n).feb_amount      -- �Q�� ���z
                ,in_feb_price       => gr_add_total(n).feb_price       -- �Q�� �i�ڒ艿
                ,in_feb_to_amount   => gr_add_total(n).feb_to_amount   -- �Q�� ���󍇌v
                ,in_feb_quant_t     => gr_add_total(n).feb_quant_t     -- �Q�� ����(�v�Z�p)
                ,in_feb_s_cost      => gr_add_total(n).feb_s_cost      -- �Q�� �W������(�v�Z�p)
                ,in_feb_calc        => gr_add_total(n).feb_calc        -- �Q�� �i�ڒ艿*����(�v�Z�p)
                ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
                ,in_mar_quant       => gr_add_total(n).mar_quant       -- �R�� ����
                ,in_mar_amount      => gr_add_total(n).mar_amount      -- �R�� ���z
                ,in_mar_price       => gr_add_total(n).mar_price       -- �R�� �i�ڒ艿
                ,in_mar_to_amount   => gr_add_total(n).mar_to_amount   -- �R�� ���󍇌v
                ,in_mar_quant_t     => gr_add_total(n).mar_quant_t     -- �R�� ����(�v�Z�p)
                ,in_mar_s_cost      => gr_add_total(n).mar_s_cost      -- �R�� �W������(�v�Z�p)
                ,in_mar_calc        => gr_add_total(n).mar_calc        -- �R�� �i�ڒ艿*����(�v�Z�p)
                ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
                ,in_apr_quant       => gr_add_total(n).apr_quant       -- �S�� ����
                ,in_apr_amount      => gr_add_total(n).apr_amount      -- �S�� ���z
                ,in_apr_price       => gr_add_total(n).apr_price       -- �S�� �i�ڒ艿
                ,in_apr_to_amount   => gr_add_total(n).apr_to_amount   -- �S�� ���󍇌v
                ,in_apr_quant_t     => gr_add_total(n).apr_quant_t     -- �S�� ����(�v�Z�p)
                ,in_apr_s_cost      => gr_add_total(n).apr_s_cost      -- �S�� �W������(�v�Z�p)
                ,in_apr_calc        => gr_add_total(n).apr_calc        -- �S�� �i�ڒ艿*����(�v�Z�p)
                ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
                ,in_year_quant      => gr_add_total(n).year_quant        -- �N�v ����
                ,in_year_amount     => gr_add_total(n).year_amount       -- �N�v ���z
                ,in_year_price      => gr_add_total(n).year_price        -- �N�v �i�ڒ艿
                ,in_year_to_amount  => gr_add_total(n).year_to_amount    -- �N�v ���󍇌v
                ,in_year_quant_t    => gr_add_total(n).year_quant_t      -- �N�v ����(�v�Z�p)
                ,in_year_s_cost     => gr_add_total(n).year_s_cost       -- �N�v �W������(�v�Z�p)
                ,in_year_calc       => gr_add_total(n).year_calc         -- �N�v �i�ڒ艿*����(�v�Z�p)
                ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
                ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
            END LOOP gun_loop;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
            -- -----------------------------------------------------
            --  �Q�R�[�h�I���f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
-- 
            -- -----------------------------------------------------
            --  �Q�R�[�h�I���k�f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start
/*
            --------------------------------------------------------
            -- ���_�v�f�[�^�^�O�o�� 
            --------------------------------------------------------
            prc_create_xml_data_s_k_t
              (
                iv_label_name     => gv_name_ktn                    -- ���_�v�p�^�O��
               ,in_may_quant      => gr_add_total(3).may_quant      -- �T�� ����
               ,in_may_amount     => gr_add_total(3).may_amount     -- �T�� ���z
               ,in_may_price      => gr_add_total(3).may_price      -- �T�� �i�ڒ艿
               ,in_may_to_amount  => gr_add_total(3).may_to_amount  -- �T�� ���󍇌v
               ,in_jun_quant      => gr_add_total(3).jun_quant      -- �U�� ����
               ,in_jun_amount     => gr_add_total(3).jun_amount     -- �U�� ���z
               ,in_jun_price      => gr_add_total(3).jun_price      -- �U�� �i�ڒ艿
               ,in_jun_to_amount  => gr_add_total(3).jun_to_amount  -- �U�� ���󍇌v
               ,in_jul_quant      => gr_add_total(3).jul_quant      -- �V�� ����
               ,in_jul_amount     => gr_add_total(3).jul_amount     -- �V�� ���z
               ,in_jul_price      => gr_add_total(3).jul_price      -- �V�� �i�ڒ艿
               ,in_jul_to_amount  => gr_add_total(3).jul_to_amount  -- �V�� ���󍇌v
               ,in_aug_quant      => gr_add_total(3).aug_quant      -- �W�� ����
               ,in_aug_amount     => gr_add_total(3).aug_amount     -- �W�� ���z
               ,in_aug_price      => gr_add_total(3).aug_price      -- �W�� �i�ڒ艿
               ,in_aug_to_amount  => gr_add_total(3).aug_to_amount  -- �W�� ���󍇌v
               ,in_sep_quant      => gr_add_total(3).sep_quant      -- �X�� ����
               ,in_sep_amount     => gr_add_total(3).sep_amount     -- �X�� ���z
               ,in_sep_price      => gr_add_total(3).sep_price      -- �X�� �i�ڒ艿
               ,in_sep_to_amount  => gr_add_total(3).sep_to_amount  -- �X�� ���󍇌v
               ,in_oct_quant      => gr_add_total(3).oct_quant      -- �P�O�� ����
               ,in_oct_amount     => gr_add_total(3).oct_amount     -- �P�O�� ���z
               ,in_oct_price      => gr_add_total(3).oct_price      -- �P�O�� �i�ڒ艿
               ,in_oct_to_amount  => gr_add_total(3).oct_to_amount  -- �P�O�� ���󍇌v
               ,in_nov_quant      => gr_add_total(3).nov_quant      -- �P�P�� ����
               ,in_nov_amount     => gr_add_total(3).nov_amount     -- �P�P�� ���z
               ,in_nov_price      => gr_add_total(3).nov_price      -- �P�P�� �i�ڒ艿
               ,in_nov_to_amount  => gr_add_total(3).nov_to_amount  -- �P�P�� ���󍇌v
               ,in_dec_quant      => gr_add_total(3).dec_quant      -- �P�Q�� ����
               ,in_dec_amount     => gr_add_total(3).dec_amount     -- �P�Q�� ���z
               ,in_dec_price      => gr_add_total(3).dec_price      -- �P�Q�� �i�ڒ艿
               ,in_dec_to_amount  => gr_add_total(3).dec_to_amount  -- �P�Q�� ���󍇌v
               ,in_jan_quant      => gr_add_total(3).jan_quant      -- �P�� ����
               ,in_jan_amount     => gr_add_total(3).jan_amount     -- �P�� ���z
               ,in_jan_price      => gr_add_total(3).jan_price      -- �P�� �i�ڒ艿
               ,in_jan_to_amount  => gr_add_total(3).jan_to_amount  -- �P�� ���󍇌v
               ,in_feb_quant      => gr_add_total(3).feb_quant      -- �Q�� ����
               ,in_feb_amount     => gr_add_total(3).feb_amount     -- �Q�� ���z
               ,in_feb_price      => gr_add_total(3).feb_price      -- �Q�� �i�ڒ艿
               ,in_feb_to_amount  => gr_add_total(3).feb_to_amount  -- �Q�� ���󍇌v
               ,in_mar_quant      => gr_add_total(3).mar_quant      -- �R�� ����
               ,in_mar_amount     => gr_add_total(3).mar_amount     -- �R�� ���z
               ,in_mar_price      => gr_add_total(3).mar_price      -- �R�� �i�ڒ艿
               ,in_mar_to_amount  => gr_add_total(3).mar_to_amount  -- �R�� ���󍇌v
               ,in_apr_quant      => gr_add_total(3).apr_quant      -- �S�� ����
               ,in_apr_amount     => gr_add_total(3).apr_amount     -- �S�� ���z
               ,in_apr_price      => gr_add_total(3).apr_price      -- �S�� �i�ڒ艿
               ,in_apr_to_amount  => gr_add_total(3).apr_to_amount  -- �S�� ���󍇌v
               ,in_year_quant     => gr_add_total(3).year_quant     -- �N�v ����
               ,in_year_amount    => gr_add_total(3).year_amount    -- �N�v ���z
               ,in_year_price     => gr_add_total(3).year_price     -- �N�v �i�ڒ艿
               ,in_year_to_amount => gr_add_total(3).year_to_amount -- �N�v ���󍇌v
               ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
               ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
               ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- -----------------------------------------------------
            --  ���_�I���f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- -----------------------------------------------------
            --  ���_�I���k�f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            --------------------------------------------------------
            -- ���i�敪�v�f�[�^�^�O�o�� 
            --------------------------------------------------------
            prc_create_xml_data_s_k_t
              (
                iv_label_name     => gv_name_skbn                   -- ���i�敪�v�p�^�O��
               ,in_may_quant      => gr_add_total(4).may_quant      -- �T�� ����
               ,in_may_amount     => gr_add_total(4).may_amount     -- �T�� ���z
               ,in_may_price      => gr_add_total(4).may_price      -- �T�� �i�ڒ艿
               ,in_may_to_amount  => gr_add_total(4).may_to_amount  -- �T�� ���󍇌v
               ,in_jun_quant      => gr_add_total(4).jun_quant      -- �U�� ����
               ,in_jun_amount     => gr_add_total(4).jun_amount     -- �U�� ���z
               ,in_jun_price      => gr_add_total(4).jun_price      -- �U�� �i�ڒ艿
               ,in_jun_to_amount  => gr_add_total(4).jun_to_amount  -- �U�� ���󍇌v
               ,in_jul_quant      => gr_add_total(4).jul_quant      -- �V�� ����
               ,in_jul_amount     => gr_add_total(4).jul_amount     -- �V�� ���z
               ,in_jul_price      => gr_add_total(4).jul_price      -- �V�� �i�ڒ艿
               ,in_jul_to_amount  => gr_add_total(4).jul_to_amount  -- �V�� ���󍇌v
               ,in_aug_quant      => gr_add_total(4).aug_quant      -- �W�� ����
               ,in_aug_amount     => gr_add_total(4).aug_amount     -- �W�� ���z
               ,in_aug_price      => gr_add_total(4).aug_price      -- �W�� �i�ڒ艿
               ,in_aug_to_amount  => gr_add_total(4).aug_to_amount  -- �W�� ���󍇌v
               ,in_sep_quant      => gr_add_total(4).sep_quant      -- �X�� ����
               ,in_sep_amount     => gr_add_total(4).sep_amount     -- �X�� ���z
               ,in_sep_price      => gr_add_total(4).sep_price      -- �X�� �i�ڒ艿
               ,in_sep_to_amount  => gr_add_total(4).sep_to_amount  -- �X�� ���󍇌v
               ,in_oct_quant      => gr_add_total(4).oct_quant      -- �P�O�� ����
               ,in_oct_amount     => gr_add_total(4).oct_amount     -- �P�O�� ���z
               ,in_oct_price      => gr_add_total(4).oct_price      -- �P�O�� �i�ڒ艿
               ,in_oct_to_amount  => gr_add_total(4).oct_to_amount  -- �P�O�� ���󍇌v
               ,in_nov_quant      => gr_add_total(4).nov_quant      -- �P�P�� ����
               ,in_nov_amount     => gr_add_total(4).nov_amount     -- �P�P�� ���z
               ,in_nov_price      => gr_add_total(4).nov_price      -- �P�P�� �i�ڒ艿
               ,in_nov_to_amount  => gr_add_total(4).nov_to_amount  -- �P�P�� ���󍇌v
               ,in_dec_quant      => gr_add_total(4).dec_quant      -- �P�Q�� ����
               ,in_dec_amount     => gr_add_total(4).dec_amount     -- �P�Q�� ���z
               ,in_dec_price      => gr_add_total(4).dec_price      -- �P�Q�� �i�ڒ艿
               ,in_dec_to_amount  => gr_add_total(4).dec_to_amount  -- �P�Q�� ���󍇌v
               ,in_jan_quant      => gr_add_total(4).jan_quant      -- �P�� ����
               ,in_jan_amount     => gr_add_total(4).jan_amount     -- �P�� ���z
               ,in_jan_price      => gr_add_total(4).jan_price      -- �P�� �i�ڒ艿
               ,in_jan_to_amount  => gr_add_total(4).jan_to_amount  -- �P�� ���󍇌v
               ,in_feb_quant      => gr_add_total(4).feb_quant      -- �Q�� ����
               ,in_feb_amount     => gr_add_total(4).feb_amount     -- �Q�� ���z
               ,in_feb_price      => gr_add_total(4).feb_price      -- �Q�� �i�ڒ艿
               ,in_feb_to_amount  => gr_add_total(4).feb_to_amount  -- �Q�� ���󍇌v
               ,in_mar_quant      => gr_add_total(4).mar_quant      -- �R�� ����
               ,in_mar_amount     => gr_add_total(4).mar_amount     -- �R�� ���z
               ,in_mar_price      => gr_add_total(4).mar_price      -- �R�� �i�ڒ艿
               ,in_mar_to_amount  => gr_add_total(4).mar_to_amount  -- �R�� ���󍇌v
               ,in_apr_quant      => gr_add_total(4).apr_quant      -- �S�� ����
               ,in_apr_amount     => gr_add_total(4).apr_amount     -- �S�� ���z
               ,in_apr_price      => gr_add_total(4).apr_price      -- �S�� �i�ڒ艿
               ,in_apr_to_amount  => gr_add_total(4).apr_to_amount  -- �S�� ���󍇌v
               ,in_year_quant     => gr_add_total(4).year_quant     -- �N�v ����
               ,in_year_amount    => gr_add_total(4).year_amount    -- �N�v ���z
               ,in_year_price     => gr_add_total(4).year_price     -- �N�v �i�ڒ艿
               ,in_year_to_amount => gr_add_total(4).year_to_amount -- �N�v ���󍇌v
               ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
               ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
               ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- -----------------------------------------------------
            --  ���i�敪�I���f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
*/
--
            --------------------------------------------------------
            -- (���_����)(3)���_�v/(4)���i�敪�v�f�[�^�^�O�o�� 
            --------------------------------------------------------
            <<kyoten_skbn_loop>>
            FOR n IN 3..4 LOOP        -- ���_�v/���i�敪�v
--
              -- ���_�v�̏ꍇ
              IF ( n = 3) THEN
                lv_param_label := gv_name_ktn;
              -- ���i�敪�v�̏ꍇ
              ELSE
                lv_param_label := gv_name_skbn;
              END IF;
--
              prc_create_xml_data_s_k_t
              (
                iv_label_name       => lv_param_label                   -- ���i�敪�v�p�^�O��
                ,in_may_quant       => gr_add_total(n).may_quant      -- �T�� ����
                ,in_may_amount      => gr_add_total(n).may_amount     -- �T�� ���z
                ,in_may_price       => gr_add_total(n).may_price      -- �T�� �i�ڒ艿
                ,in_may_to_amount   => gr_add_total(n).may_to_amount  -- �T�� ���󍇌v
                ,in_may_quant_t     => gr_add_total(n).may_quant_t    -- �T�� ����(�v�Z�p)
                ,in_may_s_cost      => gr_add_total(n).may_s_cost     -- �T�� �W������(�v�Z�p)
                ,in_may_calc        => gr_add_total(n).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
                ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
                ,in_jun_quant       => gr_add_total(n).jun_quant      -- �U�� ����
                ,in_jun_amount      => gr_add_total(n).jun_amount     -- �U�� ���z
                ,in_jun_price       => gr_add_total(n).jun_price      -- �U�� �i�ڒ艿
                ,in_jun_to_amount   => gr_add_total(n).jun_to_amount  -- �U�� ���󍇌v
                ,in_jun_quant_t     => gr_add_total(n).jun_quant_t    -- �U�� ����(�v�Z�p)
                ,in_jun_s_cost      => gr_add_total(n).jun_s_cost     -- �U�� �W������(�v�Z�p)
                ,in_jun_calc        => gr_add_total(n).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
                ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
                ,in_jul_quant       => gr_add_total(n).jul_quant      -- �V�� ����
                ,in_jul_amount      => gr_add_total(n).jul_amount     -- �V�� ���z
                ,in_jul_price       => gr_add_total(n).jul_price      -- �V�� �i�ڒ艿
                ,in_jul_to_amount   => gr_add_total(n).jul_to_amount  -- �V�� ���󍇌v
                ,in_jul_quant_t     => gr_add_total(n).jul_quant_t    -- �V�� ����(�v�Z�p)
                ,in_jul_s_cost      => gr_add_total(n).jul_s_cost     -- �V�� �W������(�v�Z�p)
                ,in_jul_calc        => gr_add_total(n).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
                ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
                ,in_aug_quant       => gr_add_total(n).aug_quant      -- �W�� ����
                ,in_aug_amount      => gr_add_total(n).aug_amount     -- �W�� ���z
                ,in_aug_price       => gr_add_total(n).aug_price      -- �W�� �i�ڒ艿
                ,in_aug_to_amount   => gr_add_total(n).aug_to_amount  -- �W�� ���󍇌v
                ,in_aug_quant_t     => gr_add_total(n).aug_quant_t    -- �W�� ����(�v�Z�p)
                ,in_aug_s_cost      => gr_add_total(n).aug_s_cost     -- �W�� �W������(�v�Z�p)
                ,in_aug_calc        => gr_add_total(n).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
                ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
                ,in_sep_quant       => gr_add_total(n).sep_quant      -- �X�� ����
                ,in_sep_amount      => gr_add_total(n).sep_amount     -- �X�� ���z
                ,in_sep_price       => gr_add_total(n).sep_price      -- �X�� �i�ڒ艿
                ,in_sep_to_amount   => gr_add_total(n).sep_to_amount  -- �X�� ���󍇌v
                ,in_sep_quant_t     => gr_add_total(n).sep_quant_t    -- �X�� ����(�v�Z�p)
                ,in_sep_s_cost      => gr_add_total(n).sep_s_cost     -- �X�� �W������(�v�Z�p)
                ,in_sep_calc        => gr_add_total(n).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
                ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
                ,in_oct_quant       => gr_add_total(n).oct_quant      -- �P�O�� ����
                ,in_oct_amount      => gr_add_total(n).oct_amount     -- �P�O�� ���z
                ,in_oct_price       => gr_add_total(n).oct_price      -- �P�O�� �i�ڒ艿
                ,in_oct_to_amount   => gr_add_total(n).oct_to_amount  -- �P�O�� ���󍇌v
                ,in_oct_quant_t     => gr_add_total(n).oct_quant_t    -- �P�O�� ����(�v�Z�p)
                ,in_oct_s_cost      => gr_add_total(n).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
                ,in_oct_calc        => gr_add_total(n).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
                ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
                ,in_nov_quant       => gr_add_total(n).nov_quant      -- �P�P�� ����
                ,in_nov_amount      => gr_add_total(n).nov_amount     -- �P�P�� ���z
                ,in_nov_price       => gr_add_total(n).nov_price      -- �P�P�� �i�ڒ艿
                ,in_nov_to_amount   => gr_add_total(n).nov_to_amount  -- �P�P�� ���󍇌v
                ,in_nov_quant_t     => gr_add_total(n).nov_quant_t    -- �P�P�� ����(�v�Z�p)
                ,in_nov_s_cost      => gr_add_total(n).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
                ,in_nov_calc        => gr_add_total(n).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
                ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
                ,in_dec_quant       => gr_add_total(n).dec_quant      -- �P�Q�� ����
                ,in_dec_amount      => gr_add_total(n).dec_amount     -- �P�Q�� ���z
                ,in_dec_price       => gr_add_total(n).dec_price      -- �P�Q�� �i�ڒ艿
                ,in_dec_to_amount   => gr_add_total(n).dec_to_amount  -- �P�Q�� ���󍇌v
                ,in_dec_quant_t     => gr_add_total(n).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
                ,in_dec_s_cost      => gr_add_total(n).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
                ,in_dec_calc        => gr_add_total(n).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
                ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
                ,in_jan_quant       => gr_add_total(n).jan_quant      -- �P�� ����
                ,in_jan_amount      => gr_add_total(n).jan_amount     -- �P�� ���z
                ,in_jan_price       => gr_add_total(n).jan_price      -- �P�� �i�ڒ艿
                ,in_jan_to_amount   => gr_add_total(n).jan_to_amount  -- �P�� ���󍇌v
                ,in_jan_quant_t     => gr_add_total(n).jan_quant_t    -- �P�� ����(�v�Z�p)
                ,in_jan_s_cost      => gr_add_total(n).jan_s_cost     -- �P�� �W������(�v�Z�p)
                ,in_jan_calc        => gr_add_total(n).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
                ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
                ,in_feb_quant       => gr_add_total(n).feb_quant      -- �Q�� ����
                ,in_feb_amount      => gr_add_total(n).feb_amount     -- �Q�� ���z
                ,in_feb_price       => gr_add_total(n).feb_price      -- �Q�� �i�ڒ艿
                ,in_feb_to_amount   => gr_add_total(n).feb_to_amount  -- �Q�� ���󍇌v
                ,in_feb_quant_t     => gr_add_total(n).feb_quant_t    -- �Q�� ����(�v�Z�p)
                ,in_feb_s_cost      => gr_add_total(n).feb_s_cost     -- �Q�� �W������(�v�Z�p)
                ,in_feb_calc        => gr_add_total(n).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
                ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
                ,in_mar_quant       => gr_add_total(n).mar_quant      -- �R�� ����
                ,in_mar_amount      => gr_add_total(n).mar_amount     -- �R�� ���z
                ,in_mar_price       => gr_add_total(n).mar_price      -- �R�� �i�ڒ艿
                ,in_mar_to_amount   => gr_add_total(n).mar_to_amount  -- �R�� ���󍇌v
                ,in_mar_quant_t     => gr_add_total(n).mar_quant_t    -- �R�� ����(�v�Z�p)
                ,in_mar_s_cost      => gr_add_total(n).mar_s_cost     -- �R�� �W������(�v�Z�p)
                ,in_mar_calc        => gr_add_total(n).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
                ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
                ,in_apr_quant       => gr_add_total(n).apr_quant      -- �S�� ����
                ,in_apr_amount      => gr_add_total(n).apr_amount     -- �S�� ���z
                ,in_apr_price       => gr_add_total(n).apr_price      -- �S�� �i�ڒ艿
                ,in_apr_to_amount   => gr_add_total(n).apr_to_amount  -- �S�� ���󍇌v
                ,in_apr_quant_t     => gr_add_total(n).apr_quant_t    -- �S�� ����(�v�Z�p)
                ,in_apr_s_cost      => gr_add_total(n).apr_s_cost     -- �S�� �W������(�v�Z�p)
                ,in_apr_calc        => gr_add_total(n).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
                ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
                ,in_year_quant      => gr_add_total(n).year_quant     -- �N�v ����
                ,in_year_amount     => gr_add_total(n).year_amount    -- �N�v ���z
                ,in_year_price      => gr_add_total(n).year_price     -- �N�v �i�ڒ艿
                ,in_year_to_amount  => gr_add_total(n).year_to_amount -- �N�v ���󍇌v
                ,in_year_quant_t    => gr_add_total(n).year_quant_t   -- �N�v ����(�v�Z�p)
                ,in_year_s_cost     => gr_add_total(n).year_s_cost    -- �N�v �W������(�v�Z�p)
                ,in_year_calc       => gr_add_total(n).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
                ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
                ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
                ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
              -- ���_�v�̏ꍇ
              IF ( n = 3) THEN
                -- -----------------------------------------------------
                --  (���_����)���_�I���f�^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
    --
                -- -----------------------------------------------------
                --  (���_����)���_�I���k�f�^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
              -- ���i�敪�v�̏ꍇ
              ELSE
                -- -----------------------------------------------------
                --  (���_����)���i�敪�I���f�^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
              END IF;
--
            END LOOP kyoten_skbn_loop;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
--
          END IF;
--
          -- -----------------------------------------------------
          --  (���_����)���i�敪�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_skbn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (���_����)���i�敪(�R�[�h) �^�O
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).skbn;
--
          -- -----------------------------------------------------
          -- (���_����)���i�敪(����) �^�O
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'skbn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          ------------------------------------------------
          -- (���_����)���͂o�w���i�敪�x��NULL�̏ꍇ   --
          ------------------------------------------------
          IF (gr_param.prod_div IS NULL) THEN
            -- ���o�f�[�^��'1'�̏ꍇ
            IF (gr_sale_plan_1(i).skbn = gv_prod_div_leaf) THEN
             gt_xml_data_table(gl_xml_idx).tag_value := lv_name_leaf;  -- '���[�t'
            -- ���o�f�[�^��'2'�̏ꍇ
            ELSIF (gr_sale_plan_1(i).skbn = gv_prod_div_drink) THEN
              gt_xml_data_table(gl_xml_idx).tag_value := lv_name_drink; -- '�h�����N'
            END IF;
          -- ���͂o�w���i�敪�x���w�肳��Ă���ꍇ
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).skbn_name;
          END IF;
--
          -- -----------------------------------------------------
          --  (���_����)���_�敪�J�n�k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ktn_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (���_����)���_�敪�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (���_����)���_�敪(���_�R�[�h) �^�O
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).ktn_code;
--
          -- -----------------------------------------------------
          --  (���_����)���_�敪(���_����) �^�O
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).party_short_name;
--
          -- -----------------------------------------------------
          --  (���_����)�Q�R�[�h�J�nL�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (���_����)�Q�R�[�h�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (���_����)�i�ڊJ�n�k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- �e�u���C�N�L�[�X�V
          lv_skbn_break := gr_sale_plan_1(i).skbn;              -- ���i�敪
          lv_ktn_break  := gr_sale_plan_1(i).ktn_code;          -- ���_
          lv_gun_break  := gr_sale_plan_1(i).gun;               -- �Q�R�[�h
          lv_dtl_break  := lv_break_init;                       -- �i�ڃR�[�h
          lv_sttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,3);  -- ���Q�v
          lv_lttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,1);  -- ��Q�v
--
          ----------------------------------------
          --  (���_����)�e�W�v���ڏ�����
          ----------------------------------------
          -- �f�[�^���P���ڂ̏ꍇ
          IF (i = 1) THEN 
            <<add_total_loop>>
            FOR l IN 1..5 LOOP        -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
              gr_add_total(l).may_quant       := gn_0; -- �T�� ����
              gr_add_total(l).may_amount      := gn_0; -- �T�� ���z
              gr_add_total(l).may_price       := gn_0; -- �T�� �i�ڒ艿
              gr_add_total(l).may_to_amount   := gn_0; -- �T�� ���󍇌v
              gr_add_total(l).may_quant_t     := gn_0; -- �T�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).may_s_cost      := gn_0; -- �T�� �W������(�v)
              gr_add_total(l).may_calc        := gn_0; -- �T�� �i�ڒ艿*����(�v)
              gr_add_total(l).may_minus_flg   := 'N';  -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).may_ht_zero_flg := 'N';  -- �T�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).jun_quant       := gn_0; -- �U�� ����
              gr_add_total(l).jun_amount      := gn_0; -- �U�� ���z
              gr_add_total(l).jun_price       := gn_0; -- �U�� �i�ڒ艿
              gr_add_total(l).jun_to_amount   := gn_0; -- �U�� ���󍇌v
              gr_add_total(l).jun_quant_t     := gn_0; -- �U�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).jun_s_cost      := gn_0; -- �U�� �W������(�v)
              gr_add_total(l).jun_calc        := gn_0; -- �U�� �i�ڒ艿*����(�v)
              gr_add_total(l).jun_minus_flg   := 'N';  -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).jun_ht_zero_flg := 'N';  -- �U�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).jul_quant       := gn_0; -- �V�� ����
              gr_add_total(l).jul_amount      := gn_0; -- �V�� ���z
              gr_add_total(l).jul_price       := gn_0; -- �V�� �i�ڒ艿
              gr_add_total(l).jul_to_amount   := gn_0; -- �V�� ���󍇌v
              gr_add_total(l).jul_quant_t     := gn_0; -- �V�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).jul_s_cost      := gn_0; -- �V�� �W������(�v)
              gr_add_total(l).jul_calc        := gn_0; -- �V�� �i�ڒ艿*����(�v)
              gr_add_total(l).jul_minus_flg   := 'N';  -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).jul_ht_zero_flg := 'N';  -- �V�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).aug_quant       := gn_0; -- �W�� ����
              gr_add_total(l).aug_amount      := gn_0; -- �W�� ���z
              gr_add_total(l).aug_price       := gn_0; -- �W�� �i�ڒ艿
              gr_add_total(l).aug_to_amount   := gn_0; -- �W�� ���󍇌v
              gr_add_total(l).aug_quant_t     := gn_0; -- �W�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).aug_s_cost      := gn_0; -- �W�� �W������(�v)
              gr_add_total(l).aug_calc        := gn_0; -- �W�� �i�ڒ艿*����(�v)
              gr_add_total(l).aug_minus_flg   := 'N';  -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).aug_ht_zero_flg := 'N';  -- �W�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).sep_quant       := gn_0; -- �X�� ����
              gr_add_total(l).sep_amount      := gn_0; -- �X�� ���z
              gr_add_total(l).sep_price       := gn_0; -- �X�� �i�ڒ艿
              gr_add_total(l).sep_to_amount   := gn_0; -- �X�� ���󍇌v
              gr_add_total(l).sep_quant_t     := gn_0; -- �X�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).sep_s_cost      := gn_0; -- �X�� �W������(�v)
              gr_add_total(l).sep_calc        := gn_0; -- �X�� �i�ڒ艿*����(�v)
              gr_add_total(l).sep_minus_flg   := 'N';  -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).sep_ht_zero_flg := 'N';  -- �X�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).oct_quant       := gn_0; -- �P�O�� ����
              gr_add_total(l).oct_amount      := gn_0; -- �P�O�� ���z
              gr_add_total(l).oct_price       := gn_0; -- �P�O�� �i�ڒ艿
              gr_add_total(l).oct_to_amount   := gn_0; -- �P�O�� ���󍇌v
              gr_add_total(l).oct_quant_t     := gn_0; -- �P�O�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).oct_s_cost      := gn_0; -- �P�O�� �W������(�v)
              gr_add_total(l).oct_calc        := gn_0; -- �P�O�� �i�ڒ艿*����(�v)
              gr_add_total(l).oct_minus_flg   := 'N';  -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).oct_ht_zero_flg := 'N';  -- �P�O�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).nov_quant       := gn_0; -- �P�P�� ����
              gr_add_total(l).nov_amount      := gn_0; -- �P�P�� ���z
              gr_add_total(l).nov_price       := gn_0; -- �P�P�� �i�ڒ艿
              gr_add_total(l).nov_to_amount   := gn_0; -- �P�P�� ���󍇌v
              gr_add_total(l).nov_quant_t     := gn_0; -- �P�P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).nov_s_cost      := gn_0; -- �P�P�� �W������(�v)
              gr_add_total(l).nov_calc        := gn_0; -- �P�P�� �i�ڒ艿*����(�v)
              gr_add_total(l).nov_minus_flg   := 'N';  -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).nov_ht_zero_flg := 'N';  -- �P�P�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).dec_quant       := gn_0; -- �P�Q�� ����
              gr_add_total(l).dec_amount      := gn_0; -- �P�Q�� ���z
              gr_add_total(l).dec_price       := gn_0; -- �P�Q�� �i�ڒ艿
              gr_add_total(l).dec_to_amount   := gn_0; -- �P�Q�� ���󍇌v
              gr_add_total(l).dec_quant_t     := gn_0; -- �P�Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).dec_s_cost      := gn_0; -- �P�Q�� �W������(�v)
              gr_add_total(l).dec_calc        := gn_0; -- �P�Q�� �i�ڒ艿*����(�v)
              gr_add_total(l).dec_minus_flg   := 'N';  -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).dec_ht_zero_flg := 'N';  -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).jan_quant       := gn_0; -- �P�� ����
              gr_add_total(l).jan_amount      := gn_0; -- �P�� ���z
              gr_add_total(l).jan_price       := gn_0; -- �P�� �i�ڒ艿
              gr_add_total(l).jan_to_amount   := gn_0; -- �P�� ���󍇌v
              gr_add_total(l).jan_quant_t     := gn_0; -- �P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).jan_s_cost      := gn_0; -- �P�� �W������(�v)
              gr_add_total(l).jan_calc        := gn_0; -- �P�� �i�ڒ艿*����(�v)
              gr_add_total(l).jan_minus_flg   := 'N';  -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).jan_ht_zero_flg := 'N';  -- �P�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).feb_quant       := gn_0; -- �Q�� ����
              gr_add_total(l).feb_amount      := gn_0; -- �Q�� ���z
              gr_add_total(l).feb_price       := gn_0; -- �Q�� �i�ڒ艿
              gr_add_total(l).feb_to_amount   := gn_0; -- �Q�� ���󍇌v
              gr_add_total(l).feb_quant_t     := gn_0; -- �Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).feb_s_cost      := gn_0; -- �Q�� �W������(�v)
              gr_add_total(l).feb_calc        := gn_0; -- �Q�� �i�ڒ艿*����(�v)
              gr_add_total(l).feb_minus_flg   := 'N';  -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).feb_ht_zero_flg := 'N';  -- �Q�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).mar_quant       := gn_0; -- �R�� ����
              gr_add_total(l).mar_amount      := gn_0; -- �R�� ���z
              gr_add_total(l).mar_price       := gn_0; -- �R�� �i�ڒ艿
              gr_add_total(l).mar_to_amount   := gn_0; -- �R�� ���󍇌v
              gr_add_total(l).mar_quant_t     := gn_0; -- �R�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).mar_s_cost      := gn_0; -- �R�� �W������(�v)
              gr_add_total(l).mar_calc        := gn_0; -- �R�� �i�ڒ艿*����(�v)
              gr_add_total(l).mar_minus_flg   := 'N';  -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).mar_ht_zero_flg := 'N';  -- �R�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).apr_quant       := gn_0; -- �S�� ����
              gr_add_total(l).apr_amount      := gn_0; -- �S�� ���z
              gr_add_total(l).apr_price       := gn_0; -- �S�� �i�ڒ艿
              gr_add_total(l).apr_to_amount   := gn_0; -- �S�� ���󍇌v
              gr_add_total(l).apr_quant_t     := gn_0; -- �S�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).apr_s_cost      := gn_0; -- �S�� �W������(�v)
              gr_add_total(l).apr_calc        := gn_0; -- �S�� �i�ڒ艿*����(�v)
              gr_add_total(l).apr_minus_flg   := 'N';  -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).apr_ht_zero_flg := 'N';  -- �S�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).year_quant      := gn_0; -- �N�v ����
              gr_add_total(l).year_amount     := gn_0; -- �N�v ���z
              gr_add_total(l).year_price      := gn_0; -- �N�v �i�ڒ艿
              gr_add_total(l).year_to_amount  := gn_0; -- �N�v ���󍇌v
              gr_add_total(l).year_quant_t    := gn_0; -- �N�v ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).year_s_cost     := gn_0; -- �N�v �W������(�v)
              gr_add_total(l).year_calc       := gn_0; -- �N�v �i�ڒ艿*����(�v)
              gr_add_total(l).year_minus_flg   := 'N'; -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).year_ht_zero_flg := 'N'; -- �N�v �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            END LOOP add_total_loop;
          -- �f�[�^�Q���ڈȍ~�̏ꍇ
          ELSE
            <<add_total_loop>>
            FOR l IN 1..4 LOOP        -- ���Q�v/��Q�v/���_�v/���i�敪�v
              gr_add_total(l).may_quant       := gn_0; -- �T�� ����
              gr_add_total(l).may_amount      := gn_0; -- �T�� ���z
              gr_add_total(l).may_price       := gn_0; -- �T�� �i�ڒ艿
              gr_add_total(l).may_to_amount   := gn_0; -- �T�� ���󍇌v
              gr_add_total(l).may_quant_t     := gn_0; -- �T�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).may_s_cost      := gn_0; -- �T�� �W������(�v)
              gr_add_total(l).may_calc        := gn_0; -- �T�� �i�ڒ艿*����(�v)
              gr_add_total(l).may_minus_flg   := 'N';  -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).may_ht_zero_flg := 'N';  -- �T�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).jun_quant       := gn_0; -- �U�� ����
              gr_add_total(l).jun_amount      := gn_0; -- �U�� ���z
              gr_add_total(l).jun_price       := gn_0; -- �U�� �i�ڒ艿
              gr_add_total(l).jun_to_amount   := gn_0; -- �U�� ���󍇌v
              gr_add_total(l).jun_quant_t     := gn_0; -- �U�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).jun_s_cost      := gn_0; -- �U�� �W������(�v)
              gr_add_total(l).jun_calc        := gn_0; -- �U�� �i�ڒ艿*����(�v)
              gr_add_total(l).jun_minus_flg   := 'N';  -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).jun_ht_zero_flg := 'N';  -- �U�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).jul_quant       := gn_0; -- �V�� ����
              gr_add_total(l).jul_amount      := gn_0; -- �V�� ���z
              gr_add_total(l).jul_price       := gn_0; -- �V�� �i�ڒ艿
              gr_add_total(l).jul_to_amount   := gn_0; -- �V�� ���󍇌v
              gr_add_total(l).jul_quant_t     := gn_0; -- �V�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).jul_s_cost      := gn_0; -- �V�� �W������(�v)
              gr_add_total(l).jul_calc        := gn_0; -- �V�� �i�ڒ艿*����(�v)
              gr_add_total(l).jul_minus_flg   := 'N';  -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).jul_ht_zero_flg := 'N';  -- �V�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).aug_quant       := gn_0; -- �W�� ����
              gr_add_total(l).aug_amount      := gn_0; -- �W�� ���z
              gr_add_total(l).aug_price       := gn_0; -- �W�� �i�ڒ艿
              gr_add_total(l).aug_to_amount   := gn_0; -- �W�� ���󍇌v
              gr_add_total(l).aug_quant_t     := gn_0; -- �W�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).aug_s_cost      := gn_0; -- �W�� �W������(�v)
              gr_add_total(l).aug_calc        := gn_0; -- �W�� �i�ڒ艿*����(�v)
              gr_add_total(l).aug_minus_flg   := 'N';  -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).aug_ht_zero_flg := 'N';  -- �W�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).sep_quant       := gn_0; -- �X�� ����
              gr_add_total(l).sep_amount      := gn_0; -- �X�� ���z
              gr_add_total(l).sep_price       := gn_0; -- �X�� �i�ڒ艿
              gr_add_total(l).sep_to_amount   := gn_0; -- �X�� ���󍇌v
              gr_add_total(l).sep_quant_t     := gn_0; -- �X�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).sep_s_cost      := gn_0; -- �X�� �W������(�v)
              gr_add_total(l).sep_calc        := gn_0; -- �X�� �i�ڒ艿*����(�v)
              gr_add_total(l).sep_minus_flg   := 'N';  -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).sep_ht_zero_flg := 'N';  -- �X�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).oct_quant       := gn_0; -- �P�O�� ����
              gr_add_total(l).oct_amount      := gn_0; -- �P�O�� ���z
              gr_add_total(l).oct_price       := gn_0; -- �P�O�� �i�ڒ艿
              gr_add_total(l).oct_to_amount   := gn_0; -- �P�O�� ���󍇌v
              gr_add_total(l).oct_quant_t     := gn_0; -- �P�O�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).oct_s_cost      := gn_0; -- �P�O�� �W������(�v)
              gr_add_total(l).oct_calc        := gn_0; -- �P�O�� �i�ڒ艿*����(�v)
              gr_add_total(l).oct_minus_flg   := 'N';  -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).oct_ht_zero_flg := 'N';  -- �P�O�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).nov_quant       := gn_0; -- �P�P�� ����
              gr_add_total(l).nov_amount      := gn_0; -- �P�P�� ���z
              gr_add_total(l).nov_price       := gn_0; -- �P�P�� �i�ڒ艿
              gr_add_total(l).nov_to_amount   := gn_0; -- �P�P�� ���󍇌v
              gr_add_total(l).nov_quant_t     := gn_0; -- �P�P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).nov_s_cost      := gn_0; -- �P�P�� �W������(�v)
              gr_add_total(l).nov_calc        := gn_0; -- �P�P�� �i�ڒ艿*����(�v)
              gr_add_total(l).nov_minus_flg   := 'N';  -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).nov_ht_zero_flg := 'N';  -- �P�P�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).dec_quant       := gn_0; -- �P�Q�� ����
              gr_add_total(l).dec_amount      := gn_0; -- �P�Q�� ���z
              gr_add_total(l).dec_price       := gn_0; -- �P�Q�� �i�ڒ艿
              gr_add_total(l).dec_to_amount   := gn_0; -- �P�Q�� ���󍇌v
              gr_add_total(l).dec_quant_t     := gn_0; -- �P�Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).dec_s_cost      := gn_0; -- �P�Q�� �W������(�v)
              gr_add_total(l).dec_calc        := gn_0; -- �P�Q�� �i�ڒ艿*����(�v)
              gr_add_total(l).dec_minus_flg   := 'N';  -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).dec_ht_zero_flg := 'N';  -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).jan_quant       := gn_0; -- �P�� ����
              gr_add_total(l).jan_amount      := gn_0; -- �P�� ���z
              gr_add_total(l).jan_price       := gn_0; -- �P�� �i�ڒ艿
              gr_add_total(l).jan_to_amount   := gn_0; -- �P�� ���󍇌v
              gr_add_total(l).jan_quant_t     := gn_0; -- �P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).jan_s_cost      := gn_0; -- �P�� �W������(�v)
              gr_add_total(l).jan_calc        := gn_0; -- �P�� �i�ڒ艿*����(�v)
              gr_add_total(l).jan_minus_flg   := 'N';  -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).jan_ht_zero_flg := 'N';  -- �P�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).feb_quant       := gn_0; -- �Q�� ����
              gr_add_total(l).feb_amount      := gn_0; -- �Q�� ���z
              gr_add_total(l).feb_price       := gn_0; -- �Q�� �i�ڒ艿
              gr_add_total(l).feb_to_amount   := gn_0; -- �Q�� ���󍇌v
              gr_add_total(l).feb_quant_t     := gn_0; -- �Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).feb_s_cost      := gn_0; -- �Q�� �W������(�v)
              gr_add_total(l).feb_calc        := gn_0; -- �Q�� �i�ڒ艿*����(�v)
              gr_add_total(l).feb_minus_flg   := 'N';  -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).feb_ht_zero_flg := 'N';  -- �Q�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).mar_quant       := gn_0; -- �R�� ����
              gr_add_total(l).mar_amount      := gn_0; -- �R�� ���z
              gr_add_total(l).mar_price       := gn_0; -- �R�� �i�ڒ艿
              gr_add_total(l).mar_to_amount   := gn_0; -- �R�� ���󍇌v
              gr_add_total(l).mar_quant_t     := gn_0; -- �R�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).mar_s_cost      := gn_0; -- �R�� �W������(�v)
              gr_add_total(l).mar_calc        := gn_0; -- �R�� �i�ڒ艿*����(�v)
              gr_add_total(l).mar_minus_flg   := 'N';  -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).mar_ht_zero_flg := 'N';  -- �R�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).apr_quant       := gn_0; -- �S�� ����
              gr_add_total(l).apr_amount      := gn_0; -- �S�� ���z
              gr_add_total(l).apr_price       := gn_0; -- �S�� �i�ڒ艿
              gr_add_total(l).apr_to_amount   := gn_0; -- �S�� ���󍇌v
              gr_add_total(l).apr_quant_t     := gn_0; -- �S�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).apr_s_cost      := gn_0; -- �S�� �W������(�v)
              gr_add_total(l).apr_calc        := gn_0; -- �S�� �i�ڒ艿*����(�v)
              gr_add_total(l).apr_minus_flg   := 'N';  -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).apr_ht_zero_flg := 'N';  -- �S�� �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              gr_add_total(l).year_quant      := gn_0; -- �N�v ����
              gr_add_total(l).year_amount     := gn_0; -- �N�v ���z
              gr_add_total(l).year_price      := gn_0; -- �N�v �i�ڒ艿
              gr_add_total(l).year_to_amount  := gn_0; -- �N�v ���󍇌v
              gr_add_total(l).year_quant_t    := gn_0; -- �N�v ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              gr_add_total(l).year_s_cost     := gn_0; -- �N�v �W������(�v)
              gr_add_total(l).year_calc       := gn_0; -- �N�v �i�ڒ艿*����(�v)
              gr_add_total(l).year_minus_flg   := 'N'; -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v)
              gr_add_total(l).year_ht_zero_flg := 'N'; -- �N�v �i�ڒ艿0�l���݃t���O(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            END LOOP add_total_loop;
          END IF;
--
          -- �N�v������
          ln_year_quant_sum  := gn_0;           -- ����
          ln_year_amount_sum := gn_0;           -- ���z
          ln_year_to_am_sum  := gn_0;           -- ���󍇌v
          ln_year_price_sum  := gn_0;           -- �i�ڒ艿
--
          -- XML�o�̓t���O������
          <<xml_out_loop>>
          FOR n IN 1..12 LOOP
            gr_xml_out(n).out_fg   := lv_no;
          END LOOP xml_out_loop;
--
        END IF;
--
        -- ====================================================
        --  (���_����)���_�u���C�N
        -- ====================================================
        -- ���_���؂�ւ�����Ƃ�
        IF (gr_sale_plan_1(i).ktn_code <> lv_ktn_break) THEN
          -------------------------------------------------------
          -- �e�����o�f�[�^�����݂��Ȃ��ꍇ�A0�\���ɂ�XML�o��  --
          -------------------------------------------------------
          <<xml_out_0_loop>>
          FOR m IN 1..12 LOOP
            IF (gr_xml_out(m).out_fg = lv_no) THEN
              prc_create_xml_data_dtl_n
                (
                  iv_label_name     => gr_xml_out(m).tag_name                      -- �o�̓^�O��
                 ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          END LOOP xml_out_0_loop;
--
          -- -----------------------------------------------------
          -- (���_����)�N�v ���ʃf�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
          -- -----------------------------------------------------
          -- (���_����)�N�v ���z�f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
          -- -----------------------------------------------------
          -- (���_����)�N�v �e�����f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          ------------------------------------------------
          -- (���_����)�e���v�Z (���z�|���󍇌v������)  --
          ------------------------------------------------
          ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
          -- �O���Z��𔻒�
          IF (ln_year_amount_sum <> gn_0) THEN
          -- �l��[0]�o�Ȃ���Όv�Z
          gt_xml_data_table(gl_xml_idx).tag_value := 
                    ROUND((ln_arari / ln_year_amount_sum * 100),2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
          END IF;
--
          -- -----------------------------------------------------
          -- (���_����)�N�v �|���f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          --------------------------------------
          -- �O���Z���荀�ڂ֔���l��}��     --
          --------------------------------------
          ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> gn_0) THEN
          -- �l��[0]�o�Ȃ���Όv�Z
          ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_kake_par := gn_0;
          END IF;
--
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
          IF ((ln_year_price_sum = 0)
            OR (ln_kake_par < 0)) THEN
            ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
          END IF;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).year_quant     :=
               gr_add_total(r).year_quant     + ln_year_quant_sum;        -- ����
            gr_add_total(r).year_amount    :=
               gr_add_total(r).year_amount    + ln_year_amount_sum;       -- ���z
            gr_add_total(r).year_price     :=
               gr_add_total(r).year_price     + ln_year_price_sum;        -- �i�ڒ艿
            gr_add_total(r).year_to_amount :=
               gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- ���󍇌v
            gr_add_total(r).year_quant_t   :=
               gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- ����(�v)
          END LOOP add_total_loop;
--
          -- -----------------------------------------------------
          --  (���_����)�i�ڏI���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- ----------------------------------------------------
          --  (���_����)�i�ڏI���k�f�^�O�o��
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start
/*
          --------------------------------------------------------
          -- XML�f�[�^�쐬 - ���[�f�[�^�o�� ���Q�v
          --------------------------------------------------------
          prc_create_xml_data_st_lt
            (
              iv_label_name     => gv_name_st                     -- ���Q�v�p�^�O��
             ,iv_name           => gv_label_st                    -- ���Q�v�^�C�g��
             ,in_may_quant      => gr_add_total(1).may_quant      -- �T�� ����
             ,in_may_amount     => gr_add_total(1).may_amount     -- �T�� ���z
             ,in_may_price      => gr_add_total(1).may_price      -- �T�� �i�ڒ艿
             ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- �T�� ���󍇌v
             ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- �T�� ����(�v�Z�p)
             ,in_jun_quant      => gr_add_total(1).jun_quant      -- �U�� ����
             ,in_jun_amount     => gr_add_total(1).jun_amount     -- �U�� ���z
             ,in_jun_price      => gr_add_total(1).jun_price      -- �U�� �i�ڒ艿
             ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- �U�� ���󍇌v
             ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- �U�� ����(�v�Z�p)
             ,in_jul_quant      => gr_add_total(1).jul_quant      -- �V�� ����
             ,in_jul_amount     => gr_add_total(1).jul_amount     -- �V�� ���z
             ,in_jul_price      => gr_add_total(1).jul_price      -- �V�� �i�ڒ艿
             ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- �V�� ���󍇌v
             ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- �V�� ����(�v�Z�p)
             ,in_aug_quant      => gr_add_total(1).aug_quant      -- �W�� ����
             ,in_aug_amount     => gr_add_total(1).aug_amount     -- �W�� ���z
             ,in_aug_price      => gr_add_total(1).aug_price      -- �W�� �i�ڒ艿
             ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- �W�� ���󍇌v
             ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- �W�� ����(�v�Z�p)
             ,in_sep_quant      => gr_add_total(1).sep_quant      -- �X�� ����
             ,in_sep_amount     => gr_add_total(1).sep_amount     -- �X�� ���z
             ,in_sep_price      => gr_add_total(1).sep_price      -- �X�� �i�ڒ艿
             ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- �X�� ���󍇌v
             ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- �X�� ����(�v�Z�p)
             ,in_oct_quant      => gr_add_total(1).oct_quant      -- �P�O�� ����
             ,in_oct_amount     => gr_add_total(1).oct_amount     -- �P�O�� ���z
             ,in_oct_price      => gr_add_total(1).oct_price      -- �P�O�� �i�ڒ艿
             ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- �P�O�� ���󍇌v
             ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- �P�O�� ����(�v�Z�p)
             ,in_nov_quant      => gr_add_total(1).nov_quant      -- �P�P�� ����
             ,in_nov_amount     => gr_add_total(1).nov_amount     -- �P�P�� ���z
             ,in_nov_price      => gr_add_total(1).nov_price      -- �P�P�� �i�ڒ艿
             ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- �P�P�� ���󍇌v
             ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- �P�P�� ����(�v�Z�p)
             ,in_dec_quant      => gr_add_total(1).dec_quant      -- �P�Q�� ����
             ,in_dec_amount     => gr_add_total(1).dec_amount     -- �P�Q�� ���z
             ,in_dec_price      => gr_add_total(1).dec_price      -- �P�Q�� �i�ڒ艿
             ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- �P�Q�� ���󍇌v
             ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
             ,in_jan_quant      => gr_add_total(1).jan_quant      -- �P�� ����
             ,in_jan_amount     => gr_add_total(1).jan_amount     -- �P�� ���z
             ,in_jan_price      => gr_add_total(1).jan_price      -- �P�� �i�ڒ艿
             ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- �P�� ���󍇌v
             ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- �P�� ����(�v�Z�p)
             ,in_feb_quant      => gr_add_total(1).feb_quant      -- �Q�� ����
             ,in_feb_amount     => gr_add_total(1).feb_amount     -- �Q�� ���z
             ,in_feb_price      => gr_add_total(1).feb_price      -- �Q�� �i�ڒ艿
             ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- �Q�� ���󍇌v
             ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- �Q�� ����(�v�Z�p)
             ,in_mar_quant      => gr_add_total(1).mar_quant      -- �R�� ����
             ,in_mar_amount     => gr_add_total(1).mar_amount     -- �R�� ���z
             ,in_mar_price      => gr_add_total(1).mar_price      -- �R�� �i�ڒ艿
             ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- �R�� ���󍇌v
             ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- �R�� ����(�v�Z�p)
             ,in_apr_quant      => gr_add_total(1).apr_quant      -- �S�� ����
             ,in_apr_amount     => gr_add_total(1).apr_amount     -- �S�� ���z
             ,in_apr_price      => gr_add_total(1).apr_price      -- �S�� �i�ڒ艿
             ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- �S�� ���󍇌v
             ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- �S�� ����(�v�Z�p)
             ,in_year_quant     => gr_add_total(1).year_quant     -- �N�v ����
             ,in_year_amount    => gr_add_total(1).year_amount    -- �N�v ���z
             ,in_year_price     => gr_add_total(1).year_price     -- �N�v �i�ڒ艿
             ,in_year_to_amount => gr_add_total(1).year_to_amount -- �N�v ���󍇌v
             ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- �N�v ����(�v�Z�p)
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
             );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          --------------------------------------------------------
          -- ��Q�v�f�[�^�o�� 
          --------------------------------------------------------
          prc_create_xml_data_st_lt
            (
              iv_label_name     => gv_name_lt                     -- ��Q�v�p�^�O��
             ,iv_name           => gv_label_lt                    -- ��Q�v�^�C�g��
             ,in_may_quant      => gr_add_total(2).may_quant      -- �T�� ����
             ,in_may_amount     => gr_add_total(2).may_amount     -- �T�� ���z
             ,in_may_price      => gr_add_total(2).may_price      -- �T�� �i�ڒ艿
             ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- �T�� ���󍇌v
             ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- �T�� ����(�v�Z�p)
             ,in_jun_quant      => gr_add_total(2).jun_quant      -- �U�� ����
             ,in_jun_amount     => gr_add_total(2).jun_amount     -- �U�� ���z
             ,in_jun_price      => gr_add_total(2).jun_price      -- �U�� �i�ڒ艿
             ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- �U�� ���󍇌v
             ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- �U�� ����(�v�Z�p)
             ,in_jul_quant      => gr_add_total(2).jul_quant      -- �V�� ����
             ,in_jul_amount     => gr_add_total(2).jul_amount     -- �V�� ���z
             ,in_jul_price      => gr_add_total(2).jul_price      -- �V�� �i�ڒ艿
             ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- �V�� ���󍇌v
             ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- �V�� ����(�v�Z�p)
             ,in_aug_quant      => gr_add_total(2).aug_quant      -- �W�� ����
             ,in_aug_amount     => gr_add_total(2).aug_amount     -- �W�� ���z
             ,in_aug_price      => gr_add_total(2).aug_price      -- �W�� �i�ڒ艿
             ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- �W�� ���󍇌v
             ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- �W�� ����(�v�Z�p)
             ,in_sep_quant      => gr_add_total(2).sep_quant      -- �X�� ����
             ,in_sep_amount     => gr_add_total(2).sep_amount     -- �X�� ���z
             ,in_sep_price      => gr_add_total(2).sep_price      -- �X�� �i�ڒ艿
             ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- �X�� ���󍇌v
             ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- �X�� ����(�v�Z�p)
             ,in_oct_quant      => gr_add_total(2).oct_quant      -- �P�O�� ����
             ,in_oct_amount     => gr_add_total(2).oct_amount     -- �P�O�� ���z
             ,in_oct_price      => gr_add_total(2).oct_price      -- �P�O�� �i�ڒ艿
             ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- �P�O�� ���󍇌v
             ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- �P�O�� ����(�v�Z�p)
             ,in_nov_quant      => gr_add_total(2).nov_quant      -- �P�P�� ����
             ,in_nov_amount     => gr_add_total(2).nov_amount     -- �P�P�� ���z
             ,in_nov_price      => gr_add_total(2).nov_price      -- �P�P�� �i�ڒ艿
             ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- �P�P�� ���󍇌v
             ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- �P�P�� ����(�v�Z�p)
             ,in_dec_quant      => gr_add_total(2).dec_quant      -- �P�Q�� ����
             ,in_dec_amount     => gr_add_total(2).dec_amount     -- �P�Q�� ���z
             ,in_dec_price      => gr_add_total(2).dec_price      -- �P�Q�� �i�ڒ艿
             ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- �P�Q�� ���󍇌v
             ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
             ,in_jan_quant      => gr_add_total(2).jan_quant      -- �P�� ����
             ,in_jan_amount     => gr_add_total(2).jan_amount     -- �P�� ���z
             ,in_jan_price      => gr_add_total(2).jan_price      -- �P�� �i�ڒ艿
             ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- �P�� ���󍇌v
             ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- �P�� ����(�v�Z�p)
             ,in_feb_quant      => gr_add_total(2).feb_quant      -- �Q�� ����
             ,in_feb_amount     => gr_add_total(2).feb_amount     -- �Q�� ���z
             ,in_feb_price      => gr_add_total(2).feb_price      -- �Q�� �i�ڒ艿
             ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- �Q�� ���󍇌v
             ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- �Q�� ����(�v�Z�p)
             ,in_mar_quant      => gr_add_total(2).mar_quant      -- �R�� ����
             ,in_mar_amount     => gr_add_total(2).mar_amount     -- �R�� ���z
             ,in_mar_price      => gr_add_total(2).mar_price      -- �R�� �i�ڒ艿
             ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- �R�� ���󍇌v
             ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- �R�� ����(�v�Z�p)
             ,in_apr_quant      => gr_add_total(2).apr_quant      -- �S�� ����
             ,in_apr_amount     => gr_add_total(2).apr_amount     -- �S�� ���z
             ,in_apr_price      => gr_add_total(2).apr_price      -- �S�� �i�ڒ艿
             ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- �S�� ���󍇌v
             ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- �S�� ����(�v�Z�p)
             ,in_year_quant     => gr_add_total(2).year_quant     -- �N�v ����
             ,in_year_amount    => gr_add_total(2).year_amount    -- �N�v ���z
             ,in_year_price     => gr_add_total(2).year_price     -- �N�v �i�ڒ艿
             ,in_year_to_amount => gr_add_total(2).year_to_amount -- �N�v ���󍇌v
             ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- �N�v ����(�v�Z�p)
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
*/
          --------------------------------------------------------
          -- (���_����)(1)���Q�v/(2)��Q�v�f�[�^�o�� 
          --------------------------------------------------------
          <<gun_loop>>
          FOR n IN 1..2 LOOP        -- ���Q�v/��Q�v
--
            -- ���Q�v�̏ꍇ
            IF ( n = 1) THEN
              lv_param_name  := gv_name_st;
              lv_param_label := gv_label_st;
            -- ��Q�v�̏ꍇ
            ELSE
              lv_param_name  := gv_name_lt;
              lv_param_label := gv_label_lt;
            END IF;
--
            prc_create_xml_data_st_lt
            (
                iv_label_name      => lv_param_name                   -- ��Q�v�p�^�O��
              ,iv_name            => lv_param_label                  -- ��Q�v�^�C�g��
              ,in_may_quant       => gr_add_total(n).may_quant       -- �T�� ����
              ,in_may_amount      => gr_add_total(n).may_amount      -- �T�� ���z
              ,in_may_price       => gr_add_total(n).may_price       -- �T�� �i�ڒ艿
              ,in_may_to_amount   => gr_add_total(n).may_to_amount   -- �T�� ���󍇌v
              ,in_may_quant_t     => gr_add_total(n).may_quant_t     -- �T�� ����(�v�Z�p)
              ,in_may_s_cost      => gr_add_total(n).may_s_cost      -- �T�� �W������(�v�Z�p)
              ,in_may_calc        => gr_add_total(n).may_calc        -- �T�� �i�ڒ艿*����(�v�Z�p)
              ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
              ,in_jun_quant       => gr_add_total(n).jun_quant       -- �U�� ����
              ,in_jun_amount      => gr_add_total(n).jun_amount      -- �U�� ���z
              ,in_jun_price       => gr_add_total(n).jun_price       -- �U�� �i�ڒ艿
              ,in_jun_to_amount   => gr_add_total(n).jun_to_amount   -- �U�� ���󍇌v
              ,in_jun_quant_t     => gr_add_total(n).jun_quant_t     -- �U�� ����(�v�Z�p)
              ,in_jun_s_cost      => gr_add_total(n).jun_s_cost      -- �U�� �W������(�v�Z�p)
              ,in_jun_calc        => gr_add_total(n).jun_calc        -- �U�� �i�ڒ艿*����(�v�Z�p)
              ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
              ,in_jul_quant       => gr_add_total(n).jul_quant       -- �V�� ����
              ,in_jul_amount      => gr_add_total(n).jul_amount      -- �V�� ���z
              ,in_jul_price       => gr_add_total(n).jul_price       -- �V�� �i�ڒ艿
              ,in_jul_to_amount   => gr_add_total(n).jul_to_amount   -- �V�� ���󍇌v
              ,in_jul_quant_t     => gr_add_total(n).jul_quant_t     -- �V�� ����(�v�Z�p)
              ,in_jul_s_cost      => gr_add_total(n).jul_s_cost      -- �V�� �W������(�v�Z�p)
              ,in_jul_calc        => gr_add_total(n).jul_calc        -- �V�� �i�ڒ艿*����(�v�Z�p)
              ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
              ,in_aug_quant       => gr_add_total(n).aug_quant       -- �W�� ����
              ,in_aug_amount      => gr_add_total(n).aug_amount      -- �W�� ���z
              ,in_aug_price       => gr_add_total(n).aug_price       -- �W�� �i�ڒ艿
              ,in_aug_to_amount   => gr_add_total(n).aug_to_amount   -- �W�� ���󍇌v
              ,in_aug_quant_t     => gr_add_total(n).aug_quant_t     -- �W�� ����(�v�Z�p)
              ,in_aug_s_cost      => gr_add_total(n).aug_s_cost      -- �W�� �W������(�v�Z�p)
              ,in_aug_calc        => gr_add_total(n).aug_calc        -- �W�� �i�ڒ艿*����(�v�Z�p)
              ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
              ,in_sep_quant       => gr_add_total(n).sep_quant       -- �X�� ����
              ,in_sep_amount      => gr_add_total(n).sep_amount      -- �X�� ���z
              ,in_sep_price       => gr_add_total(n).sep_price       -- �X�� �i�ڒ艿
              ,in_sep_to_amount   => gr_add_total(n).sep_to_amount   -- �X�� ���󍇌v
              ,in_sep_quant_t     => gr_add_total(n).sep_quant_t     -- �X�� ����(�v�Z�p)
              ,in_sep_s_cost      => gr_add_total(n).sep_s_cost      -- �X�� �W������(�v�Z�p)
              ,in_sep_calc        => gr_add_total(n).sep_calc        -- �X�� �i�ڒ艿*����(�v�Z�p)
              ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
              ,in_oct_quant       => gr_add_total(n).oct_quant       -- �P�O�� ����
              ,in_oct_amount      => gr_add_total(n).oct_amount      -- �P�O�� ���z
              ,in_oct_price       => gr_add_total(n).oct_price       -- �P�O�� �i�ڒ艿
              ,in_oct_to_amount   => gr_add_total(n).oct_to_amount   -- �P�O�� ���󍇌v
              ,in_oct_quant_t     => gr_add_total(n).oct_quant_t     -- �P�O�� ����(�v�Z�p)
              ,in_oct_s_cost      => gr_add_total(n).oct_s_cost      -- �P�O�� �W������(�v�Z�p)
              ,in_oct_calc        => gr_add_total(n).oct_calc        -- �P�O�� �i�ڒ艿*����(�v�Z�p)
              ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
              ,in_nov_quant       => gr_add_total(n).nov_quant       -- �P�P�� ����
              ,in_nov_amount      => gr_add_total(n).nov_amount      -- �P�P�� ���z
              ,in_nov_price       => gr_add_total(n).nov_price       -- �P�P�� �i�ڒ艿
              ,in_nov_to_amount   => gr_add_total(n).nov_to_amount   -- �P�P�� ���󍇌v
              ,in_nov_quant_t     => gr_add_total(n).nov_quant_t     -- �P�P�� ����(�v�Z�p)
              ,in_nov_s_cost      => gr_add_total(n).nov_s_cost      -- �P�P�� �W������(�v�Z�p)
              ,in_nov_calc        => gr_add_total(n).nov_calc        -- �P�P�� �i�ڒ艿*����(�v�Z�p)
              ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
              ,in_dec_quant       => gr_add_total(n).dec_quant       -- �P�Q�� ����
              ,in_dec_amount      => gr_add_total(n).dec_amount      -- �P�Q�� ���z
              ,in_dec_price       => gr_add_total(n).dec_price       -- �P�Q�� �i�ڒ艿
              ,in_dec_to_amount   => gr_add_total(n).dec_to_amount   -- �P�Q�� ���󍇌v
              ,in_dec_quant_t     => gr_add_total(n).dec_quant_t     -- �P�Q�� ����(�v�Z�p)
              ,in_dec_s_cost      => gr_add_total(n).dec_s_cost      -- �P�Q�� �W������(�v�Z�p)
              ,in_dec_calc        => gr_add_total(n).dec_calc        -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
              ,in_jan_quant       => gr_add_total(n).jan_quant       -- �P�� ����
              ,in_jan_amount      => gr_add_total(n).jan_amount      -- �P�� ���z
              ,in_jan_price       => gr_add_total(n).jan_price       -- �P�� �i�ڒ艿
              ,in_jan_to_amount   => gr_add_total(n).jan_to_amount   -- �P�� ���󍇌v
              ,in_jan_quant_t     => gr_add_total(n).jan_quant_t     -- �P�� ����(�v�Z�p)
              ,in_jan_s_cost      => gr_add_total(n).jan_s_cost      -- �P�� �W������(�v�Z�p)
              ,in_jan_calc        => gr_add_total(n).jan_calc        -- �P�� �i�ڒ艿*����(�v�Z�p)
              ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
              ,in_feb_quant       => gr_add_total(n).feb_quant       -- �Q�� ����
              ,in_feb_amount      => gr_add_total(n).feb_amount      -- �Q�� ���z
              ,in_feb_price       => gr_add_total(n).feb_price       -- �Q�� �i�ڒ艿
              ,in_feb_to_amount   => gr_add_total(n).feb_to_amount   -- �Q�� ���󍇌v
              ,in_feb_quant_t     => gr_add_total(n).feb_quant_t     -- �Q�� ����(�v�Z�p)
              ,in_feb_s_cost      => gr_add_total(n).feb_s_cost      -- �Q�� �W������(�v�Z�p)
              ,in_feb_calc        => gr_add_total(n).feb_calc        -- �Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
              ,in_mar_quant       => gr_add_total(n).mar_quant       -- �R�� ����
              ,in_mar_amount      => gr_add_total(n).mar_amount      -- �R�� ���z
              ,in_mar_price       => gr_add_total(n).mar_price       -- �R�� �i�ڒ艿
              ,in_mar_to_amount   => gr_add_total(n).mar_to_amount   -- �R�� ���󍇌v
              ,in_mar_quant_t     => gr_add_total(n).mar_quant_t     -- �R�� ����(�v�Z�p)
              ,in_mar_s_cost      => gr_add_total(n).mar_s_cost      -- �R�� �W������(�v�Z�p)
              ,in_mar_calc        => gr_add_total(n).mar_calc        -- �R�� �i�ڒ艿*����(�v�Z�p)
              ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
              ,in_apr_quant       => gr_add_total(n).apr_quant       -- �S�� ����
              ,in_apr_amount      => gr_add_total(n).apr_amount      -- �S�� ���z
              ,in_apr_price       => gr_add_total(n).apr_price       -- �S�� �i�ڒ艿
              ,in_apr_to_amount   => gr_add_total(n).apr_to_amount   -- �S�� ���󍇌v
              ,in_apr_quant_t     => gr_add_total(n).apr_quant_t     -- �S�� ����(�v�Z�p)
              ,in_apr_s_cost      => gr_add_total(n).apr_s_cost      -- �S�� �W������(�v�Z�p)
              ,in_apr_calc        => gr_add_total(n).apr_calc        -- �S�� �i�ڒ艿*����(�v�Z�p)
              ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
              ,in_year_quant      => gr_add_total(n).year_quant        -- �N�v ����
              ,in_year_amount     => gr_add_total(n).year_amount       -- �N�v ���z
              ,in_year_price      => gr_add_total(n).year_price        -- �N�v �i�ڒ艿
              ,in_year_to_amount  => gr_add_total(n).year_to_amount    -- �N�v ���󍇌v
              ,in_year_quant_t    => gr_add_total(n).year_quant_t      -- �N�v ����(�v�Z�p)
              ,in_year_s_cost     => gr_add_total(n).year_s_cost       -- �N�v �W������(�v�Z�p)
              ,in_year_calc       => gr_add_total(n).year_calc         -- �N�v �i�ڒ艿*����(�v�Z�p)
              ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
              ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
          END LOOP gun_loop;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
--
          -- -----------------------------------------------------
          --  (���_����)�Q�R�[�h�I���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (���_����)�Q�R�[�h�I���k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          --------------------------------------------------------
          -- (���_����)���_�v�f�[�^�^�O�o�� 
          --------------------------------------------------------
          prc_create_xml_data_s_k_t
          (
             iv_label_name     => gv_name_ktn                    -- ���_�v�p�^�O��
            ,in_may_quant      => gr_add_total(3).may_quant      -- �T�� ����
            ,in_may_amount     => gr_add_total(3).may_amount     -- �T�� ���z
            ,in_may_price      => gr_add_total(3).may_price      -- �T�� �i�ڒ艿
            ,in_may_to_amount  => gr_add_total(3).may_to_amount  -- �T�� ���󍇌v
            ,in_may_quant_t    => gr_add_total(3).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            ,in_may_s_cost     => gr_add_total(3).may_s_cost     -- �T�� �W������(�v�Z�p)
            ,in_may_calc       => gr_add_total(3).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
            ,in_may_minus_flg   => gr_add_total(3).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            ,in_may_ht_zero_flg => gr_add_total(3).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            ,in_jun_quant      => gr_add_total(3).jun_quant      -- �U�� ����
            ,in_jun_amount     => gr_add_total(3).jun_amount     -- �U�� ���z
            ,in_jun_price      => gr_add_total(3).jun_price      -- �U�� �i�ڒ艿
            ,in_jun_to_amount  => gr_add_total(3).jun_to_amount  -- �U�� ���󍇌v
            ,in_jun_quant_t    => gr_add_total(3).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            ,in_jun_s_cost     => gr_add_total(3).jun_s_cost     -- �U�� �W������(�v�Z�p)
            ,in_jun_calc       => gr_add_total(3).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
            ,in_jun_minus_flg   => gr_add_total(3).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            ,in_jun_ht_zero_flg => gr_add_total(3).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            ,in_jul_quant      => gr_add_total(3).jul_quant      -- �V�� ����
            ,in_jul_amount     => gr_add_total(3).jul_amount     -- �V�� ���z
            ,in_jul_price      => gr_add_total(3).jul_price      -- �V�� �i�ڒ艿
            ,in_jul_to_amount  => gr_add_total(3).jul_to_amount  -- �V�� ���󍇌v
            ,in_jul_quant_t    => gr_add_total(3).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            ,in_jul_s_cost     => gr_add_total(3).jul_s_cost     -- �V�� �W������(�v�Z�p)
            ,in_jul_calc       => gr_add_total(3).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
            ,in_jul_minus_flg   => gr_add_total(3).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            ,in_jul_ht_zero_flg => gr_add_total(3).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            ,in_aug_quant      => gr_add_total(3).aug_quant      -- �W�� ����
            ,in_aug_amount     => gr_add_total(3).aug_amount     -- �W�� ���z
            ,in_aug_price      => gr_add_total(3).aug_price      -- �W�� �i�ڒ艿
            ,in_aug_to_amount  => gr_add_total(3).aug_to_amount  -- �W�� ���󍇌v
            ,in_aug_quant_t    => gr_add_total(3).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            ,in_aug_s_cost     => gr_add_total(3).aug_s_cost     -- �W�� �W������(�v�Z�p)
            ,in_aug_calc       => gr_add_total(3).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
            ,in_aug_minus_flg   => gr_add_total(3).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            ,in_aug_ht_zero_flg => gr_add_total(3).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            ,in_sep_quant      => gr_add_total(3).sep_quant      -- �X�� ����
            ,in_sep_amount     => gr_add_total(3).sep_amount     -- �X�� ���z
            ,in_sep_price      => gr_add_total(3).sep_price      -- �X�� �i�ڒ艿
            ,in_sep_to_amount  => gr_add_total(3).sep_to_amount  -- �X�� ���󍇌v
            ,in_sep_quant_t    => gr_add_total(3).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            ,in_sep_s_cost     => gr_add_total(3).sep_s_cost     -- �X�� �W������(�v�Z�p)
            ,in_sep_calc       => gr_add_total(3).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
            ,in_sep_minus_flg   => gr_add_total(3).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            ,in_sep_ht_zero_flg => gr_add_total(3).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            ,in_oct_quant      => gr_add_total(3).oct_quant      -- �P�O�� ����
            ,in_oct_amount     => gr_add_total(3).oct_amount     -- �P�O�� ���z
            ,in_oct_price      => gr_add_total(3).oct_price      -- �P�O�� �i�ڒ艿
            ,in_oct_to_amount  => gr_add_total(3).oct_to_amount  -- �P�O�� ���󍇌v
            ,in_oct_quant_t    => gr_add_total(3).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            ,in_oct_s_cost     => gr_add_total(3).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
            ,in_oct_calc       => gr_add_total(3).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
            ,in_oct_minus_flg   => gr_add_total(3).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            ,in_oct_ht_zero_flg => gr_add_total(3).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            ,in_nov_quant      => gr_add_total(3).nov_quant      -- �P�P�� ����
            ,in_nov_amount     => gr_add_total(3).nov_amount     -- �P�P�� ���z
            ,in_nov_price      => gr_add_total(3).nov_price      -- �P�P�� �i�ڒ艿
            ,in_nov_to_amount  => gr_add_total(3).nov_to_amount  -- �P�P�� ���󍇌v
            ,in_nov_quant_t    => gr_add_total(3).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            ,in_nov_s_cost     => gr_add_total(3).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
            ,in_nov_calc       => gr_add_total(3).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
            ,in_nov_minus_flg   => gr_add_total(3).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            ,in_nov_ht_zero_flg => gr_add_total(3).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            ,in_dec_quant      => gr_add_total(3).dec_quant      -- �P�Q�� ����
            ,in_dec_amount     => gr_add_total(3).dec_amount     -- �P�Q�� ���z
            ,in_dec_price      => gr_add_total(3).dec_price      -- �P�Q�� �i�ڒ艿
            ,in_dec_to_amount  => gr_add_total(3).dec_to_amount  -- �P�Q�� ���󍇌v
            ,in_dec_quant_t    => gr_add_total(3).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            ,in_dec_s_cost     => gr_add_total(3).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
            ,in_dec_calc       => gr_add_total(3).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
            ,in_dec_minus_flg   => gr_add_total(3).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            ,in_dec_ht_zero_flg => gr_add_total(3).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            ,in_jan_quant      => gr_add_total(3).jan_quant      -- �P�� ����
            ,in_jan_amount     => gr_add_total(3).jan_amount     -- �P�� ���z
            ,in_jan_price      => gr_add_total(3).jan_price      -- �P�� �i�ڒ艿
            ,in_jan_to_amount  => gr_add_total(3).jan_to_amount  -- �P�� ���󍇌v
            ,in_jan_quant_t    => gr_add_total(3).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            ,in_jan_s_cost     => gr_add_total(3).jan_s_cost     -- �P�� �W������(�v�Z�p)
            ,in_jan_calc       => gr_add_total(3).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
            ,in_jan_minus_flg   => gr_add_total(3).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            ,in_jan_ht_zero_flg => gr_add_total(3).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            ,in_feb_quant      => gr_add_total(3).feb_quant      -- �Q�� ����
            ,in_feb_amount     => gr_add_total(3).feb_amount     -- �Q�� ���z
            ,in_feb_price      => gr_add_total(3).feb_price      -- �Q�� �i�ڒ艿
            ,in_feb_to_amount  => gr_add_total(3).feb_to_amount  -- �Q�� ���󍇌v
            ,in_feb_quant_t    => gr_add_total(3).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            ,in_feb_s_cost     => gr_add_total(3).feb_s_cost     -- �Q�� �W������(�v�Z�p)
            ,in_feb_calc       => gr_add_total(3).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
            ,in_feb_minus_flg   => gr_add_total(3).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            ,in_feb_ht_zero_flg => gr_add_total(3).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            ,in_mar_quant      => gr_add_total(3).mar_quant      -- �R�� ����
            ,in_mar_amount     => gr_add_total(3).mar_amount     -- �R�� ���z
            ,in_mar_price      => gr_add_total(3).mar_price      -- �R�� �i�ڒ艿
            ,in_mar_to_amount  => gr_add_total(3).mar_to_amount  -- �R�� ���󍇌v
            ,in_mar_quant_t    => gr_add_total(3).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            ,in_mar_s_cost     => gr_add_total(3).mar_s_cost     -- �R�� �W������(�v�Z�p)
            ,in_mar_calc       => gr_add_total(3).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
            ,in_mar_minus_flg   => gr_add_total(3).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            ,in_mar_ht_zero_flg => gr_add_total(3).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            ,in_apr_quant      => gr_add_total(3).apr_quant      -- �S�� ����
            ,in_apr_amount     => gr_add_total(3).apr_amount     -- �S�� ���z
            ,in_apr_price      => gr_add_total(3).apr_price      -- �S�� �i�ڒ艿
            ,in_apr_to_amount  => gr_add_total(3).apr_to_amount  -- �S�� ���󍇌v
            ,in_apr_quant_t    => gr_add_total(3).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            ,in_apr_s_cost     => gr_add_total(3).apr_s_cost     -- �S�� �W������(�v�Z�p)
            ,in_apr_calc       => gr_add_total(3).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
            ,in_apr_minus_flg   => gr_add_total(3).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            ,in_apr_ht_zero_flg => gr_add_total(3).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            ,in_year_quant     => gr_add_total(3).year_quant     -- �N�v ����
            ,in_year_amount    => gr_add_total(3).year_amount    -- �N�v ���z
            ,in_year_price     => gr_add_total(3).year_price     -- �N�v �i�ڒ艿
            ,in_year_to_amount => gr_add_total(3).year_to_amount -- �N�v ���󍇌v
            ,in_year_quant_t   => gr_add_total(3).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            ,in_year_s_cost    => gr_add_total(3).year_s_cost    -- �N�v �W������(�v�Z�p)
            ,in_year_calc      => gr_add_total(3).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
            ,in_year_minus_flg   => gr_add_total(3).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            ,in_year_ht_zero_flg => gr_add_total(3).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- -----------------------------------------------------
          --  (���_����)���_�I���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (���_����)���_�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ----------------------------------------------------------------
          -- (���_����)���_�敪(���_�R�[�h) �^�O
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).ktn_code;
--
          ----------------------------------------------------------------
          -- (���_����)���_�敪(���_����) �^�O
          ----------------------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ktn_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).party_short_name;
--
          -- -----------------------------------------------------
          --  (���_����)�Q�R�[�h�J�nL�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (���_����)�Q�R�[�h�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (���_����)�i�ڊJ�n�k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- �e�u���C�N�L�[�X�V
          lv_ktn_break  := gr_sale_plan_1(i).ktn_code;          -- ���_
          lv_gun_break  := gr_sale_plan_1(i).gun;               -- �Q�R�[�h
          lv_dtl_break  := lv_break_init;                       -- �i�ڃR�[�h
          lv_sttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,3);  -- ���Q�v
          lv_lttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,1);  -- ��Q�v
--
          ----------------------------------------
          -- (���_����)�e�W�v���ڏ�����         --
          ----------------------------------------
          <<add_total_loop>>
          FOR r IN 1..3 LOOP           -- ���Q�v/��Q�v/���_�v
            gr_add_total(r).may_quant       := gn_0; -- �T�� ����
            gr_add_total(r).may_amount      := gn_0; -- �T�� ���z
            gr_add_total(r).may_price       := gn_0; -- �T�� �i�ڒ艿
            gr_add_total(r).may_to_amount   := gn_0; -- �T�� ���󍇌v
            gr_add_total(r).may_quant_t     := gn_0; -- �T�� ����(�v)
            gr_add_total(r).jun_quant       := gn_0; -- �U�� ����
            gr_add_total(r).jun_amount      := gn_0; -- �U�� ���z
            gr_add_total(r).jun_price       := gn_0; -- �U�� �i�ڒ艿
            gr_add_total(r).jun_to_amount   := gn_0; -- �U�� ���󍇌v
            gr_add_total(r).jun_quant_t     := gn_0; -- �U�� ����(�v)
            gr_add_total(r).jul_quant       := gn_0; -- �V�� ����
            gr_add_total(r).jul_amount      := gn_0; -- �V�� ���z
            gr_add_total(r).jul_price       := gn_0; -- �V�� �i�ڒ艿
            gr_add_total(r).jul_to_amount   := gn_0; -- �V�� ���󍇌v
            gr_add_total(r).jul_quant_t     := gn_0; -- �V�� ����(�v)
            gr_add_total(r).aug_quant       := gn_0; -- �W�� ����
            gr_add_total(r).aug_amount      := gn_0; -- �W�� ���z
            gr_add_total(r).aug_price       := gn_0; -- �W�� �i�ڒ艿
            gr_add_total(r).aug_to_amount   := gn_0; -- �W�� ���󍇌v
            gr_add_total(r).aug_quant_t     := gn_0; -- �W�� ����(�v)
            gr_add_total(r).sep_quant       := gn_0; -- �X�� ����
            gr_add_total(r).sep_amount      := gn_0; -- �X�� ���z
            gr_add_total(r).sep_price       := gn_0; -- �X�� �i�ڒ艿
            gr_add_total(r).sep_to_amount   := gn_0; -- �X�� ���󍇌v
            gr_add_total(r).sep_quant_t     := gn_0; -- �X�� ����(�v)
            gr_add_total(r).oct_quant       := gn_0; -- �P�O�� ����
            gr_add_total(r).oct_amount      := gn_0; -- �P�O�� ���z
            gr_add_total(r).oct_price       := gn_0; -- �P�O�� �i�ڒ艿
            gr_add_total(r).oct_to_amount   := gn_0; -- �P�O�� ���󍇌v
            gr_add_total(r).oct_quant_t     := gn_0; -- �P�O�� ����(�v)
            gr_add_total(r).nov_quant       := gn_0; -- �P�P�� ����
            gr_add_total(r).nov_amount      := gn_0; -- �P�P�� ���z
            gr_add_total(r).nov_price       := gn_0; -- �P�P�� �i�ڒ艿
            gr_add_total(r).nov_to_amount   := gn_0; -- �P�P�� ���󍇌v
            gr_add_total(r).nov_quant_t     := gn_0; -- �P�P�� ����(�v)
            gr_add_total(r).dec_quant       := gn_0; -- �P�Q�� ����
            gr_add_total(r).dec_amount      := gn_0; -- �P�Q�� ���z
            gr_add_total(r).dec_price       := gn_0; -- �P�Q�� �i�ڒ艿
            gr_add_total(r).dec_to_amount   := gn_0; -- �P�Q�� ���󍇌v
            gr_add_total(r).dec_quant_t     := gn_0; -- �P�Q�� ����(�v)
            gr_add_total(r).jan_quant       := gn_0; -- �P�Q�� ����
            gr_add_total(r).jan_amount      := gn_0; -- �P�� ���z
            gr_add_total(r).jan_price       := gn_0; -- �P�� �i�ڒ艿
            gr_add_total(r).jan_to_amount   := gn_0; -- �P�� ���󍇌v
            gr_add_total(r).jan_quant_t     := gn_0; -- �P�� ����(�v)
            gr_add_total(r).feb_quant       := gn_0; -- �Q�� ����
            gr_add_total(r).feb_amount      := gn_0; -- �Q�� ���z
            gr_add_total(r).feb_price       := gn_0; -- �Q�� �i�ڒ艿
            gr_add_total(r).feb_to_amount   := gn_0; -- �Q�� ���󍇌v
            gr_add_total(r).feb_quant_t     := gn_0; -- �Q�� ����(�v)
            gr_add_total(r).mar_quant       := gn_0; -- �R�� ����
            gr_add_total(r).mar_amount      := gn_0; -- �R�� ���z
            gr_add_total(r).mar_price       := gn_0; -- �R�� �i�ڒ艿
            gr_add_total(r).mar_to_amount   := gn_0; -- �R�� ���󍇌v
            gr_add_total(r).mar_quant_t     := gn_0; -- �R�� ����(�v)
            gr_add_total(r).apr_quant       := gn_0; -- �S�� ����
            gr_add_total(r).apr_amount      := gn_0; -- �S�� ���z
            gr_add_total(r).apr_price       := gn_0; -- �S�� �i�ڒ艿
            gr_add_total(r).apr_to_amount   := gn_0; -- �S�� ���󍇌v
            gr_add_total(r).apr_quant_t     := gn_0; -- �S�� ����(�v)
            gr_add_total(r).year_quant      := gn_0; -- �N�v ����
            gr_add_total(r).year_amount     := gn_0; -- �N�v ���z
            gr_add_total(r).year_price      := gn_0; -- �N�v �i�ڒ艿
            gr_add_total(r).year_to_amount  := gn_0; -- �N�v ���󍇌v
            gr_add_total(r).year_quant_t    := gn_0; -- �N�v ����(�v)
          END LOOP add_total_loop;
--
          -- �N�v������
          ln_year_quant_sum  := gn_0;           -- ����
          ln_year_amount_sum := gn_0;           -- ���z
          ln_year_to_am_sum  := gn_0;           -- ���󍇌v
          ln_year_price_sum  := gn_0;           -- �i�ڒ艿
--
          -- XML�o�̓t���O������
          <<xml_out_loop>>
          FOR n IN 1..12 LOOP
            gr_xml_out(n).out_fg   := lv_no;
          END LOOP xml_out_loop;
--
        END IF;
--
        -- ====================================================
        --  (���_����)�Q�R�[�h�u���C�N
        -- ====================================================
        -- �Q�R�[�h���؂�ւ�����Ƃ�
        IF (gr_sale_plan_1(i).gun <> lv_gun_break) THEN
          -------------------------------------------------------
          -- �e�����o�f�[�^�����݂��Ȃ��ꍇ�A0�\���ɂ�XML�o��  --
          -------------------------------------------------------
          <<xml_out_0_loop>>
          FOR m IN 1..12 LOOP
            IF (gr_xml_out(m).out_fg = lv_no) THEN
              prc_create_xml_data_dtl_n
                (
                  iv_label_name     => gr_xml_out(m).tag_name                      -- �o�̓^�O��
                 ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          END LOOP xml_out_0_loop;
--
          -- -----------------------------------------------------
          -- (���_����)�N�v ���ʃf�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
          -- -----------------------------------------------------
          -- (���_����)�N�v ���z�f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
          -- -----------------------------------------------------
          -- (���_����)�N�v �e�����f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          ------------------------------------------------
          -- (���_����)�e���v�Z (���z�|���󍇌v������)  --
          ------------------------------------------------
          ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
          -- �O���Z��𔻒�
          IF (ln_year_amount_sum <> gn_0) THEN
          -- �l��[0]�o�Ȃ���Όv�Z
          gt_xml_data_table(gl_xml_idx).tag_value := 
                    ROUND((ln_arari / ln_year_amount_sum * 100),2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
          END IF;
--
          -- -----------------------------------------------------
          -- (���_����)�N�v �|���f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
          --------------------------------------
          -- �O���Z���荀�ڂ֔���l��}��     --
          --------------------------------------
          ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
          -- �O���Z��𔻒�
          IF (ln_chk_0 <> gn_0) THEN
          -- �l��[0]�o�Ȃ���Όv�Z
          ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
          ELSE
            -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
            ln_kake_par := gn_0;
          END IF;
--
          -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
          IF ((ln_year_price_sum = 0)
            OR (ln_kake_par < 0)) THEN
            ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
          END IF;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).year_quant     :=
               gr_add_total(r).year_quant     + ln_year_quant_sum;        -- ����
            gr_add_total(r).year_amount    :=
               gr_add_total(r).year_amount    + ln_year_amount_sum;       -- ���z
            gr_add_total(r).year_price     :=
               gr_add_total(r).year_price     + ln_year_price_sum;        -- �i�ڒ艿
            gr_add_total(r).year_to_amount :=
               gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- ���󍇌v
            gr_add_total(r).year_quant_t   :=
               gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- ����(�v)
          END LOOP add_total_loop;
--
          -- -----------------------------------------------------
          --  (���_����)�i�ڏI���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (���_����)�i�ڏI���k�f�^�O�o��
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- ====================================================
          --  (���_����)���Q�v�u���C�N
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan_1(i).gun,1,3) <> lv_sttl_break) THEN
            --------------------------------------------------------
            -- XML�f�[�^�쐬 - ���[�f�[�^�o�� ���Q�v
            --------------------------------------------------------
            prc_create_xml_data_st_lt
            (
               iv_label_name     => gv_name_st                     -- ���Q�v�p�^�O��
              ,iv_name           => gv_label_st                    -- ���Q�v�^�C�g��
              ,in_may_quant      => gr_add_total(1).may_quant      -- �T�� ����
              ,in_may_amount     => gr_add_total(1).may_amount     -- �T�� ���z
              ,in_may_price      => gr_add_total(1).may_price      -- �T�� �i�ڒ艿
              ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- �T�� ���󍇌v
              ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_may_s_cost     => gr_add_total(1).may_s_cost     -- �T�� �W������(�v�Z�p)
              ,in_may_calc       => gr_add_total(1).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
              ,in_may_minus_flg   => gr_add_total(1).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_may_ht_zero_flg => gr_add_total(1).may_ht_zero_flg -- �T�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jun_quant      => gr_add_total(1).jun_quant      -- �U�� ����
              ,in_jun_amount     => gr_add_total(1).jun_amount     -- �U�� ���z
              ,in_jun_price      => gr_add_total(1).jun_price      -- �U�� �i�ڒ艿
              ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- �U�� ���󍇌v
              ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jun_s_cost     => gr_add_total(1).jun_s_cost     -- �U�� �W������(�v�Z�p)
              ,in_jun_calc       => gr_add_total(1).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
              ,in_jun_minus_flg   => gr_add_total(1).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jun_ht_zero_flg => gr_add_total(1).jun_ht_zero_flg -- �U�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jul_quant      => gr_add_total(1).jul_quant      -- �V�� ����
              ,in_jul_amount     => gr_add_total(1).jul_amount     -- �V�� ���z
              ,in_jul_price      => gr_add_total(1).jul_price      -- �V�� �i�ڒ艿
              ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- �V�� ���󍇌v
              ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jul_s_cost     => gr_add_total(1).jul_s_cost     -- �V�� �W������(�v�Z�p)
              ,in_jul_calc       => gr_add_total(1).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
              ,in_jul_minus_flg   => gr_add_total(1).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jul_ht_zero_flg => gr_add_total(1).jul_ht_zero_flg -- �V�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_aug_quant      => gr_add_total(1).aug_quant      -- �W�� ����
              ,in_aug_amount     => gr_add_total(1).aug_amount     -- �W�� ���z
              ,in_aug_price      => gr_add_total(1).aug_price      -- �W�� �i�ڒ艿
              ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- �W�� ���󍇌v
              ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_aug_s_cost     => gr_add_total(1).aug_s_cost     -- �W�� �W������(�v�Z�p)
              ,in_aug_calc       => gr_add_total(1).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
              ,in_aug_minus_flg   => gr_add_total(1).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_aug_ht_zero_flg => gr_add_total(1).aug_ht_zero_flg -- �W�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_sep_quant      => gr_add_total(1).sep_quant      -- �X�� ����
              ,in_sep_amount     => gr_add_total(1).sep_amount     -- �X�� ���z
              ,in_sep_price      => gr_add_total(1).sep_price      -- �X�� �i�ڒ艿
              ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- �X�� ���󍇌v
              ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_sep_s_cost     => gr_add_total(1).sep_s_cost     -- �X�� �W������(�v�Z�p)
              ,in_sep_calc       => gr_add_total(1).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
              ,in_sep_minus_flg   => gr_add_total(1).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_sep_ht_zero_flg => gr_add_total(1).sep_ht_zero_flg -- �X�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_oct_quant      => gr_add_total(1).oct_quant      -- �P�O�� ����
              ,in_oct_amount     => gr_add_total(1).oct_amount     -- �P�O�� ���z
              ,in_oct_price      => gr_add_total(1).oct_price      -- �P�O�� �i�ڒ艿
              ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- �P�O�� ���󍇌v
              ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_oct_s_cost     => gr_add_total(1).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
              ,in_oct_calc       => gr_add_total(1).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
              ,in_oct_minus_flg   => gr_add_total(1).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_oct_ht_zero_flg => gr_add_total(1).oct_ht_zero_flg -- �P�O�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_nov_quant      => gr_add_total(1).nov_quant      -- �P�P�� ����
              ,in_nov_amount     => gr_add_total(1).nov_amount     -- �P�P�� ���z
              ,in_nov_price      => gr_add_total(1).nov_price      -- �P�P�� �i�ڒ艿
              ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- �P�P�� ���󍇌v
              ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_nov_s_cost     => gr_add_total(1).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
              ,in_nov_calc       => gr_add_total(1).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
              ,in_nov_minus_flg   => gr_add_total(1).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_nov_ht_zero_flg => gr_add_total(1).nov_ht_zero_flg -- �P�P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_dec_quant      => gr_add_total(1).dec_quant      -- �P�Q�� ����
              ,in_dec_amount     => gr_add_total(1).dec_amount     -- �P�Q�� ���z
              ,in_dec_price      => gr_add_total(1).dec_price      -- �P�Q�� �i�ڒ艿
              ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- �P�Q�� ���󍇌v
              ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_dec_s_cost     => gr_add_total(1).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
              ,in_dec_calc       => gr_add_total(1).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_dec_minus_flg   => gr_add_total(1).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_dec_ht_zero_flg => gr_add_total(1).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jan_quant      => gr_add_total(1).jan_quant      -- �P�� ����
              ,in_jan_amount     => gr_add_total(1).jan_amount     -- �P�� ���z
              ,in_jan_price      => gr_add_total(1).jan_price      -- �P�� �i�ڒ艿
              ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- �P�� ���󍇌v
              ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jan_s_cost     => gr_add_total(1).jan_s_cost     -- �P�� �W������(�v�Z�p)
              ,in_jan_calc       => gr_add_total(1).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
              ,in_jan_minus_flg   => gr_add_total(1).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jan_ht_zero_flg => gr_add_total(1).jan_ht_zero_flg -- �P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_feb_quant      => gr_add_total(1).feb_quant      -- �Q�� ����
              ,in_feb_amount     => gr_add_total(1).feb_amount     -- �Q�� ���z
              ,in_feb_price      => gr_add_total(1).feb_price      -- �Q�� �i�ڒ艿
              ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- �Q�� ���󍇌v
              ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_feb_s_cost     => gr_add_total(1).feb_s_cost     -- �Q�� �W������(�v�Z�p)
              ,in_feb_calc       => gr_add_total(1).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_feb_minus_flg   => gr_add_total(1).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_feb_ht_zero_flg => gr_add_total(1).feb_ht_zero_flg -- �Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_mar_quant      => gr_add_total(1).mar_quant      -- �R�� ����
              ,in_mar_amount     => gr_add_total(1).mar_amount     -- �R�� ���z
              ,in_mar_price      => gr_add_total(1).mar_price      -- �R�� �i�ڒ艿
              ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- �R�� ���󍇌v
              ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_mar_s_cost     => gr_add_total(1).mar_s_cost     -- �R�� �W������(�v�Z�p)
              ,in_mar_calc       => gr_add_total(1).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
              ,in_mar_minus_flg   => gr_add_total(1).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_mar_ht_zero_flg => gr_add_total(1).mar_ht_zero_flg -- �R�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_apr_quant      => gr_add_total(1).apr_quant      -- �S�� ����
              ,in_apr_amount     => gr_add_total(1).apr_amount     -- �S�� ���z
              ,in_apr_price      => gr_add_total(1).apr_price      -- �S�� �i�ڒ艿
              ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- �S�� ���󍇌v
              ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_apr_s_cost     => gr_add_total(1).apr_s_cost     -- �S�� �W������(�v�Z�p)
              ,in_apr_calc       => gr_add_total(1).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
              ,in_apr_minus_flg   => gr_add_total(1).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_apr_ht_zero_flg => gr_add_total(1).apr_ht_zero_flg -- �S�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_year_quant     => gr_add_total(1).year_quant     -- �N�v ����
              ,in_year_amount    => gr_add_total(1).year_amount    -- �N�v ���z
              ,in_year_price     => gr_add_total(1).year_price     -- �N�v �i�ڒ艿
              ,in_year_to_amount => gr_add_total(1).year_to_amount -- �N�v ���󍇌v
              ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_year_s_cost    => gr_add_total(1).year_s_cost    -- �N�v �W������(�v�Z�p)
              ,in_year_calc      => gr_add_total(1).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
              ,in_year_minus_flg   => gr_add_total(1).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_year_ht_zero_flg => gr_add_total(1).year_ht_zero_flg -- �N�v �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ���Q�v�u���C�N�L�[�X�V
            lv_sttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,3);
--
            -- ���Q�v�W�v���ڏ�����
            gr_add_total(1).may_quant       := gn_0; -- �T�� ����
            gr_add_total(1).may_amount      := gn_0; -- �T�� ���z
            gr_add_total(1).may_price       := gn_0; -- �T�� �i�ڒ艿
            gr_add_total(1).may_to_amount   := gn_0; -- �T�� ���󍇌v
            gr_add_total(1).may_quant_t     := gn_0; -- �T�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).may_s_cost      := gn_0; -- �T�� �W������(�v)
            gr_add_total(1).may_calc        := gn_0; -- �T�� �i�ڒ艿*����(�v)
            gr_add_total(1).may_minus_flg   := 'N';  -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).may_ht_zero_flg := 'N';  -- �T�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).jun_quant       := gn_0; -- �U�� ����
            gr_add_total(1).jun_amount      := gn_0; -- �U�� ���z
            gr_add_total(1).jun_price       := gn_0; -- �U�� �i�ڒ艿
            gr_add_total(1).jun_to_amount   := gn_0; -- �U�� ���󍇌v
            gr_add_total(1).jun_quant_t     := gn_0; -- �U�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).jun_s_cost      := gn_0; -- �U�� �W������(�v)
            gr_add_total(1).jun_calc        := gn_0; -- �U�� �i�ڒ艿*����(�v)
            gr_add_total(1).jun_minus_flg   := 'N';  -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).jun_ht_zero_flg := 'N';  -- �U�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).jul_quant       := gn_0; -- �V�� ����
            gr_add_total(1).jul_amount      := gn_0; -- �V�� ���z
            gr_add_total(1).jul_price       := gn_0; -- �V�� �i�ڒ艿
            gr_add_total(1).jul_to_amount   := gn_0; -- �V�� ���󍇌v
            gr_add_total(1).jul_quant_t     := gn_0; -- �V�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).jul_s_cost      := gn_0; -- �V�� �W������(�v)
            gr_add_total(1).jul_calc        := gn_0; -- �V�� �i�ڒ艿*����(�v)
            gr_add_total(1).jul_minus_flg   := 'N';  -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).jul_ht_zero_flg := 'N';  -- �V�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).aug_quant       := gn_0; -- �W�� ����
            gr_add_total(1).aug_amount      := gn_0; -- �W�� ���z
            gr_add_total(1).aug_price       := gn_0; -- �W�� �i�ڒ艿
            gr_add_total(1).aug_to_amount   := gn_0; -- �W�� ���󍇌v
            gr_add_total(1).aug_quant_t     := gn_0; -- �W�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).aug_s_cost      := gn_0; -- �W�� �W������(�v)
            gr_add_total(1).aug_calc        := gn_0; -- �W�� �i�ڒ艿*����(�v)
            gr_add_total(1).aug_minus_flg   := 'N';  -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).aug_ht_zero_flg := 'N';  -- �W�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).sep_quant       := gn_0; -- �X�� ����
            gr_add_total(1).sep_amount      := gn_0; -- �X�� ���z
            gr_add_total(1).sep_price       := gn_0; -- �X�� �i�ڒ艿
            gr_add_total(1).sep_to_amount   := gn_0; -- �X�� ���󍇌v
            gr_add_total(1).sep_quant_t     := gn_0; -- �X�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).sep_s_cost      := gn_0; -- �X�� �W������(�v)
            gr_add_total(1).sep_calc        := gn_0; -- �X�� �i�ڒ艿*����(�v)
            gr_add_total(1).sep_minus_flg   := 'N';  -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).sep_ht_zero_flg := 'N';  -- �X�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).oct_quant       := gn_0; -- �P�O�� ����
            gr_add_total(1).oct_amount      := gn_0; -- �P�O�� ���z
            gr_add_total(1).oct_price       := gn_0; -- �P�O�� �i�ڒ艿
            gr_add_total(1).oct_to_amount   := gn_0; -- �P�O�� ���󍇌v
            gr_add_total(1).oct_quant_t     := gn_0; -- �P�O�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).oct_s_cost      := gn_0; -- �P�O�� �W������(�v)
            gr_add_total(1).oct_calc        := gn_0; -- �P�O�� �i�ڒ艿*����(�v)
            gr_add_total(1).oct_minus_flg   := 'N';  -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).oct_ht_zero_flg := 'N';  -- �P�O�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).nov_quant       := gn_0; -- �P�P�� ����
            gr_add_total(1).nov_amount      := gn_0; -- �P�P�� ���z
            gr_add_total(1).nov_price       := gn_0; -- �P�P�� �i�ڒ艿
            gr_add_total(1).nov_to_amount   := gn_0; -- �P�P�� ���󍇌v
            gr_add_total(1).nov_quant_t     := gn_0; -- �P�P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).nov_s_cost      := gn_0; -- �P�P�� �W������(�v)
            gr_add_total(1).nov_calc        := gn_0; -- �P�P�� �i�ڒ艿*����(�v)
            gr_add_total(1).nov_minus_flg   := 'N';  -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).nov_ht_zero_flg := 'N';  -- �P�P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).dec_quant       := gn_0; -- �P�Q�� ����
            gr_add_total(1).dec_amount      := gn_0; -- �P�Q�� ���z
            gr_add_total(1).dec_price       := gn_0; -- �P�Q�� �i�ڒ艿
            gr_add_total(1).dec_to_amount   := gn_0; -- �P�Q�� ���󍇌v
            gr_add_total(1).dec_quant_t     := gn_0; -- �P�Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).dec_s_cost      := gn_0; -- �P�Q�� �W������(�v)
            gr_add_total(1).dec_calc        := gn_0; -- �P�Q�� �i�ڒ艿*����(�v)
            gr_add_total(1).dec_minus_flg   := 'N';  -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).dec_ht_zero_flg := 'N';  -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).jan_quant       := gn_0; -- �P�� ����
            gr_add_total(1).jan_amount      := gn_0; -- �P�� ���z
            gr_add_total(1).jan_price       := gn_0; -- �P�� �i�ڒ艿
            gr_add_total(1).jan_to_amount   := gn_0; -- �P�� ���󍇌v
            gr_add_total(1).jan_quant_t     := gn_0; -- �P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).jan_s_cost      := gn_0; -- �P�� �W������(�v)
            gr_add_total(1).jan_calc        := gn_0; -- �P�� �i�ڒ艿*����(�v)
            gr_add_total(1).jan_minus_flg   := 'N';  -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).jan_ht_zero_flg := 'N';  -- �P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).feb_quant       := gn_0; -- �Q�� ����
            gr_add_total(1).feb_amount      := gn_0; -- �Q�� ���z
            gr_add_total(1).feb_price       := gn_0; -- �Q�� �i�ڒ艿
            gr_add_total(1).feb_to_amount   := gn_0; -- �Q�� ���󍇌v
            gr_add_total(1).feb_quant_t     := gn_0; -- �Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).feb_s_cost      := gn_0; -- �Q�� �W������(�v)
            gr_add_total(1).feb_calc        := gn_0; -- �Q�� �i�ڒ艿*����(�v)
            gr_add_total(1).feb_minus_flg   := 'N';  -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).feb_ht_zero_flg := 'N';  -- �Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).mar_quant       := gn_0; -- �R�� ����
            gr_add_total(1).mar_amount      := gn_0; -- �R�� ���z
            gr_add_total(1).mar_price       := gn_0; -- �R�� �i�ڒ艿
            gr_add_total(1).mar_to_amount   := gn_0; -- �R�� ���󍇌v
            gr_add_total(1).mar_quant_t     := gn_0; -- �R�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).mar_s_cost      := gn_0; -- �R�� �W������(�v)
            gr_add_total(1).mar_calc        := gn_0; -- �R�� �i�ڒ艿*����(�v)
            gr_add_total(1).mar_minus_flg   := 'N';  -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).mar_ht_zero_flg := 'N';  -- �R�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).apr_quant       := gn_0; -- �S�� ����
            gr_add_total(1).apr_amount      := gn_0; -- �S�� ���z
            gr_add_total(1).apr_price       := gn_0; -- �S�� �i�ڒ艿
            gr_add_total(1).apr_to_amount   := gn_0; -- �S�� ���󍇌v
            gr_add_total(1).apr_quant_t     := gn_0; -- �S�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).apr_s_cost      := gn_0; -- �S�� �W������(�v)
            gr_add_total(1).apr_calc        := gn_0; -- �S�� �i�ڒ艿*����(�v)
            gr_add_total(1).apr_minus_flg   := 'N';  -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).apr_ht_zero_flg := 'N';  -- �S�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(1).year_quant      := gn_0; -- �N�v ����
            gr_add_total(1).year_amount     := gn_0; -- �N�v ���z
            gr_add_total(1).year_price      := gn_0; -- �N�v �i�ڒ艿
            gr_add_total(1).year_to_amount  := gn_0; -- �N�v ���󍇌v
            gr_add_total(1).year_quant_t    := gn_0; -- �N�v ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(1).year_s_cost     := gn_0; -- �N�v �W������(�v)
            gr_add_total(1).year_calc       := gn_0; -- �N�v �i�ڒ艿*����(�v)
            gr_add_total(1).year_minus_flg   := 'N'; -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(1).year_ht_zero_flg := 'N'; -- �N�v �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END IF;
--
          -- ====================================================
          --  (���_����)��Q�v�u���C�N
          -- ====================================================
          IF (SUBSTRB(gr_sale_plan_1(i).gun,1,1) <> lv_lttl_break) THEN
            --------------------------------------------------------
            -- ��Q�v�f�[�^�o�� 
            --------------------------------------------------------
            prc_create_xml_data_st_lt
            (
               iv_label_name     => gv_name_lt                     -- ��Q�v�p�^�O��
              ,iv_name           => gv_label_lt                    -- ��Q�v�^�C�g��
              ,in_may_quant      => gr_add_total(2).may_quant      -- �T�� ����
              ,in_may_amount     => gr_add_total(2).may_amount     -- �T�� ���z
              ,in_may_price      => gr_add_total(2).may_price      -- �T�� �i�ڒ艿
              ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- �T�� ���󍇌v
              ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- �T�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_may_s_cost     => gr_add_total(2).may_s_cost     -- �T�� �W������(�v�Z�p)
              ,in_may_calc       => gr_add_total(2).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
              ,in_may_minus_flg   => gr_add_total(2).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_may_ht_zero_flg => gr_add_total(2).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jun_quant      => gr_add_total(2).jun_quant      -- �U�� ����
              ,in_jun_amount     => gr_add_total(2).jun_amount     -- �U�� ���z
              ,in_jun_price      => gr_add_total(2).jun_price      -- �U�� �i�ڒ艿
              ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- �U�� ���󍇌v
              ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- �U�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jun_s_cost     => gr_add_total(2).jun_s_cost     -- �U�� �W������(�v�Z�p)
              ,in_jun_calc       => gr_add_total(2).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
              ,in_jun_minus_flg   => gr_add_total(2).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jun_ht_zero_flg => gr_add_total(2).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jul_quant      => gr_add_total(2).jul_quant      -- �V�� ����
              ,in_jul_amount     => gr_add_total(2).jul_amount     -- �V�� ���z
              ,in_jul_price      => gr_add_total(2).jul_price      -- �V�� �i�ڒ艿
              ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- �V�� ���󍇌v
              ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- �V�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jul_s_cost     => gr_add_total(2).jul_s_cost     -- �V�� �W������(�v�Z�p)
              ,in_jul_calc       => gr_add_total(2).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
              ,in_jul_minus_flg   => gr_add_total(2).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jul_ht_zero_flg => gr_add_total(2).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_aug_quant      => gr_add_total(2).aug_quant      -- �W�� ����
              ,in_aug_amount     => gr_add_total(2).aug_amount     -- �W�� ���z
              ,in_aug_price      => gr_add_total(2).aug_price      -- �W�� �i�ڒ艿
              ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- �W�� ���󍇌v
              ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- �W�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_aug_s_cost     => gr_add_total(2).aug_s_cost     -- �W�� �W������(�v�Z�p)
              ,in_aug_calc       => gr_add_total(2).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
              ,in_aug_minus_flg   => gr_add_total(2).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_aug_ht_zero_flg => gr_add_total(2).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_sep_quant      => gr_add_total(2).sep_quant      -- �X�� ����
              ,in_sep_amount     => gr_add_total(2).sep_amount     -- �X�� ���z
              ,in_sep_price      => gr_add_total(2).sep_price      -- �X�� �i�ڒ艿
              ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- �X�� ���󍇌v
              ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- �X�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_sep_s_cost     => gr_add_total(2).sep_s_cost     -- �X�� �W������(�v�Z�p)
              ,in_sep_calc       => gr_add_total(2).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
              ,in_sep_minus_flg   => gr_add_total(2).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_sep_ht_zero_flg => gr_add_total(2).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_oct_quant      => gr_add_total(2).oct_quant      -- �P�O�� ����
              ,in_oct_amount     => gr_add_total(2).oct_amount     -- �P�O�� ���z
              ,in_oct_price      => gr_add_total(2).oct_price      -- �P�O�� �i�ڒ艿
              ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- �P�O�� ���󍇌v
              ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- �P�O�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_oct_s_cost     => gr_add_total(2).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
              ,in_oct_calc       => gr_add_total(2).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
              ,in_oct_minus_flg   => gr_add_total(2).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_oct_ht_zero_flg => gr_add_total(2).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_nov_quant      => gr_add_total(2).nov_quant      -- �P�P�� ����
              ,in_nov_amount     => gr_add_total(2).nov_amount     -- �P�P�� ���z
              ,in_nov_price      => gr_add_total(2).nov_price      -- �P�P�� �i�ڒ艿
              ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- �P�P�� ���󍇌v
              ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- �P�P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_nov_s_cost     => gr_add_total(2).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
              ,in_nov_calc       => gr_add_total(2).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
              ,in_nov_minus_flg   => gr_add_total(2).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_nov_ht_zero_flg => gr_add_total(2).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_dec_quant      => gr_add_total(2).dec_quant      -- �P�Q�� ����
              ,in_dec_amount     => gr_add_total(2).dec_amount     -- �P�Q�� ���z
              ,in_dec_price      => gr_add_total(2).dec_price      -- �P�Q�� �i�ڒ艿
              ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- �P�Q�� ���󍇌v
              ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_dec_s_cost     => gr_add_total(2).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
              ,in_dec_calc       => gr_add_total(2).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_dec_minus_flg   => gr_add_total(2).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_dec_ht_zero_flg => gr_add_total(2).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_jan_quant      => gr_add_total(2).jan_quant      -- �P�� ����
              ,in_jan_amount     => gr_add_total(2).jan_amount     -- �P�� ���z
              ,in_jan_price      => gr_add_total(2).jan_price      -- �P�� �i�ڒ艿
              ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- �P�� ���󍇌v
              ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- �P�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_jan_s_cost     => gr_add_total(2).jan_s_cost     -- �P�� �W������(�v�Z�p)
              ,in_jan_calc       => gr_add_total(2).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
              ,in_jan_minus_flg   => gr_add_total(2).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_jan_ht_zero_flg => gr_add_total(2).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_feb_quant      => gr_add_total(2).feb_quant      -- �Q�� ����
              ,in_feb_amount     => gr_add_total(2).feb_amount     -- �Q�� ���z
              ,in_feb_price      => gr_add_total(2).feb_price      -- �Q�� �i�ڒ艿
              ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- �Q�� ���󍇌v
              ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- �Q�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_feb_s_cost     => gr_add_total(2).feb_s_cost     -- �Q�� �W������(�v�Z�p)
              ,in_feb_calc       => gr_add_total(2).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
              ,in_feb_minus_flg   => gr_add_total(2).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_feb_ht_zero_flg => gr_add_total(2).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_mar_quant      => gr_add_total(2).mar_quant      -- �R�� ����
              ,in_mar_amount     => gr_add_total(2).mar_amount     -- �R�� ���z
              ,in_mar_price      => gr_add_total(2).mar_price      -- �R�� �i�ڒ艿
              ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- �R�� ���󍇌v
              ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- �R�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_mar_s_cost     => gr_add_total(2).mar_s_cost     -- �R�� �W������(�v�Z�p)
              ,in_mar_calc       => gr_add_total(2).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
              ,in_mar_minus_flg   => gr_add_total(2).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_mar_ht_zero_flg => gr_add_total(2).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_apr_quant      => gr_add_total(2).apr_quant      -- �S�� ����
              ,in_apr_amount     => gr_add_total(2).apr_amount     -- �S�� ���z
              ,in_apr_price      => gr_add_total(2).apr_price      -- �S�� �i�ڒ艿
              ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- �S�� ���󍇌v
              ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- �S�� ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_apr_s_cost     => gr_add_total(2).apr_s_cost     -- �S�� �W������(�v�Z�p)
              ,in_apr_calc       => gr_add_total(2).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
              ,in_apr_minus_flg   => gr_add_total(2).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_apr_ht_zero_flg => gr_add_total(2).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,in_year_quant     => gr_add_total(2).year_quant     -- �N�v ����
              ,in_year_amount    => gr_add_total(2).year_amount    -- �N�v ���z
              ,in_year_price     => gr_add_total(2).year_price     -- �N�v �i�ڒ艿
              ,in_year_to_amount => gr_add_total(2).year_to_amount -- �N�v ���󍇌v
              ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- �N�v ����(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
              ,in_year_s_cost    => gr_add_total(2).year_s_cost    -- �N�v �W������(�v�Z�p)
              ,in_year_calc      => gr_add_total(2).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
              ,in_year_minus_flg   => gr_add_total(2).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
              ,in_year_ht_zero_flg => gr_add_total(2).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
              ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
              ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ��Q�v�u���C�N�L�[�X�V
            lv_lttl_break := SUBSTRB(gr_sale_plan_1(i).gun,1,1);
--
            -- ��Q�v�W�v�p���ڏ�����
            gr_add_total(2).may_quant       := gn_0; -- �T�� ����
            gr_add_total(2).may_amount      := gn_0; -- �T�� ���z
            gr_add_total(2).may_price       := gn_0; -- �T�� �i�ڒ艿
            gr_add_total(2).may_to_amount   := gn_0; -- �T�� ���󍇌v
            gr_add_total(2).may_quant_t     := gn_0; -- �T�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).may_s_cost      := gn_0; -- �T�� �W������(�v)
            gr_add_total(2).may_calc        := gn_0; -- �T�� �i�ڒ艿*����(�v)
            gr_add_total(2).may_minus_flg   := 'N';  -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).may_ht_zero_flg := 'N';  -- �T�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).jun_quant       := gn_0; -- �U�� ����
            gr_add_total(2).jun_amount      := gn_0; -- �U�� ���z
            gr_add_total(2).jun_price       := gn_0; -- �U�� �i�ڒ艿
            gr_add_total(2).jun_to_amount   := gn_0; -- �U�� ���󍇌v
            gr_add_total(2).jun_quant_t     := gn_0; -- �U�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).jun_s_cost      := gn_0; -- �U�� �W������(�v)
            gr_add_total(2).jun_calc        := gn_0; -- �U�� �i�ڒ艿*����(�v)
            gr_add_total(2).jun_minus_flg   := 'N';  -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).jun_ht_zero_flg := 'N';  -- �U�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).jul_quant       := gn_0; -- �V�� ����
            gr_add_total(2).jul_amount      := gn_0; -- �V�� ���z
            gr_add_total(2).jul_price       := gn_0; -- �V�� �i�ڒ艿
            gr_add_total(2).jul_to_amount   := gn_0; -- �V�� ���󍇌v
            gr_add_total(2).jul_quant_t     := gn_0; -- �V�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).jul_s_cost      := gn_0; -- �V�� �W������(�v)
            gr_add_total(2).jul_calc        := gn_0; -- �V�� �i�ڒ艿*����(�v)
            gr_add_total(2).jul_minus_flg   := 'N';  -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).jul_ht_zero_flg := 'N';  -- �V�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).aug_quant       := gn_0; -- �W�� ����
            gr_add_total(2).aug_amount      := gn_0; -- �W�� ���z
            gr_add_total(2).aug_price       := gn_0; -- �W�� �i�ڒ艿
            gr_add_total(2).aug_to_amount   := gn_0; -- �W�� ���󍇌v
            gr_add_total(2).aug_quant_t     := gn_0; -- �W�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).aug_s_cost      := gn_0; -- �W�� �W������(�v)
            gr_add_total(2).aug_calc        := gn_0; -- �W�� �i�ڒ艿*����(�v)
            gr_add_total(2).aug_minus_flg   := 'N';  -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).aug_ht_zero_flg := 'N';  -- �W�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).sep_quant       := gn_0; -- �X�� ����
            gr_add_total(2).sep_amount      := gn_0; -- �X�� ���z
            gr_add_total(2).sep_price       := gn_0; -- �X�� �i�ڒ艿
            gr_add_total(2).sep_to_amount   := gn_0; -- �X�� ���󍇌v
            gr_add_total(2).sep_quant_t     := gn_0; -- �X�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).sep_s_cost      := gn_0; -- �X�� �W������(�v)
            gr_add_total(2).sep_calc        := gn_0; -- �X�� �i�ڒ艿*����(�v)
            gr_add_total(2).sep_minus_flg   := 'N';  -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).sep_ht_zero_flg := 'N';  -- �X�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).oct_quant       := gn_0; -- �P�O�� ����
            gr_add_total(2).oct_amount      := gn_0; -- �P�O�� ���z
            gr_add_total(2).oct_price       := gn_0; -- �P�O�� �i�ڒ艿
            gr_add_total(2).oct_to_amount   := gn_0; -- �P�O�� ���󍇌v
            gr_add_total(2).oct_quant_t     := gn_0; -- �P�O�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).oct_s_cost      := gn_0; -- �P�O�� �W������(�v)
            gr_add_total(2).oct_calc        := gn_0; -- �P�O�� �i�ڒ艿*����(�v)
            gr_add_total(2).oct_minus_flg   := 'N';  -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).oct_ht_zero_flg := 'N';  -- �P�O�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).nov_quant       := gn_0; -- �P�P�� ����
            gr_add_total(2).nov_amount      := gn_0; -- �P�P�� ���z
            gr_add_total(2).nov_price       := gn_0; -- �P�P�� �i�ڒ艿
            gr_add_total(2).nov_to_amount   := gn_0; -- �P�P�� ���󍇌v
            gr_add_total(2).nov_quant_t     := gn_0; -- �P�P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).nov_s_cost      := gn_0; -- �P�P�� �W������(�v)
            gr_add_total(2).nov_calc        := gn_0; -- �P�P�� �i�ڒ艿*����(�v)
            gr_add_total(2).nov_minus_flg   := 'N';  -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).nov_ht_zero_flg := 'N';  -- �P�P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).dec_quant       := gn_0; -- �P�Q�� ����
            gr_add_total(2).dec_amount      := gn_0; -- �P�Q�� ���z
            gr_add_total(2).dec_price       := gn_0; -- �P�Q�� �i�ڒ艿
            gr_add_total(2).dec_to_amount   := gn_0; -- �P�Q�� ���󍇌v
            gr_add_total(2).dec_quant_t     := gn_0; -- �P�Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).dec_s_cost      := gn_0; -- �P�Q�� �W������(�v)
            gr_add_total(2).dec_calc        := gn_0; -- �P�Q�� �i�ڒ艿*����(�v)
            gr_add_total(2).dec_minus_flg   := 'N';  -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).dec_ht_zero_flg := 'N';  -- �P�Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).jan_quant       := gn_0; -- �P�� ����
            gr_add_total(2).jan_amount      := gn_0; -- �P�� ���z
            gr_add_total(2).jan_price       := gn_0; -- �P�� �i�ڒ艿
            gr_add_total(2).jan_to_amount   := gn_0; -- �P�� ���󍇌v
            gr_add_total(2).jan_quant_t     := gn_0; -- �P�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).jan_s_cost      := gn_0; -- �P�� �W������(�v)
            gr_add_total(2).jan_calc        := gn_0; -- �P�� �i�ڒ艿*����(�v)
            gr_add_total(2).jan_minus_flg   := 'N';  -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).jan_ht_zero_flg := 'N';  -- �P�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).feb_quant       := gn_0; -- �Q�� ����
            gr_add_total(2).feb_amount      := gn_0; -- �Q�� ���z
            gr_add_total(2).feb_price       := gn_0; -- �Q�� �i�ڒ艿
            gr_add_total(2).feb_to_amount   := gn_0; -- �Q�� ���󍇌v
            gr_add_total(2).feb_quant_t     := gn_0; -- �Q�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).feb_s_cost      := gn_0; -- �Q�� �W������(�v)
            gr_add_total(2).feb_calc        := gn_0; -- �Q�� �i�ڒ艿*����(�v)
            gr_add_total(2).feb_minus_flg   := 'N';  -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).feb_ht_zero_flg := 'N';  -- �Q�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).mar_quant       := gn_0; -- �R�� ����
            gr_add_total(2).mar_amount      := gn_0; -- �R�� ���z
            gr_add_total(2).mar_price       := gn_0; -- �R�� �i�ڒ艿
            gr_add_total(2).mar_to_amount   := gn_0; -- �R�� ���󍇌v
            gr_add_total(2).mar_quant_t     := gn_0; -- �R�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).mar_s_cost      := gn_0; -- �R�� �W������(�v)
            gr_add_total(2).mar_calc        := gn_0; -- �R�� �i�ڒ艿*����(�v)
            gr_add_total(2).mar_minus_flg   := 'N';  -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).mar_ht_zero_flg := 'N';  -- �R�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).apr_quant       := gn_0; -- �S�� ����
            gr_add_total(2).apr_amount      := gn_0; -- �S�� ���z
            gr_add_total(2).apr_price       := gn_0; -- �S�� �i�ڒ艿
            gr_add_total(2).apr_to_amount   := gn_0; -- �S�� ���󍇌v
            gr_add_total(2).apr_quant_t     := gn_0; -- �S�� ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).apr_s_cost      := gn_0; -- �S�� �W������(�v)
            gr_add_total(2).apr_calc        := gn_0; -- �S�� �i�ڒ艿*����(�v)
            gr_add_total(2).apr_minus_flg   := 'N';  -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).apr_ht_zero_flg := 'N';  -- �S�� �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
            gr_add_total(2).year_quant      := gn_0; -- �N�v ����
            gr_add_total(2).year_amount     := gn_0; -- �N�v ���z
            gr_add_total(2).year_price      := gn_0; -- �N�v �i�ڒ艿
            gr_add_total(2).year_to_amount  := gn_0; -- �N�v ���󍇌v
            gr_add_total(2).year_quant_t    := gn_0; -- �N�v ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(2).year_s_cost     := gn_0; -- �N�v �W������(�v)
            gr_add_total(2).year_calc       := gn_0; -- �N�v �i�ڒ艿*����(�v)
            gr_add_total(2).year_minus_flg   := 'N'; -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
            gr_add_total(2).year_ht_zero_flg := 'N'; -- �N�v �i�ڒ艿0�l���݃t���O(�v�Z�p)
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END IF;
--
          -- -----------------------------------------------------
          --  (���_����)�Q�R�[�h�I���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (���_����)�Q�R�[�h�I��L�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (���_����)�Q�R�[�h�J�nL�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_gun_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (���_����)�Q�R�[�h�J�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_gun';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  (���_����)�i�ڊJ�n�k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          --  �u���C�N�L�[�X�V
          lv_gun_break  := gr_sale_plan_1(i).gun;           -- �Q�R�[�h
          lv_dtl_break  := lv_break_init;                   -- �i�ڃR�[�h
--
          -- �N�v������
          ln_year_quant_sum  := gn_0;           -- ����
          ln_year_amount_sum := gn_0;           -- ���z
          ln_year_to_am_sum  := gn_0;           -- ���󍇌v
          ln_year_price_sum  := gn_0;           -- �i�ڒ艿
--
          -- XML�o�̓t���O������
          <<xml_out_loop>>
          FOR n IN 1..12 LOOP
            gr_xml_out(n).out_fg   := lv_no;
          END LOOP xml_out_loop;
--
        END IF;
--
        -- ====================================================
        --  (���_����)�i�ڃR�[�h�u���C�N
        -- ====================================================
        -- �ŏ��̃��R�[�h�̎��ƁA�i�ڂ��؂�ւ�����Ƃ��\��
        IF ((lv_dtl_break = lv_break_init)
          OR (lv_dtl_break <> gr_sale_plan_1(i).item_no)) THEN
          -- �ŏ��̃��R�[�h�ł́A�I���^�O�͕\�����Ȃ��B
          IF (lv_dtl_break <> lv_break_init) THEN
            -------------------------------------------------------
            -- �e�����o�f�[�^�����݂��Ȃ��ꍇ�A0�\���ɂ�XML�o��  --
            -------------------------------------------------------
            <<xml_out_0_loop>>
            FOR m IN 1..12 LOOP
              IF (gr_xml_out(m).out_fg = lv_no) THEN
                prc_create_xml_data_dtl_n
                  (
                    iv_label_name     => gr_xml_out(m).tag_name                      -- �o�̓^�O��
                   ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                   ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                   ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                  );
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
              END IF;
            END LOOP xml_out_0_loop;
--
            -- -----------------------------------------------------
            -- (���_����)�N�v ���ʃf�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
            -- -----------------------------------------------------
            -- (���_����)�N�v ���z�f�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
            gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
            -- -----------------------------------------------------
            -- (���_����)�N�v �e�����f�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            ------------------------------------------------
            -- (���_����)�e���v�Z (���z�|���󍇌v������)  --
            ------------------------------------------------
            ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
            -- �O���Z��𔻒�
            IF (ln_year_amount_sum <> gn_0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              gt_xml_data_table(gl_xml_idx).tag_value := 
                      ROUND((ln_arari / ln_year_amount_sum * 100),2);
            ELSE
              -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
              gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
            END IF;
--
            -- -----------------------------------------------------
            -- (���_����)�N�v �|���f�[�^
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
            --------------------------------------
            -- �O���Z���荀�ڂ֔���l��}��     --
            --------------------------------------
            ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
            -- �O���Z��𔻒�
            IF (ln_chk_0 <> gn_0) THEN
              -- �l��[0]�o�Ȃ���Όv�Z
              ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
            ELSE
             -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
             ln_kake_par := gn_0;
            END IF;
--
            -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
            IF ((ln_year_price_sum = 0)
              OR (ln_kake_par < 0)) THEN
              ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
            END IF;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
            -- �e�W�v���ڂփf�[�^�}��
            <<add_total_loop>>
            FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
              gr_add_total(r).year_quant     :=
                 gr_add_total(r).year_quant     + ln_year_quant_sum;        -- ����
              gr_add_total(r).year_amount    :=
                 gr_add_total(r).year_amount    + ln_year_amount_sum;       -- ���z
              gr_add_total(r).year_price     :=
                 gr_add_total(r).year_price     + ln_year_price_sum;        -- �i�ڒ艿
              gr_add_total(r).year_to_amount :=
                 gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- ���󍇌v
              gr_add_total(r).year_quant_t   :=
                 gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- ����(�v)
            END LOOP add_total_loop;
--
            -- -----------------------------------------------------
            --  (���_����)�i�ڏI���f�^�O�o��
            -- -----------------------------------------------------
            gl_xml_idx := gt_xml_data_table.COUNT + 1;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
            -- �N�v������
            ln_year_quant_sum  := gn_0;           -- ����
            ln_year_amount_sum := gn_0;           -- ���z
            ln_year_to_am_sum  := gn_0;           -- ���󍇌v
            ln_year_price_sum  := gn_0;           -- �i�ڒ艿
--
          END IF;
          -- -----------------------------------------------------
          --  (���_����)�i�ڊJ�n�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          -- (���_����)�Q�R�[�h�f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'gun_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).gun;
--
          -- -----------------------------------------------------
          -- (���_����)�i��(�R�[�h)�f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).item_no;
--
          -- -----------------------------------------------------
          -- (���_����)�i��(����)�f�[�^
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := gr_sale_plan_1(i).item_short_name;
        END IF;
--
        -- ====================================================
        --  (���_����)���׃f�[�^�o��
        -- ====================================================
        --------------------------------------
        -- (���_����)���o�f�[�^���T���̏ꍇ --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_may_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_may                               -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                  -- �N�v�p ����
             ,on_price          => ln_price                                  -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                            -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_5>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).may_quant     :=
               gr_add_total(r).may_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- ����
            gr_add_total(r).may_amount    :=
               gr_add_total(r).may_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- ���z
            gr_add_total(r).may_price     :=
               gr_add_total(r).may_price     + ln_price;                                  -- �i�ڒ艿
            gr_add_total(r).may_to_amount :=
               gr_add_total(r).may_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- ���󍇌v
            gr_add_total(r).may_quant_t   :=
               gr_add_total(r).may_quant_t   + ln_quant;                                  -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).may_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).may_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).may_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).may_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                             -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).may_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).may_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410

          END LOOP add_total_loop_5;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(1).tag_name := gv_name_may;
          gr_xml_out(1).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(1).tag_name := gv_name_may;
          gr_xml_out(1).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (���_����)���o�f�[�^���U���̏ꍇ --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_jun_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_jun                               -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                  -- �N�v�p ����
             ,on_price          => ln_price                                  -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_6>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).jun_quant     :=
               gr_add_total(r).jun_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- ����
            gr_add_total(r).jun_amount    :=
               gr_add_total(r).jun_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- ���z
            gr_add_total(r).jun_price     :=
               gr_add_total(r).jun_price     + ln_price;                                  -- �i�ڒ艿
            gr_add_total(r).jun_to_amount :=
               gr_add_total(r).jun_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- ���󍇌v
            gr_add_total(r).jun_quant_t   :=
               gr_add_total(r).jun_quant_t   + ln_quant;                                  -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).jun_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).jun_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).jun_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).jun_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                             -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).jun_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).jun_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_6;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(2).tag_name := gv_name_jun;
          gr_xml_out(2).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(2).tag_name := gv_name_jun;
          gr_xml_out(2).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (���_����)���o�f�[�^���V���̏ꍇ --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_jul_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_jul                               -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                  -- �N�v�p ����
             ,on_price          => ln_price                                  -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_7>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).jul_quant     :=
               gr_add_total(r).jul_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- ����
            gr_add_total(r).jul_amount    :=
               gr_add_total(r).jul_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- ���z
            gr_add_total(r).jul_price     :=
               gr_add_total(r).jul_price     + ln_price;                                  -- �i�ڒ艿
            gr_add_total(r).jul_to_amount :=
               gr_add_total(r).jul_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- ���󍇌v
            gr_add_total(r).jul_quant_t   :=
               gr_add_total(r).jul_quant_t   + ln_quant;                                  -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).jul_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).jul_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).jul_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).jul_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                             -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).jul_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).jul_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_7;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(3).tag_name := gv_name_jul;
          gr_xml_out(3).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(3).tag_name := gv_name_jul;
          gr_xml_out(3).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (���_����)���o�f�[�^���W���̏ꍇ --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_aug_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_aug                               -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                  -- �N�v�p ����
             ,on_price          => ln_price                                  -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_8>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).aug_quant     :=
               gr_add_total(r).aug_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- ����
            gr_add_total(r).aug_amount    :=
               gr_add_total(r).aug_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- ���z
            gr_add_total(r).aug_price     :=
               gr_add_total(r).aug_price     + ln_price;                                  -- �i�ڒ艿
            gr_add_total(r).aug_to_amount :=
               gr_add_total(r).aug_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- ���󍇌v
            gr_add_total(r).aug_quant_t   :=
               gr_add_total(r).aug_quant_t   + ln_quant;                                  -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).aug_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).aug_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).aug_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).aug_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                             -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).aug_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).aug_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_8;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(4).tag_name := gv_name_aug;
          gr_xml_out(4).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(4).tag_name := gv_name_aug;
          gr_xml_out(4).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (���_����)���o�f�[�^���X���̏ꍇ --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_sep_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_sep                               -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                  -- �N�v�p ����
             ,on_price          => ln_price                                  -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_9>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).sep_quant     :=
               gr_add_total(r).sep_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- ����
            gr_add_total(r).sep_amount    :=
               gr_add_total(r).sep_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- ���z
            gr_add_total(r).sep_price     :=
               gr_add_total(r).sep_price     + ln_price;                                  -- �i�ڒ艿
            gr_add_total(r).sep_to_amount :=
               gr_add_total(r).sep_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- ���󍇌v
            gr_add_total(r).sep_quant_t   :=
               gr_add_total(r).sep_quant_t   + ln_quant;                                  -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).sep_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).sep_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).sep_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).sep_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).sep_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).sep_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_9;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(5).tag_name := gv_name_sep;
          gr_xml_out(5).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(5).tag_name := gv_name_sep;
          gr_xml_out(5).out_fg   := lv_no;
        END IF;
--
        ----------------------------------------
        -- (���_����)���o�f�[�^���P�O���̏ꍇ --
        ----------------------------------------
        IF (gr_sale_plan_1(i).month = lv_oct_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_oct                               -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                  -- �N�v�p ����
             ,on_price          => ln_price                                  -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_10>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).oct_quant     :=
               gr_add_total(r).oct_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- ����
            gr_add_total(r).oct_amount    :=
               gr_add_total(r).oct_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- ���z
            gr_add_total(r).oct_price     :=
               gr_add_total(r).oct_price     + ln_price;                                  -- �i�ڒ艿
            gr_add_total(r).oct_to_amount :=
               gr_add_total(r).oct_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- ���󍇌v
            gr_add_total(r).oct_quant_t   :=
               gr_add_total(r).oct_quant_t   + ln_quant;                                  -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).oct_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).oct_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).oct_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).oct_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).oct_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).oct_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_10;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(6).tag_name := gv_name_oct;
          gr_xml_out(6).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(6).tag_name := gv_name_oct;
          gr_xml_out(6).out_fg   := lv_no;
        END IF;
--
        ----------------------------------------
        -- (���_����)���o�f�[�^���P�P���̏ꍇ --
        ----------------------------------------
        IF (gr_sale_plan_1(i).month = lv_nov_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_nov                               -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                  -- �N�v�p ����
             ,on_price          => ln_price                                  -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_11>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).nov_quant     :=
              gr_add_total(r).nov_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- ����
            gr_add_total(r).nov_amount    :=
              gr_add_total(r).nov_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- ���z
            gr_add_total(r).nov_price     :=
              gr_add_total(r).nov_price     + ln_price;                                  -- �i�ڒ艿
            gr_add_total(r).nov_to_amount :=
              gr_add_total(r).nov_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- ���󍇌v
            gr_add_total(r).nov_quant_t   :=
              gr_add_total(r).nov_quant_t   + ln_quant;                                  -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).nov_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).nov_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).nov_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).nov_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).nov_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).nov_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_11;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(7).tag_name := gv_name_nov;
          gr_xml_out(7).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(7).tag_name := gv_name_nov;
          gr_xml_out(7).out_fg   := lv_no;
        END IF;
--
        ----------------------------------------
        -- (���_����)���o�f�[�^���P�Q���̏ꍇ --
        ----------------------------------------
        IF (gr_sale_plan_1(i).month = lv_dec_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_dec                               -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                  -- �N�v�p ����
             ,on_price          => ln_price                                  -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_12>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).dec_quant     :=
              gr_add_total(r).dec_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- ����
            gr_add_total(r).dec_amount    :=
              gr_add_total(r).dec_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- ���z
            gr_add_total(r).dec_price     :=
              gr_add_total(r).dec_price     + ln_price;                                  -- �i�ڒ艿
            gr_add_total(r).dec_to_amount :=
              gr_add_total(r).dec_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- ���󍇌v
            gr_add_total(r).dec_quant_t   :=
              gr_add_total(r).dec_quant_t   + ln_quant;                                  -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).dec_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).dec_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).dec_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).dec_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).dec_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).dec_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_12;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(8).tag_name := gv_name_dec;
          gr_xml_out(8).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(8).tag_name := gv_name_dec;
          gr_xml_out(8).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (���_����)���o�f�[�^���P���̏ꍇ --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_jan_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_jan                               -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                  -- �N�v�p ����
             ,on_price          => ln_price                                  -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_1>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).jan_quant     :=
              gr_add_total(r).jan_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- ����
            gr_add_total(r).jan_amount    :=
              gr_add_total(r).jan_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- ���z
            gr_add_total(r).jan_price     :=
              gr_add_total(r).jan_price     + ln_price;                                  -- �i�ڒ艿
            gr_add_total(r).jan_to_amount :=
              gr_add_total(r).jan_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- ���󍇌v
            gr_add_total(r).jan_quant_t   :=
              gr_add_total(r).jan_quant_t   + ln_quant;                                  -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).jan_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).jan_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).jan_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).jan_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).jan_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).jan_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_1;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(9).tag_name := gv_name_jan;
          gr_xml_out(9).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(9).tag_name := gv_name_jan;
          gr_xml_out(9).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (���_����)���o�f�[�^���Q���̏ꍇ --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_feb_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_feb                               -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                  -- �N�v�p ����
             ,on_price          => ln_price                                  -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_2>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).feb_quant     :=
              gr_add_total(r).feb_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- ����
            gr_add_total(r).feb_amount    :=
              gr_add_total(r).feb_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- ���z
            gr_add_total(r).feb_price     :=
              gr_add_total(r).feb_price     + ln_price;                                  -- �i�ڒ艿
            gr_add_total(r).feb_to_amount :=
              gr_add_total(r).feb_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- ���󍇌v
            gr_add_total(r).feb_quant_t   :=
              gr_add_total(r).feb_quant_t   + ln_quant;                                  -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).feb_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).feb_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).feb_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).feb_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).feb_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).feb_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_2;
          -- XML�o�̓t���O�X�V
          gr_xml_out(10).tag_name := gv_name_feb;
          gr_xml_out(10).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(10).tag_name := gv_name_feb;
          gr_xml_out(10).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (���_����)���o�f�[�^���R���̏ꍇ --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_mar_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
           (
             iv_label_name     => gv_name_mar                               -- �o�̓^�O��
            ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- ����
            ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- ����
            ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- ���z
            ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- ���󍇌v
            ,iv_price_st       => gr_sale_plan_1(i).price_st                -- �艿�K�p�J�n��
            ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- �V�艿
            ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- ���艿
            ,on_quant          => ln_quant                                  -- �N�v�p ����
            ,on_price          => ln_price                                  -- �N�v�p �i�ڒ艿
            ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
           );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_3>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).mar_quant     :=
              gr_add_total(r).mar_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- ����
            gr_add_total(r).mar_amount    :=
              gr_add_total(r).mar_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- ���z
            gr_add_total(r).mar_price     :=
              gr_add_total(r).mar_price     + ln_price;                                  -- �i�ڒ艿
            gr_add_total(r).mar_to_amount :=
              gr_add_total(r).mar_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- ���󍇌v
            gr_add_total(r).mar_quant_t   :=
              gr_add_total(r).mar_quant_t   + ln_quant;                                  -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).mar_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).mar_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).mar_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).mar_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).mar_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).mar_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_3;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(11).tag_name := gv_name_mar;
          gr_xml_out(11).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(11).tag_name := gv_name_mar;
          gr_xml_out(11).out_fg   := lv_no;
        END IF;
--
        --------------------------------------
        -- (���_����)���o�f�[�^���S���̏ꍇ --
        --------------------------------------
        IF (gr_sale_plan_1(i).month = lv_apr_name) THEN
          -- ���o�f�[�^ �L
          prc_create_xml_data_dtl
            (
              iv_label_name     => gv_name_apr                               -- �o�̓^�O��
             ,in_quant          => TO_NUMBER(gr_sale_plan_1(i).quant)        -- ����
             ,in_case_quant     => TO_NUMBER(gr_sale_plan_1(i).case_quant)   -- ����
             ,in_amount         => TO_NUMBER(gr_sale_plan_1(i).amount)       -- ���z
             ,in_total_amount   => TO_NUMBER(gr_sale_plan_1(i).total_amount) -- ���󍇌v
             ,iv_price_st       => gr_sale_plan_1(i).price_st                -- �艿�K�p�J�n��
             ,in_n_amount       => TO_NUMBER(gr_sale_plan_1(i).n_amount)     -- �V�艿
             ,in_o_amount       => TO_NUMBER(gr_sale_plan_1(i).o_amount)     -- ���艿
             ,on_quant          => ln_quant                                  -- �N�v�p ����
             ,on_price          => ln_price                                  -- �N�v�p �i�ڒ艿
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �N�v�W�v���ڌv�Z
          ln_year_quant_sum  := ln_year_quant_sum  + ln_quant;             -- ����
          ln_year_amount_sum := ln_year_amount_sum + TO_NUMBER(gr_sale_plan_1(i).amount);
                                                                           -- ���z
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
          ln_year_to_am_sum  := ln_year_to_am_sum  + TO_NUMBER(gr_sale_plan_1(i).total_amount);
                                                                           -- ���󍇌v
          ln_year_price_sum  := ln_year_price_sum  + ln_price;             -- �i�ڒ艿
*/
          ln_year_to_am_sum  := TO_NUMBER(gr_sale_plan_1(i).total_amount);   -- ���󍇌v
          ln_year_price_sum  := ln_price;                                  -- �i�ڒ艿
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
          -- �e�W�v���ڂփf�[�^�}��
          <<add_total_loop_4>>
          FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
            gr_add_total(r).apr_quant     :=
              gr_add_total(r).apr_quant     + TO_NUMBER(gr_sale_plan_1(i).quant);        -- ����
            gr_add_total(r).apr_amount    :=
              gr_add_total(r).apr_amount    + TO_NUMBER(gr_sale_plan_1(i).amount);       -- ���z
            gr_add_total(r).apr_price     :=
              gr_add_total(r).apr_price     + ln_price;                                  -- �i�ڒ艿
            gr_add_total(r).apr_to_amount :=
              gr_add_total(r).apr_to_amount + TO_NUMBER(gr_sale_plan_1(i).total_amount); -- ���󍇌v
            gr_add_total(r).apr_quant_t   :=
              gr_add_total(r).apr_quant_t   + ln_quant;                                  -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
            gr_add_total(r).apr_s_cost    :=                                            -- �W������(�v)
                gr_add_total(r).apr_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).apr_calc      :=                                            -- �i�ڒ艿*����(�v)
                gr_add_total(r).apr_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            gr_add_total(r).year_s_cost    :=                                            -- �N��.�W������(�v)
                gr_add_total(r).year_s_cost   + (TO_NUMBER(gr_sale_plan_1(i).total_amount) * TO_NUMBER(gr_sale_plan_1(i).quant));
            gr_add_total(r).year_calc      :=                                            -- �N��.�i�ڒ艿*����(�v)
                gr_add_total(r).year_calc     + (ln_price * TO_NUMBER(gr_sale_plan_1(i).quant));
--
            -- ���ʂ��}�C�i�X�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( TO_NUMBER(gr_sale_plan_1(i).quant) < 0 ) THEN
              gr_add_total(r).apr_minus_flg := 'Y';
            END IF;
--
            -- �i�ڒ艿��0�̏ꍇ(���Ԃł̑��݃`�F�b�N)
            IF ( ln_price = 0 ) THEN
              gr_add_total(r).apr_ht_zero_flg := 'Y';
            END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
          END LOOP add_total_loop_4;
--
          -- XML�o�̓t���O�X�V
          gr_xml_out(12).tag_name := gv_name_apr;
          gr_xml_out(12).out_fg   := lv_yes;
        ELSE
          -- XML�o�̓t���O�X�V
          gr_xml_out(12).tag_name := gv_name_apr;
          gr_xml_out(12).out_fg   := lv_no;
        END IF;
--
        ------------------------------------------------
        -- (���_����)�u���C�N�L�[�X�V                 --
        ------------------------------------------------
        lv_dtl_break := gr_sale_plan_1(i).item_no;
--
      END LOOP main_data_loop_1;
--
      -- =====================================================
      -- (���_����)�I������
      -- =====================================================
      -----------------------------------------------------------------
      -- (���_����)�e�����o�f�[�^�����݂��Ȃ��ꍇ�A0�\���ɂ�XML�o��  --
      -----------------------------------------------------------------
      <<xml_out_0_loop>>
      FOR m IN 1..12 LOOP
        IF (gr_xml_out(m).out_fg = lv_no) THEN
          prc_create_xml_data_dtl_n
            (
              iv_label_name     => gr_xml_out(m).tag_name                      -- �o�̓^�O��
             ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END LOOP xml_out_0_loop;
--
      -- -----------------------------------------------------
      -- (���_����)�N�v ���ʃf�[�^
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_quant';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ln_year_quant_sum;
--
      -- -----------------------------------------------------
      -- (���_����)�N�v ���z�f�[�^
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_amount';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := ROUND(ln_year_amount_sum / 1000,0);
--
      -- -----------------------------------------------------
      -- (���_����)�N�v �e�����f�[�^
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_arari_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
      ------------------------------------------------
      -- (���_����)�e���v�Z (���z�|���󍇌v������)  --
      ------------------------------------------------
      ln_arari := ln_year_amount_sum - ln_year_to_am_sum * ln_year_quant_sum;
      -- �O���Z��𔻒�
      IF (ln_year_amount_sum <> gn_0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        gt_xml_data_table(gl_xml_idx).tag_value := 
                ROUND((ln_arari / ln_year_amount_sum * 100),2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        gt_xml_data_table(gl_xml_idx).tag_value := gn_0;
      END IF;
--
      -- -----------------------------------------------------
      -- (���_����)�N�v �|���f�[�^
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year_kake_par';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
--
      --------------------------------------
      -- �O���Z���荀�ڂ֔���l��}��     --
      --------------------------------------
      ln_chk_0 := ln_year_price_sum * ln_year_quant_sum;
      -- �O���Z��𔻒�
      IF (ln_chk_0 <> gn_0) THEN
        -- �l��[0]�o�Ȃ���Όv�Z
        ln_kake_par := ROUND((ln_year_amount_sum * 100) / ln_chk_0,2);
      ELSE
        -- �l��[0]�̏ꍇ�́A�ꗥ[0]�ݒ�
        ln_kake_par := gn_0;
      END IF;
--
      -- �i�ڒ艿 = �O���A�v�Z���ʂ��}�C�i�X�̏ꍇ�A�Œ�l[70.00]��o�^
      IF ((ln_year_price_sum = 0)
        OR (ln_kake_par < 0)) THEN
        ln_kake_par := gn_kotei_70; -- �Œ�l[70.00]
      END IF;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_kake_par;
--
      -- �e�W�v���ڂփf�[�^�}��
      <<add_total_loop>>
      FOR r IN 1..5 LOOP                     -- ���Q�v/��Q�v/���_�v/���i�敪�v/�����v
        gr_add_total(r).year_quant     :=
           gr_add_total(r).year_quant     + ln_year_quant_sum;        -- ����
        gr_add_total(r).year_amount    :=
           gr_add_total(r).year_amount    + ln_year_amount_sum;       -- ���z
        gr_add_total(r).year_price     :=
           gr_add_total(r).year_price     + ln_year_price_sum;        -- �i�ڒ艿
        gr_add_total(r).year_to_amount :=
           gr_add_total(r).year_to_amount + ln_year_to_am_sum;        -- ���󍇌v
        gr_add_total(r).year_quant_t   :=
           gr_add_total(r).year_quant_t   + ln_year_quant_sum;        -- ����(�v)
-- 2009/04/16 v1.6 T.Yoshimoto Add Start �{��#1410
        -- ���ʂ��}�C�i�X�̏ꍇ(�N�Ԃł̑��݃`�F�b�N)
        IF ( ln_year_quant_sum < 0 ) THEN
          gr_add_total(r).year_minus_flg := 'Y';
        END IF;
--
        -- �i�ڒ艿��0�̏ꍇ(�N�Ԃł̑��݃`�F�b�N)
        IF ( ln_year_price_sum = 0 ) THEN
          gr_add_total(r).year_ht_zero_flg := 'Y';
        END IF;
-- 2009/04/16 v1.6 T.Yoshimoto Add End �{��#1410
      END LOOP add_total_loop;
--
      -- -----------------------------------------------------
      --  (���_����)�i�ڏI���f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  (���_����)�i�ڏI���k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
      --------------------------------------------------------
      -- ���Q�v�f�[�^�^�O�o�� 
      --------------------------------------------------------
      prc_create_xml_data_st_lt
        (
          iv_label_name     => gv_name_st                     -- ���Q�v�p�^�O��
         ,iv_name           => gv_label_st                    -- ���Q�v�^�C�g��
         ,in_may_quant      => gr_add_total(1).may_quant      -- �T�� ����
         ,in_may_amount     => gr_add_total(1).may_amount     -- �T�� ���z
         ,in_may_price      => gr_add_total(1).may_price      -- �T�� �i�ڒ艿
         ,in_may_to_amount  => gr_add_total(1).may_to_amount  -- �T�� ���󍇌v
         ,in_may_quant_t    => gr_add_total(1).may_quant_t    -- �T�� ����(�v�Z�p)
         ,in_jun_quant      => gr_add_total(1).jun_quant      -- �U�� ����
         ,in_jun_amount     => gr_add_total(1).jun_amount     -- �U�� ���z
         ,in_jun_price      => gr_add_total(1).jun_price      -- �U�� �i�ڒ艿
         ,in_jun_to_amount  => gr_add_total(1).jun_to_amount  -- �U�� ���󍇌v
         ,in_jun_quant_t    => gr_add_total(1).jun_quant_t    -- �U�� ����(�v�Z�p)
         ,in_jul_quant      => gr_add_total(1).jul_quant      -- �V�� ����
         ,in_jul_amount     => gr_add_total(1).jul_amount     -- �V�� ���z
         ,in_jul_price      => gr_add_total(1).jul_price      -- �V�� �i�ڒ艿
         ,in_jul_to_amount  => gr_add_total(1).jul_to_amount  -- �V�� ���󍇌v
         ,in_jul_quant_t    => gr_add_total(1).jul_quant_t    -- �V�� ����(�v�Z�p)
         ,in_aug_quant      => gr_add_total(1).aug_quant      -- �W�� ����
         ,in_aug_amount     => gr_add_total(1).aug_amount     -- �W�� ���z
         ,in_aug_price      => gr_add_total(1).aug_price      -- �W�� �i�ڒ艿
         ,in_aug_to_amount  => gr_add_total(1).aug_to_amount  -- �W�� ���󍇌v
         ,in_aug_quant_t    => gr_add_total(1).aug_quant_t    -- �W�� ����(�v�Z�p)
         ,in_sep_quant      => gr_add_total(1).sep_quant      -- �X�� ����
         ,in_sep_amount     => gr_add_total(1).sep_amount     -- �X�� ���z
         ,in_sep_price      => gr_add_total(1).sep_price      -- �X�� �i�ڒ艿
         ,in_sep_to_amount  => gr_add_total(1).sep_to_amount  -- �X�� ���󍇌v
         ,in_sep_quant_t    => gr_add_total(1).sep_quant_t    -- �X�� ����(�v�Z�p)
         ,in_oct_quant      => gr_add_total(1).oct_quant      -- �P�O�� ����
         ,in_oct_amount     => gr_add_total(1).oct_amount     -- �P�O�� ���z
         ,in_oct_price      => gr_add_total(1).oct_price      -- �P�O�� �i�ڒ艿
         ,in_oct_to_amount  => gr_add_total(1).oct_to_amount  -- �P�O�� ���󍇌v
         ,in_oct_quant_t    => gr_add_total(1).oct_quant_t    -- �P�O�� ����(�v�Z�p)
         ,in_nov_quant      => gr_add_total(1).nov_quant      -- �P�P�� ����
         ,in_nov_amount     => gr_add_total(1).nov_amount     -- �P�P�� ���z
         ,in_nov_price      => gr_add_total(1).nov_price      -- �P�P�� �i�ڒ艿
         ,in_nov_to_amount  => gr_add_total(1).nov_to_amount  -- �P�P�� ���󍇌v
         ,in_nov_quant_t    => gr_add_total(1).nov_quant_t    -- �P�P�� ����(�v�Z�p)
         ,in_dec_quant      => gr_add_total(1).dec_quant      -- �P�Q�� ����
         ,in_dec_amount     => gr_add_total(1).dec_amount     -- �P�Q�� ���z
         ,in_dec_price      => gr_add_total(1).dec_price      -- �P�Q�� �i�ڒ艿
         ,in_dec_to_amount  => gr_add_total(1).dec_to_amount  -- �P�Q�� ���󍇌v
         ,in_dec_quant_t    => gr_add_total(1).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
         ,in_jan_quant      => gr_add_total(1).jan_quant      -- �P�� ����
         ,in_jan_amount     => gr_add_total(1).jan_amount     -- �P�� ���z
         ,in_jan_price      => gr_add_total(1).jan_price      -- �P�� �i�ڒ艿
         ,in_jan_to_amount  => gr_add_total(1).jan_to_amount  -- �P�� ���󍇌v
         ,in_jan_quant_t    => gr_add_total(1).jan_quant_t    -- �P�� ����(�v�Z�p)
         ,in_feb_quant      => gr_add_total(1).feb_quant      -- �Q�� ����
         ,in_feb_amount     => gr_add_total(1).feb_amount     -- �Q�� ���z
         ,in_feb_price      => gr_add_total(1).feb_price      -- �Q�� �i�ڒ艿
         ,in_feb_to_amount  => gr_add_total(1).feb_to_amount  -- �Q�� ���󍇌v
         ,in_feb_quant_t    => gr_add_total(1).feb_quant_t    -- �Q�� ����(�v�Z�p)
         ,in_mar_quant      => gr_add_total(1).mar_quant      -- �R�� ����
         ,in_mar_amount     => gr_add_total(1).mar_amount     -- �R�� ���z
         ,in_mar_price      => gr_add_total(1).mar_price      -- �R�� �i�ڒ艿
         ,in_mar_to_amount  => gr_add_total(1).mar_to_amount  -- �R�� ���󍇌v
         ,in_mar_quant_t    => gr_add_total(1).mar_quant_t    -- �R�� ����(�v�Z�p)
         ,in_apr_quant      => gr_add_total(1).apr_quant      -- �S�� ����
         ,in_apr_amount     => gr_add_total(1).apr_amount     -- �S�� ���z
         ,in_apr_price      => gr_add_total(1).apr_price      -- �S�� �i�ڒ艿
         ,in_apr_to_amount  => gr_add_total(1).apr_to_amount  -- �S�� ���󍇌v
         ,in_apr_quant_t    => gr_add_total(1).apr_quant_t    -- �S�� ����(�v�Z�p)
         ,in_year_quant     => gr_add_total(1).year_quant     -- �N�v ����
         ,in_year_amount    => gr_add_total(1).year_amount    -- �N�v ���z
         ,in_year_price     => gr_add_total(1).year_price     -- �N�v �i�ڒ艿
         ,in_year_to_amount => gr_add_total(1).year_to_amount -- �N�v ���󍇌v
         ,in_year_quant_t   => gr_add_total(1).year_quant_t   -- �N�v ����(�v�Z�p)
         ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      --------------------------------------------------------
      -- ��Q�v�f�[�^�^�O�o�� 
      --------------------------------------------------------
      prc_create_xml_data_st_lt
        (
          iv_label_name     => gv_name_lt                     -- ��Q�v�p�^�O��
         ,iv_name           => gv_label_lt                    -- ��Q�v�^�C�g��
         ,in_may_quant      => gr_add_total(2).may_quant      -- �T�� ����
         ,in_may_amount     => gr_add_total(2).may_amount     -- �T�� ���z
         ,in_may_price      => gr_add_total(2).may_price      -- �T�� �i�ڒ艿
         ,in_may_to_amount  => gr_add_total(2).may_to_amount  -- �T�� ���󍇌v
         ,in_may_quant_t    => gr_add_total(2).may_quant_t    -- �T�� ����(�v�Z�p)
         ,in_jun_quant      => gr_add_total(2).jun_quant      -- �U�� ����
         ,in_jun_amount     => gr_add_total(2).jun_amount     -- �U�� ���z
         ,in_jun_price      => gr_add_total(2).jun_price      -- �U�� �i�ڒ艿
         ,in_jun_to_amount  => gr_add_total(2).jun_to_amount  -- �U�� ���󍇌v
         ,in_jun_quant_t    => gr_add_total(2).jun_quant_t    -- �U�� ����(�v�Z�p)
         ,in_jul_quant      => gr_add_total(2).jul_quant      -- �V�� ����
         ,in_jul_amount     => gr_add_total(2).jul_amount     -- �V�� ���z
         ,in_jul_price      => gr_add_total(2).jul_price      -- �V�� �i�ڒ艿
         ,in_jul_to_amount  => gr_add_total(2).jul_to_amount  -- �V�� ���󍇌v
         ,in_jul_quant_t    => gr_add_total(2).jul_quant_t    -- �V�� ����(�v�Z�p)
         ,in_aug_quant      => gr_add_total(2).aug_quant      -- �W�� ����
         ,in_aug_amount     => gr_add_total(2).aug_amount     -- �W�� ���z
         ,in_aug_price      => gr_add_total(2).aug_price      -- �W�� �i�ڒ艿
         ,in_aug_to_amount  => gr_add_total(2).aug_to_amount  -- �W�� ���󍇌v
         ,in_aug_quant_t    => gr_add_total(2).aug_quant_t    -- �W�� ����(�v�Z�p)
         ,in_sep_quant      => gr_add_total(2).sep_quant      -- �X�� ����
         ,in_sep_amount     => gr_add_total(2).sep_amount     -- �X�� ���z
         ,in_sep_price      => gr_add_total(2).sep_price      -- �X�� �i�ڒ艿
         ,in_sep_to_amount  => gr_add_total(2).sep_to_amount  -- �X�� ���󍇌v
         ,in_sep_quant_t    => gr_add_total(2).sep_quant_t    -- �X�� ����(�v�Z�p)
         ,in_oct_quant      => gr_add_total(2).oct_quant      -- �P�O�� ����
         ,in_oct_amount     => gr_add_total(2).oct_amount     -- �P�O�� ���z
         ,in_oct_price      => gr_add_total(2).oct_price      -- �P�O�� �i�ڒ艿
         ,in_oct_to_amount  => gr_add_total(2).oct_to_amount  -- �P�O�� ���󍇌v
         ,in_oct_quant_t    => gr_add_total(2).oct_quant_t    -- �P�O�� ����(�v�Z�p)
         ,in_nov_quant      => gr_add_total(2).nov_quant      -- �P�P�� ����
         ,in_nov_amount     => gr_add_total(2).nov_amount     -- �P�P�� ���z
         ,in_nov_price      => gr_add_total(2).nov_price      -- �P�P�� �i�ڒ艿
         ,in_nov_to_amount  => gr_add_total(2).nov_to_amount  -- �P�P�� ���󍇌v
         ,in_nov_quant_t    => gr_add_total(2).nov_quant_t    -- �P�P�� ����(�v�Z�p)
         ,in_dec_quant      => gr_add_total(2).dec_quant      -- �P�Q�� ����
         ,in_dec_amount     => gr_add_total(2).dec_amount     -- �P�Q�� ���z
         ,in_dec_price      => gr_add_total(2).dec_price      -- �P�Q�� �i�ڒ艿
         ,in_dec_to_amount  => gr_add_total(2).dec_to_amount  -- �P�Q�� ���󍇌v
         ,in_dec_quant_t    => gr_add_total(2).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
         ,in_jan_quant      => gr_add_total(2).jan_quant      -- �P�� ����
         ,in_jan_amount     => gr_add_total(2).jan_amount     -- �P�� ���z
         ,in_jan_price      => gr_add_total(2).jan_price      -- �P�� �i�ڒ艿
         ,in_jan_to_amount  => gr_add_total(2).jan_to_amount  -- �P�� ���󍇌v
         ,in_jan_quant_t    => gr_add_total(2).jan_quant_t    -- �P�� ����(�v�Z�p)
         ,in_feb_quant      => gr_add_total(2).feb_quant      -- �Q�� ����
         ,in_feb_amount     => gr_add_total(2).feb_amount     -- �Q�� ���z
         ,in_feb_price      => gr_add_total(2).feb_price      -- �Q�� �i�ڒ艿
         ,in_feb_to_amount  => gr_add_total(2).feb_to_amount  -- �Q�� ���󍇌v
         ,in_feb_quant_t    => gr_add_total(2).feb_quant_t    -- �Q�� ����(�v�Z�p)
         ,in_mar_quant      => gr_add_total(2).mar_quant      -- �R�� ����
         ,in_mar_amount     => gr_add_total(2).mar_amount     -- �R�� ���z
         ,in_mar_price      => gr_add_total(2).mar_price      -- �R�� �i�ڒ艿
         ,in_mar_to_amount  => gr_add_total(2).mar_to_amount  -- �R�� ���󍇌v
         ,in_mar_quant_t    => gr_add_total(2).mar_quant_t    -- �R�� ����(�v�Z�p)
         ,in_apr_quant      => gr_add_total(2).apr_quant      -- �S�� ����
         ,in_apr_amount     => gr_add_total(2).apr_amount     -- �S�� ���z
         ,in_apr_price      => gr_add_total(2).apr_price      -- �S�� �i�ڒ艿
         ,in_apr_to_amount  => gr_add_total(2).apr_to_amount  -- �S�� ���󍇌v
         ,in_apr_quant_t    => gr_add_total(2).apr_quant_t    -- �S�� ����(�v�Z�p)
         ,in_year_quant     => gr_add_total(2).year_quant     -- �N�v ����
         ,in_year_amount    => gr_add_total(2).year_amount    -- �N�v ���z
         ,in_year_price     => gr_add_total(2).year_price     -- �N�v �i�ڒ艿
         ,in_year_to_amount => gr_add_total(2).year_to_amount -- �N�v ���󍇌v
         ,in_year_quant_t   => gr_add_total(2).year_quant_t   -- �N�v ����(�v�Z�p)
         ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
*/
--
      --------------------------------------------------------
      -- (���_����)(1)���Q�v/(2)��Q�v�f�[�^�o�� 
      --------------------------------------------------------
      <<gun_loop>>
      FOR n IN 1..2 LOOP        -- ���Q�v/��Q�v
--
        -- ���Q�v�̏ꍇ
        IF ( n = 1) THEN
          lv_param_name  := gv_name_st;
          lv_param_label := gv_label_st;
        -- ��Q�v�̏ꍇ
        ELSE
          lv_param_name  := gv_name_lt;
          lv_param_label := gv_label_lt;
        END IF;
--
        prc_create_xml_data_st_lt
        (
            iv_label_name      => lv_param_name                   -- ��Q�v�p�^�O��
          ,iv_name            => lv_param_label                  -- ��Q�v�^�C�g��
          ,in_may_quant       => gr_add_total(n).may_quant       -- �T�� ����
          ,in_may_amount      => gr_add_total(n).may_amount      -- �T�� ���z
          ,in_may_price       => gr_add_total(n).may_price       -- �T�� �i�ڒ艿
          ,in_may_to_amount   => gr_add_total(n).may_to_amount   -- �T�� ���󍇌v
          ,in_may_quant_t     => gr_add_total(n).may_quant_t     -- �T�� ����(�v�Z�p)
          ,in_may_s_cost      => gr_add_total(n).may_s_cost      -- �T�� �W������(�v�Z�p)
          ,in_may_calc        => gr_add_total(n).may_calc        -- �T�� �i�ڒ艿*����(�v�Z�p)
          ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
          ,in_jun_quant       => gr_add_total(n).jun_quant       -- �U�� ����
          ,in_jun_amount      => gr_add_total(n).jun_amount      -- �U�� ���z
          ,in_jun_price       => gr_add_total(n).jun_price       -- �U�� �i�ڒ艿
          ,in_jun_to_amount   => gr_add_total(n).jun_to_amount   -- �U�� ���󍇌v
          ,in_jun_quant_t     => gr_add_total(n).jun_quant_t     -- �U�� ����(�v�Z�p)
          ,in_jun_s_cost      => gr_add_total(n).jun_s_cost      -- �U�� �W������(�v�Z�p)
          ,in_jun_calc        => gr_add_total(n).jun_calc        -- �U�� �i�ڒ艿*����(�v�Z�p)
          ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
          ,in_jul_quant       => gr_add_total(n).jul_quant       -- �V�� ����
          ,in_jul_amount      => gr_add_total(n).jul_amount      -- �V�� ���z
          ,in_jul_price       => gr_add_total(n).jul_price       -- �V�� �i�ڒ艿
          ,in_jul_to_amount   => gr_add_total(n).jul_to_amount   -- �V�� ���󍇌v
          ,in_jul_quant_t     => gr_add_total(n).jul_quant_t     -- �V�� ����(�v�Z�p)
          ,in_jul_s_cost      => gr_add_total(n).jul_s_cost      -- �V�� �W������(�v�Z�p)
          ,in_jul_calc        => gr_add_total(n).jul_calc        -- �V�� �i�ڒ艿*����(�v�Z�p)
          ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
          ,in_aug_quant       => gr_add_total(n).aug_quant       -- �W�� ����
          ,in_aug_amount      => gr_add_total(n).aug_amount      -- �W�� ���z
          ,in_aug_price       => gr_add_total(n).aug_price       -- �W�� �i�ڒ艿
          ,in_aug_to_amount   => gr_add_total(n).aug_to_amount   -- �W�� ���󍇌v
          ,in_aug_quant_t     => gr_add_total(n).aug_quant_t     -- �W�� ����(�v�Z�p)
          ,in_aug_s_cost      => gr_add_total(n).aug_s_cost      -- �W�� �W������(�v�Z�p)
          ,in_aug_calc        => gr_add_total(n).aug_calc        -- �W�� �i�ڒ艿*����(�v�Z�p)
          ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
          ,in_sep_quant       => gr_add_total(n).sep_quant       -- �X�� ����
          ,in_sep_amount      => gr_add_total(n).sep_amount      -- �X�� ���z
          ,in_sep_price       => gr_add_total(n).sep_price       -- �X�� �i�ڒ艿
          ,in_sep_to_amount   => gr_add_total(n).sep_to_amount   -- �X�� ���󍇌v
          ,in_sep_quant_t     => gr_add_total(n).sep_quant_t     -- �X�� ����(�v�Z�p)
          ,in_sep_s_cost      => gr_add_total(n).sep_s_cost      -- �X�� �W������(�v�Z�p)
          ,in_sep_calc        => gr_add_total(n).sep_calc        -- �X�� �i�ڒ艿*����(�v�Z�p)
          ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
          ,in_oct_quant       => gr_add_total(n).oct_quant       -- �P�O�� ����
          ,in_oct_amount      => gr_add_total(n).oct_amount      -- �P�O�� ���z
          ,in_oct_price       => gr_add_total(n).oct_price       -- �P�O�� �i�ڒ艿
          ,in_oct_to_amount   => gr_add_total(n).oct_to_amount   -- �P�O�� ���󍇌v
          ,in_oct_quant_t     => gr_add_total(n).oct_quant_t     -- �P�O�� ����(�v�Z�p)
          ,in_oct_s_cost      => gr_add_total(n).oct_s_cost      -- �P�O�� �W������(�v�Z�p)
          ,in_oct_calc        => gr_add_total(n).oct_calc        -- �P�O�� �i�ڒ艿*����(�v�Z�p)
          ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
          ,in_nov_quant       => gr_add_total(n).nov_quant       -- �P�P�� ����
          ,in_nov_amount      => gr_add_total(n).nov_amount      -- �P�P�� ���z
          ,in_nov_price       => gr_add_total(n).nov_price       -- �P�P�� �i�ڒ艿
          ,in_nov_to_amount   => gr_add_total(n).nov_to_amount   -- �P�P�� ���󍇌v
          ,in_nov_quant_t     => gr_add_total(n).nov_quant_t     -- �P�P�� ����(�v�Z�p)
          ,in_nov_s_cost      => gr_add_total(n).nov_s_cost      -- �P�P�� �W������(�v�Z�p)
          ,in_nov_calc        => gr_add_total(n).nov_calc        -- �P�P�� �i�ڒ艿*����(�v�Z�p)
          ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
          ,in_dec_quant       => gr_add_total(n).dec_quant       -- �P�Q�� ����
          ,in_dec_amount      => gr_add_total(n).dec_amount      -- �P�Q�� ���z
          ,in_dec_price       => gr_add_total(n).dec_price       -- �P�Q�� �i�ڒ艿
          ,in_dec_to_amount   => gr_add_total(n).dec_to_amount   -- �P�Q�� ���󍇌v
          ,in_dec_quant_t     => gr_add_total(n).dec_quant_t     -- �P�Q�� ����(�v�Z�p)
          ,in_dec_s_cost      => gr_add_total(n).dec_s_cost      -- �P�Q�� �W������(�v�Z�p)
          ,in_dec_calc        => gr_add_total(n).dec_calc        -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
          ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
          ,in_jan_quant       => gr_add_total(n).jan_quant       -- �P�� ����
          ,in_jan_amount      => gr_add_total(n).jan_amount      -- �P�� ���z
          ,in_jan_price       => gr_add_total(n).jan_price       -- �P�� �i�ڒ艿
          ,in_jan_to_amount   => gr_add_total(n).jan_to_amount   -- �P�� ���󍇌v
          ,in_jan_quant_t     => gr_add_total(n).jan_quant_t     -- �P�� ����(�v�Z�p)
          ,in_jan_s_cost      => gr_add_total(n).jan_s_cost      -- �P�� �W������(�v�Z�p)
          ,in_jan_calc        => gr_add_total(n).jan_calc        -- �P�� �i�ڒ艿*����(�v�Z�p)
          ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
          ,in_feb_quant       => gr_add_total(n).feb_quant       -- �Q�� ����
          ,in_feb_amount      => gr_add_total(n).feb_amount      -- �Q�� ���z
          ,in_feb_price       => gr_add_total(n).feb_price       -- �Q�� �i�ڒ艿
          ,in_feb_to_amount   => gr_add_total(n).feb_to_amount   -- �Q�� ���󍇌v
          ,in_feb_quant_t     => gr_add_total(n).feb_quant_t     -- �Q�� ����(�v�Z�p)
          ,in_feb_s_cost      => gr_add_total(n).feb_s_cost      -- �Q�� �W������(�v�Z�p)
          ,in_feb_calc        => gr_add_total(n).feb_calc        -- �Q�� �i�ڒ艿*����(�v�Z�p)
          ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
          ,in_mar_quant       => gr_add_total(n).mar_quant       -- �R�� ����
          ,in_mar_amount      => gr_add_total(n).mar_amount      -- �R�� ���z
          ,in_mar_price       => gr_add_total(n).mar_price       -- �R�� �i�ڒ艿
          ,in_mar_to_amount   => gr_add_total(n).mar_to_amount   -- �R�� ���󍇌v
          ,in_mar_quant_t     => gr_add_total(n).mar_quant_t     -- �R�� ����(�v�Z�p)
          ,in_mar_s_cost      => gr_add_total(n).mar_s_cost      -- �R�� �W������(�v�Z�p)
          ,in_mar_calc        => gr_add_total(n).mar_calc        -- �R�� �i�ڒ艿*����(�v�Z�p)
          ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
          ,in_apr_quant       => gr_add_total(n).apr_quant       -- �S�� ����
          ,in_apr_amount      => gr_add_total(n).apr_amount      -- �S�� ���z
          ,in_apr_price       => gr_add_total(n).apr_price       -- �S�� �i�ڒ艿
          ,in_apr_to_amount   => gr_add_total(n).apr_to_amount   -- �S�� ���󍇌v
          ,in_apr_quant_t     => gr_add_total(n).apr_quant_t     -- �S�� ����(�v�Z�p)
          ,in_apr_s_cost      => gr_add_total(n).apr_s_cost      -- �S�� �W������(�v�Z�p)
          ,in_apr_calc        => gr_add_total(n).apr_calc        -- �S�� �i�ڒ艿*����(�v�Z�p)
          ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
          ,in_year_quant      => gr_add_total(n).year_quant        -- �N�v ����
          ,in_year_amount     => gr_add_total(n).year_amount       -- �N�v ���z
          ,in_year_price      => gr_add_total(n).year_price        -- �N�v �i�ڒ艿
          ,in_year_to_amount  => gr_add_total(n).year_to_amount    -- �N�v ���󍇌v
          ,in_year_quant_t    => gr_add_total(n).year_quant_t      -- �N�v ����(�v�Z�p)
          ,in_year_s_cost     => gr_add_total(n).year_s_cost       -- �N�v �W������(�v�Z�p)
          ,in_year_calc       => gr_add_total(n).year_calc         -- �N�v �i�ڒ艿*����(�v�Z�p)
          ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
          ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP gun_loop;
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod End �{��#1410
--
      -- -----------------------------------------------------
      --  (���_����)�Q�R�[�h�I���f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_gun';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  (���_����)�Q�R�[�h�I���k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_gun_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2009/04/16 v1.6 T.Yoshimoto Mod Start �{��#1410
/*
      --------------------------------------------------------
      -- ���_�v�f�[�^�^�O�o�� 
      --------------------------------------------------------
      prc_create_xml_data_s_k_t
        (
          iv_label_name     => gv_name_ktn                    -- ���_�v�p�^�O��
         ,in_may_quant      => gr_add_total(3).may_quant      -- �T�� ����
         ,in_may_amount     => gr_add_total(3).may_amount     -- �T�� ���z
         ,in_may_price      => gr_add_total(3).may_price      -- �T�� �i�ڒ艿
         ,in_may_to_amount  => gr_add_total(3).may_to_amount  -- �T�� ���󍇌v
         ,in_jun_quant      => gr_add_total(3).jun_quant      -- �U�� ����
         ,in_jun_amount     => gr_add_total(3).jun_amount     -- �U�� ���z
         ,in_jun_price      => gr_add_total(3).jun_price      -- �U�� �i�ڒ艿
         ,in_jun_to_amount  => gr_add_total(3).jun_to_amount  -- �U�� ���󍇌v
         ,in_jul_quant      => gr_add_total(3).jul_quant      -- �V�� ����
         ,in_jul_amount     => gr_add_total(3).jul_amount     -- �V�� ���z
         ,in_jul_price      => gr_add_total(3).jul_price      -- �V�� �i�ڒ艿
         ,in_jul_to_amount  => gr_add_total(3).jul_to_amount  -- �V�� ���󍇌v
         ,in_aug_quant      => gr_add_total(3).aug_quant      -- �W�� ����
         ,in_aug_amount     => gr_add_total(3).aug_amount     -- �W�� ���z
         ,in_aug_price      => gr_add_total(3).aug_price      -- �W�� �i�ڒ艿
         ,in_aug_to_amount  => gr_add_total(3).aug_to_amount  -- �W�� ���󍇌v
         ,in_sep_quant      => gr_add_total(3).sep_quant      -- �X�� ����
         ,in_sep_amount     => gr_add_total(3).sep_amount     -- �X�� ���z
         ,in_sep_price      => gr_add_total(3).sep_price      -- �X�� �i�ڒ艿
         ,in_sep_to_amount  => gr_add_total(3).sep_to_amount  -- �X�� ���󍇌v
         ,in_oct_quant      => gr_add_total(3).oct_quant      -- �P�O�� ����
         ,in_oct_amount     => gr_add_total(3).oct_amount     -- �P�O�� ���z
         ,in_oct_price      => gr_add_total(3).oct_price      -- �P�O�� �i�ڒ艿
         ,in_oct_to_amount  => gr_add_total(3).oct_to_amount  -- �P�O�� ���󍇌v
         ,in_nov_quant      => gr_add_total(3).nov_quant      -- �P�P�� ����
         ,in_nov_amount     => gr_add_total(3).nov_amount     -- �P�P�� ���z
         ,in_nov_price      => gr_add_total(3).nov_price      -- �P�P�� �i�ڒ艿
         ,in_nov_to_amount  => gr_add_total(3).nov_to_amount  -- �P�P�� ���󍇌v
         ,in_dec_quant      => gr_add_total(3).dec_quant      -- �P�Q�� ����
         ,in_dec_amount     => gr_add_total(3).dec_amount     -- �P�Q�� ���z
         ,in_dec_price      => gr_add_total(3).dec_price      -- �P�Q�� �i�ڒ艿
         ,in_dec_to_amount  => gr_add_total(3).dec_to_amount  -- �P�Q�� ���󍇌v
         ,in_jan_quant      => gr_add_total(3).jan_quant      -- �P�� ����
         ,in_jan_amount     => gr_add_total(3).jan_amount     -- �P�� ���z
         ,in_jan_price      => gr_add_total(3).jan_price      -- �P�� �i�ڒ艿
         ,in_jan_to_amount  => gr_add_total(3).jan_to_amount  -- �P�� ���󍇌v
         ,in_feb_quant      => gr_add_total(3).feb_quant      -- �Q�� ����
         ,in_feb_amount     => gr_add_total(3).feb_amount     -- �Q�� ���z
         ,in_feb_price      => gr_add_total(3).feb_price      -- �Q�� �i�ڒ艿
         ,in_feb_to_amount  => gr_add_total(3).feb_to_amount  -- �Q�� ���󍇌v
         ,in_mar_quant      => gr_add_total(3).mar_quant      -- �R�� ����
         ,in_mar_amount     => gr_add_total(3).mar_amount     -- �R�� ���z
         ,in_mar_price      => gr_add_total(3).mar_price      -- �R�� �i�ڒ艿
         ,in_mar_to_amount  => gr_add_total(3).mar_to_amount  -- �R�� ���󍇌v
         ,in_apr_quant      => gr_add_total(3).apr_quant      -- �S�� ����
         ,in_apr_amount     => gr_add_total(3).apr_amount     -- �S�� ���z
         ,in_apr_price      => gr_add_total(3).apr_price      -- �S�� �i�ڒ艿
         ,in_apr_to_amount  => gr_add_total(3).apr_to_amount  -- �S�� ���󍇌v
         ,in_year_quant     => gr_add_total(3).year_quant     -- �N�v ����
         ,in_year_amount    => gr_add_total(3).year_amount    -- �N�v ���z
         ,in_year_price     => gr_add_total(3).year_price     -- �N�v �i�ڒ艿
         ,in_year_to_amount => gr_add_total(3).year_to_amount -- �N�v ���󍇌v
         ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- -----------------------------------------------------
      --  ���_�I���f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      --  ���_�I���k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      --------------------------------------------------------
      -- ���i�敪�v�f�[�^�^�O�o�� 
      --------------------------------------------------------
      prc_create_xml_data_s_k_t
        (
          iv_label_name     => gv_name_skbn                   -- ���i�敪�v�p�^�O��
         ,in_may_quant      => gr_add_total(4).may_quant      -- �T�� ����
         ,in_may_amount     => gr_add_total(4).may_amount     -- �T�� ���z
         ,in_may_price      => gr_add_total(4).may_price      -- �T�� �i�ڒ艿
         ,in_may_to_amount  => gr_add_total(4).may_to_amount  -- �T�� ���󍇌v
         ,in_jun_quant      => gr_add_total(4).jun_quant      -- �U�� ����
         ,in_jun_amount     => gr_add_total(4).jun_amount     -- �U�� ���z
         ,in_jun_price      => gr_add_total(4).jun_price      -- �U�� �i�ڒ艿
         ,in_jun_to_amount  => gr_add_total(4).jun_to_amount  -- �U�� ���󍇌v
         ,in_jul_quant      => gr_add_total(4).jul_quant      -- �V�� ����
         ,in_jul_amount     => gr_add_total(4).jul_amount     -- �V�� ���z
         ,in_jul_price      => gr_add_total(4).jul_price      -- �V�� �i�ڒ艿
         ,in_jul_to_amount  => gr_add_total(4).jul_to_amount  -- �V�� ���󍇌v
         ,in_aug_quant      => gr_add_total(4).aug_quant      -- �W�� ����
         ,in_aug_amount     => gr_add_total(4).aug_amount     -- �W�� ���z
         ,in_aug_price      => gr_add_total(4).aug_price      -- �W�� �i�ڒ艿
         ,in_aug_to_amount  => gr_add_total(4).aug_to_amount  -- �W�� ���󍇌v
         ,in_sep_quant      => gr_add_total(4).sep_quant      -- �X�� ����
         ,in_sep_amount     => gr_add_total(4).sep_amount     -- �X�� ���z
         ,in_sep_price      => gr_add_total(4).sep_price      -- �X�� �i�ڒ艿
         ,in_sep_to_amount  => gr_add_total(4).sep_to_amount  -- �X�� ���󍇌v
         ,in_oct_quant      => gr_add_total(4).oct_quant      -- �P�O�� ����
         ,in_oct_amount     => gr_add_total(4).oct_amount     -- �P�O�� ���z
         ,in_oct_price      => gr_add_total(4).oct_price      -- �P�O�� �i�ڒ艿
         ,in_oct_to_amount  => gr_add_total(4).oct_to_amount  -- �P�O�� ���󍇌v
         ,in_nov_quant      => gr_add_total(4).nov_quant      -- �P�P�� ����
         ,in_nov_amount     => gr_add_total(4).nov_amount     -- �P�P�� ���z
         ,in_nov_price      => gr_add_total(4).nov_price      -- �P�P�� �i�ڒ艿
         ,in_nov_to_amount  => gr_add_total(4).nov_to_amount  -- �P�P�� ���󍇌v
         ,in_dec_quant      => gr_add_total(4).dec_quant      -- �P�Q�� ����
         ,in_dec_amount     => gr_add_total(4).dec_amount     -- �P�Q�� ���z
         ,in_dec_price      => gr_add_total(4).dec_price      -- �P�Q�� �i�ڒ艿
         ,in_dec_to_amount  => gr_add_total(4).dec_to_amount  -- �P�Q�� ���󍇌v
         ,in_jan_quant      => gr_add_total(4).jan_quant      -- �P�� ����
         ,in_jan_amount     => gr_add_total(4).jan_amount     -- �P�� ���z
         ,in_jan_price      => gr_add_total(4).jan_price      -- �P�� �i�ڒ艿
         ,in_jan_to_amount  => gr_add_total(4).jan_to_amount  -- �P�� ���󍇌v
         ,in_feb_quant      => gr_add_total(4).feb_quant      -- �Q�� ����
         ,in_feb_amount     => gr_add_total(4).feb_amount     -- �Q�� ���z
         ,in_feb_price      => gr_add_total(4).feb_price      -- �Q�� �i�ڒ艿
         ,in_feb_to_amount  => gr_add_total(4).feb_to_amount  -- �Q�� ���󍇌v
         ,in_mar_quant      => gr_add_total(4).mar_quant      -- �R�� ����
         ,in_mar_amount     => gr_add_total(4).mar_amount     -- �R�� ���z
         ,in_mar_price      => gr_add_total(4).mar_price      -- �R�� �i�ڒ艿
         ,in_mar_to_amount  => gr_add_total(4).mar_to_amount  -- �R�� ���󍇌v
         ,in_apr_quant      => gr_add_total(4).apr_quant      -- �S�� ����
         ,in_apr_amount     => gr_add_total(4).apr_amount     -- �S�� ���z
         ,in_apr_price      => gr_add_total(4).apr_price      -- �S�� �i�ڒ艿
         ,in_apr_to_amount  => gr_add_total(4).apr_to_amount  -- �S�� ���󍇌v
         ,in_year_quant     => gr_add_total(4).year_quant     -- �N�v ����
         ,in_year_amount    => gr_add_total(4).year_amount    -- �N�v ���z
         ,in_year_price     => gr_add_total(4).year_price     -- �N�v �i�ڒ艿
         ,in_year_to_amount => gr_add_total(4).year_to_amount -- �N�v ���󍇌v
         ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      --------------------------------------------------------
      -- �����v�f�[�^�^�O�o�� 
      --------------------------------------------------------
      prc_create_xml_data_s_k_t
        (
          iv_label_name     => gv_name_ttl                    -- �����v�p�^�O��
         ,in_may_quant      => gr_add_total(5).may_quant      -- �T�� ����
         ,in_may_amount     => gr_add_total(5).may_amount     -- �T�� ���z
         ,in_may_price      => gr_add_total(5).may_price      -- �T�� �i�ڒ艿
         ,in_may_to_amount  => gr_add_total(5).may_to_amount  -- �T�� ���󍇌v
         ,in_jun_quant      => gr_add_total(5).jun_quant      -- �U�� ����
         ,in_jun_amount     => gr_add_total(5).jun_amount     -- �U�� ���z
         ,in_jun_price      => gr_add_total(5).jun_price      -- �U�� �i�ڒ艿
         ,in_jun_to_amount  => gr_add_total(5).jun_to_amount  -- �U�� ���󍇌v
         ,in_jul_quant      => gr_add_total(5).jul_quant      -- �V�� ����
         ,in_jul_amount     => gr_add_total(5).jul_amount     -- �V�� ���z
         ,in_jul_price      => gr_add_total(5).jul_price      -- �V�� �i�ڒ艿
         ,in_jul_to_amount  => gr_add_total(5).jul_to_amount  -- �V�� ���󍇌v
         ,in_aug_quant      => gr_add_total(5).aug_quant      -- �W�� ����
         ,in_aug_amount     => gr_add_total(5).aug_amount     -- �W�� ���z
         ,in_aug_price      => gr_add_total(5).aug_price      -- �W�� �i�ڒ艿
         ,in_aug_to_amount  => gr_add_total(5).aug_to_amount  -- �W�� ���󍇌v
         ,in_sep_quant      => gr_add_total(5).sep_quant      -- �X�� ����
         ,in_sep_amount     => gr_add_total(5).sep_amount     -- �X�� ���z
         ,in_sep_price      => gr_add_total(5).sep_price      -- �X�� �i�ڒ艿
         ,in_sep_to_amount  => gr_add_total(5).sep_to_amount  -- �X�� ���󍇌v
         ,in_oct_quant      => gr_add_total(5).oct_quant      -- �P�O�� ����
         ,in_oct_amount     => gr_add_total(5).oct_amount     -- �P�O�� ���z
         ,in_oct_price      => gr_add_total(5).oct_price      -- �P�O�� �i�ڒ艿
         ,in_oct_to_amount  => gr_add_total(5).oct_to_amount  -- �P�O�� ���󍇌v
         ,in_nov_quant      => gr_add_total(5).nov_quant      -- �P�P�� ����
         ,in_nov_amount     => gr_add_total(5).nov_amount     -- �P�P�� ���z
         ,in_nov_price      => gr_add_total(5).nov_price      -- �P�P�� �i�ڒ艿
         ,in_nov_to_amount  => gr_add_total(5).nov_to_amount  -- �P�P�� ���󍇌v
         ,in_dec_quant      => gr_add_total(5).dec_quant      -- �P�Q�� ����
         ,in_dec_amount     => gr_add_total(5).dec_amount     -- �P�Q�� ���z
         ,in_dec_price      => gr_add_total(5).dec_price      -- �P�Q�� �i�ڒ艿
         ,in_dec_to_amount  => gr_add_total(5).dec_to_amount  -- �P�Q�� ���󍇌v
         ,in_jan_quant      => gr_add_total(5).jan_quant      -- �P�� ����
         ,in_jan_amount     => gr_add_total(5).jan_amount     -- �P�� ���z
         ,in_jan_price      => gr_add_total(5).jan_price      -- �P�� �i�ڒ艿
         ,in_jan_to_amount  => gr_add_total(5).jan_to_amount  -- �P�� ���󍇌v
         ,in_feb_quant      => gr_add_total(5).feb_quant      -- �Q�� ����
         ,in_feb_amount     => gr_add_total(5).feb_amount     -- �Q�� ���z
         ,in_feb_price      => gr_add_total(5).feb_price      -- �Q�� �i�ڒ艿
         ,in_feb_to_amount  => gr_add_total(5).feb_to_amount  -- �Q�� ���󍇌v
         ,in_mar_quant      => gr_add_total(5).mar_quant      -- �R�� ����
         ,in_mar_amount     => gr_add_total(5).mar_amount     -- �R�� ���z
         ,in_mar_price      => gr_add_total(5).mar_price      -- �R�� �i�ڒ艿
         ,in_mar_to_amount  => gr_add_total(5).mar_to_amount  -- �R�� ���󍇌v
         ,in_apr_quant      => gr_add_total(5).apr_quant      -- �S�� ����
         ,in_apr_amount     => gr_add_total(5).apr_amount     -- �S�� ���z
         ,in_apr_price      => gr_add_total(5).apr_price      -- �S�� �i�ڒ艿
         ,in_apr_to_amount  => gr_add_total(5).apr_to_amount  -- �S�� ���󍇌v
         ,in_year_quant     => gr_add_total(5).year_quant     -- �N�v ����
         ,in_year_amount    => gr_add_total(5).year_amount    -- �N�v ���z
         ,in_year_price     => gr_add_total(5).year_price     -- �N�v �i�ڒ艿
         ,in_year_to_amount => gr_add_total(5).year_to_amount -- �N�v ���󍇌v
         ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
*/
--
      -------------------------------------------------------------
      -- (���_����)(3)���_�v/(4)���i�敪�v/(5)�����v�f�[�^�^�O�o�� 
      -------------------------------------------------------------
      <<kyoten_skbn_total_loop>>
      FOR n IN 3..5 LOOP        -- ���_�v/���i�敪�v/�����v
--
        -- ���_�v�̏ꍇ
        IF ( n = 3 ) THEN
          lv_param_label := gv_name_ktn;
--
        -- ���i�敪�v�̏ꍇ
        ELSIF ( n = 4 ) THEn
          lv_param_label := gv_name_skbn;
--
        -- �����v
        ELSE
          lv_param_label := gv_name_ttl;
--
        END IF;
--
        prc_create_xml_data_s_k_t
        (
          iv_label_name       => lv_param_label                   -- ���i�敪�v�p�^�O��
          ,in_may_quant       => gr_add_total(n).may_quant      -- �T�� ����
          ,in_may_amount      => gr_add_total(n).may_amount     -- �T�� ���z
          ,in_may_price       => gr_add_total(n).may_price      -- �T�� �i�ڒ艿
          ,in_may_to_amount   => gr_add_total(n).may_to_amount  -- �T�� ���󍇌v
          ,in_may_quant_t     => gr_add_total(n).may_quant_t    -- �T�� ����(�v�Z�p)
          ,in_may_s_cost      => gr_add_total(n).may_s_cost     -- �T�� �W������(�v�Z�p)
          ,in_may_calc        => gr_add_total(n).may_calc       -- �T�� �i�ڒ艿*����(�v�Z�p)
          ,in_may_minus_flg   => gr_add_total(n).may_minus_flg   -- �T�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_may_ht_zero_flg => gr_add_total(n).may_ht_zero_flg -- �T�� �i�ڒ艿*����(�v)
          ,in_jun_quant       => gr_add_total(n).jun_quant      -- �U�� ����
          ,in_jun_amount      => gr_add_total(n).jun_amount     -- �U�� ���z
          ,in_jun_price       => gr_add_total(n).jun_price      -- �U�� �i�ڒ艿
          ,in_jun_to_amount   => gr_add_total(n).jun_to_amount  -- �U�� ���󍇌v
          ,in_jun_quant_t     => gr_add_total(n).jun_quant_t    -- �U�� ����(�v�Z�p)
          ,in_jun_s_cost      => gr_add_total(n).jun_s_cost     -- �U�� �W������(�v�Z�p)
          ,in_jun_calc        => gr_add_total(n).jun_calc       -- �U�� �i�ڒ艿*����(�v�Z�p)
          ,in_jun_minus_flg   => gr_add_total(n).jun_minus_flg   -- �U�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_jun_ht_zero_flg => gr_add_total(n).jun_ht_zero_flg -- �U�� �i�ڒ艿*����(�v)
          ,in_jul_quant       => gr_add_total(n).jul_quant      -- �V�� ����
          ,in_jul_amount      => gr_add_total(n).jul_amount     -- �V�� ���z
          ,in_jul_price       => gr_add_total(n).jul_price      -- �V�� �i�ڒ艿
          ,in_jul_to_amount   => gr_add_total(n).jul_to_amount  -- �V�� ���󍇌v
          ,in_jul_quant_t     => gr_add_total(n).jul_quant_t    -- �V�� ����(�v�Z�p)
          ,in_jul_s_cost      => gr_add_total(n).jul_s_cost     -- �V�� �W������(�v�Z�p)
          ,in_jul_calc        => gr_add_total(n).jul_calc       -- �V�� �i�ڒ艿*����(�v�Z�p)
          ,in_jul_minus_flg   => gr_add_total(n).jul_minus_flg   -- �V�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_jul_ht_zero_flg => gr_add_total(n).jul_ht_zero_flg -- �V�� �i�ڒ艿*����(�v)
          ,in_aug_quant       => gr_add_total(n).aug_quant      -- �W�� ����
          ,in_aug_amount      => gr_add_total(n).aug_amount     -- �W�� ���z
          ,in_aug_price       => gr_add_total(n).aug_price      -- �W�� �i�ڒ艿
          ,in_aug_to_amount   => gr_add_total(n).aug_to_amount  -- �W�� ���󍇌v
          ,in_aug_quant_t     => gr_add_total(n).aug_quant_t    -- �W�� ����(�v�Z�p)
          ,in_aug_s_cost      => gr_add_total(n).aug_s_cost     -- �W�� �W������(�v�Z�p)
          ,in_aug_calc        => gr_add_total(n).aug_calc       -- �W�� �i�ڒ艿*����(�v�Z�p)
          ,in_aug_minus_flg   => gr_add_total(n).aug_minus_flg   -- �W�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_aug_ht_zero_flg => gr_add_total(n).aug_ht_zero_flg -- �W�� �i�ڒ艿*����(�v)
          ,in_sep_quant       => gr_add_total(n).sep_quant      -- �X�� ����
          ,in_sep_amount      => gr_add_total(n).sep_amount     -- �X�� ���z
          ,in_sep_price       => gr_add_total(n).sep_price      -- �X�� �i�ڒ艿
          ,in_sep_to_amount   => gr_add_total(n).sep_to_amount  -- �X�� ���󍇌v
          ,in_sep_quant_t     => gr_add_total(n).sep_quant_t    -- �X�� ����(�v�Z�p)
          ,in_sep_s_cost      => gr_add_total(n).sep_s_cost     -- �X�� �W������(�v�Z�p)
          ,in_sep_calc        => gr_add_total(n).sep_calc       -- �X�� �i�ڒ艿*����(�v�Z�p)
          ,in_sep_minus_flg   => gr_add_total(n).sep_minus_flg   -- �X�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_sep_ht_zero_flg => gr_add_total(n).sep_ht_zero_flg -- �X�� �i�ڒ艿*����(�v)
          ,in_oct_quant       => gr_add_total(n).oct_quant      -- �P�O�� ����
          ,in_oct_amount      => gr_add_total(n).oct_amount     -- �P�O�� ���z
          ,in_oct_price       => gr_add_total(n).oct_price      -- �P�O�� �i�ڒ艿
          ,in_oct_to_amount   => gr_add_total(n).oct_to_amount  -- �P�O�� ���󍇌v
          ,in_oct_quant_t     => gr_add_total(n).oct_quant_t    -- �P�O�� ����(�v�Z�p)
          ,in_oct_s_cost      => gr_add_total(n).oct_s_cost     -- �P�O�� �W������(�v�Z�p)
          ,in_oct_calc        => gr_add_total(n).oct_calc       -- �P�O�� �i�ڒ艿*����(�v�Z�p)
          ,in_oct_minus_flg   => gr_add_total(n).oct_minus_flg   -- �P�O�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_oct_ht_zero_flg => gr_add_total(n).oct_ht_zero_flg -- �P�O�� �i�ڒ艿*����(�v)
          ,in_nov_quant       => gr_add_total(n).nov_quant      -- �P�P�� ����
          ,in_nov_amount      => gr_add_total(n).nov_amount     -- �P�P�� ���z
          ,in_nov_price       => gr_add_total(n).nov_price      -- �P�P�� �i�ڒ艿
          ,in_nov_to_amount   => gr_add_total(n).nov_to_amount  -- �P�P�� ���󍇌v
          ,in_nov_quant_t     => gr_add_total(n).nov_quant_t    -- �P�P�� ����(�v�Z�p)
          ,in_nov_s_cost      => gr_add_total(n).nov_s_cost     -- �P�P�� �W������(�v�Z�p)
          ,in_nov_calc        => gr_add_total(n).nov_calc       -- �P�P�� �i�ڒ艿*����(�v�Z�p)
          ,in_nov_minus_flg   => gr_add_total(n).nov_minus_flg   -- �P�P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_nov_ht_zero_flg => gr_add_total(n).nov_ht_zero_flg -- �P�P�� �i�ڒ艿*����(�v)
          ,in_dec_quant       => gr_add_total(n).dec_quant      -- �P�Q�� ����
          ,in_dec_amount      => gr_add_total(n).dec_amount     -- �P�Q�� ���z
          ,in_dec_price       => gr_add_total(n).dec_price      -- �P�Q�� �i�ڒ艿
          ,in_dec_to_amount   => gr_add_total(n).dec_to_amount  -- �P�Q�� ���󍇌v
          ,in_dec_quant_t     => gr_add_total(n).dec_quant_t    -- �P�Q�� ����(�v�Z�p)
          ,in_dec_s_cost      => gr_add_total(n).dec_s_cost     -- �P�Q�� �W������(�v�Z�p)
          ,in_dec_calc        => gr_add_total(n).dec_calc       -- �P�Q�� �i�ڒ艿*����(�v�Z�p)
          ,in_dec_minus_flg   => gr_add_total(n).dec_minus_flg   -- �P�Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_dec_ht_zero_flg => gr_add_total(n).dec_ht_zero_flg -- �P�Q�� �i�ڒ艿*����(�v)
          ,in_jan_quant       => gr_add_total(n).jan_quant      -- �P�� ����
          ,in_jan_amount      => gr_add_total(n).jan_amount     -- �P�� ���z
          ,in_jan_price       => gr_add_total(n).jan_price      -- �P�� �i�ڒ艿
          ,in_jan_to_amount   => gr_add_total(n).jan_to_amount  -- �P�� ���󍇌v
          ,in_jan_quant_t     => gr_add_total(n).jan_quant_t    -- �P�� ����(�v�Z�p)
          ,in_jan_s_cost      => gr_add_total(n).jan_s_cost     -- �P�� �W������(�v�Z�p)
          ,in_jan_calc        => gr_add_total(n).jan_calc       -- �P�� �i�ڒ艿*����(�v�Z�p)
          ,in_jan_minus_flg   => gr_add_total(n).jan_minus_flg   -- �P�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_jan_ht_zero_flg => gr_add_total(n).jan_ht_zero_flg -- �P�� �i�ڒ艿*����(�v)
          ,in_feb_quant       => gr_add_total(n).feb_quant      -- �Q�� ����
          ,in_feb_amount      => gr_add_total(n).feb_amount     -- �Q�� ���z
          ,in_feb_price       => gr_add_total(n).feb_price      -- �Q�� �i�ڒ艿
          ,in_feb_to_amount   => gr_add_total(n).feb_to_amount  -- �Q�� ���󍇌v
          ,in_feb_quant_t     => gr_add_total(n).feb_quant_t    -- �Q�� ����(�v�Z�p)
          ,in_feb_s_cost      => gr_add_total(n).feb_s_cost     -- �Q�� �W������(�v�Z�p)
          ,in_feb_calc        => gr_add_total(n).feb_calc       -- �Q�� �i�ڒ艿*����(�v�Z�p)
          ,in_feb_minus_flg   => gr_add_total(n).feb_minus_flg   -- �Q�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_feb_ht_zero_flg => gr_add_total(n).feb_ht_zero_flg -- �Q�� �i�ڒ艿*����(�v)
          ,in_mar_quant       => gr_add_total(n).mar_quant      -- �R�� ����
          ,in_mar_amount      => gr_add_total(n).mar_amount     -- �R�� ���z
          ,in_mar_price       => gr_add_total(n).mar_price      -- �R�� �i�ڒ艿
          ,in_mar_to_amount   => gr_add_total(n).mar_to_amount  -- �R�� ���󍇌v
          ,in_mar_quant_t     => gr_add_total(n).mar_quant_t    -- �R�� ����(�v�Z�p)
          ,in_mar_s_cost      => gr_add_total(n).mar_s_cost     -- �R�� �W������(�v�Z�p)
          ,in_mar_calc        => gr_add_total(n).mar_calc       -- �R�� �i�ڒ艿*����(�v�Z�p)
          ,in_mar_minus_flg   => gr_add_total(n).mar_minus_flg   -- �R�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_mar_ht_zero_flg => gr_add_total(n).mar_ht_zero_flg -- �R�� �i�ڒ艿*����(�v)
          ,in_apr_quant       => gr_add_total(n).apr_quant      -- �S�� ����
          ,in_apr_amount      => gr_add_total(n).apr_amount     -- �S�� ���z
          ,in_apr_price       => gr_add_total(n).apr_price      -- �S�� �i�ڒ艿
          ,in_apr_to_amount   => gr_add_total(n).apr_to_amount  -- �S�� ���󍇌v
          ,in_apr_quant_t     => gr_add_total(n).apr_quant_t    -- �S�� ����(�v�Z�p)
          ,in_apr_s_cost      => gr_add_total(n).apr_s_cost     -- �S�� �W������(�v�Z�p)
          ,in_apr_calc        => gr_add_total(n).apr_calc       -- �S�� �i�ڒ艿*����(�v�Z�p)
          ,in_apr_minus_flg   => gr_add_total(n).apr_minus_flg   -- �S�� ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_apr_ht_zero_flg => gr_add_total(n).apr_ht_zero_flg -- �S�� �i�ڒ艿*����(�v)
          ,in_year_quant      => gr_add_total(n).year_quant     -- �N�v ����
          ,in_year_amount     => gr_add_total(n).year_amount    -- �N�v ���z
          ,in_year_price      => gr_add_total(n).year_price     -- �N�v �i�ڒ艿
          ,in_year_to_amount  => gr_add_total(n).year_to_amount -- �N�v ���󍇌v
          ,in_year_quant_t    => gr_add_total(n).year_quant_t   -- �N�v ����(�v�Z�p)
          ,in_year_s_cost     => gr_add_total(n).year_s_cost    -- �N�v �W������(�v�Z�p)
          ,in_year_calc       => gr_add_total(n).year_calc      -- �N�v �i�ڒ艿*����(�v�Z�p)
          ,in_year_minus_flg   => gr_add_total(n).year_minus_flg   -- �N�v ���ʃ}�C�i�X�l���݃t���O(�v�Z�p)
          ,in_year_ht_zero_flg => gr_add_total(n).year_ht_zero_flg -- �N�v �i�ڒ艿*����(�v)
          ,ov_errbuf         => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode        => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg         => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ���_�v�̏ꍇ
        IF ( n = 3) THEN
          -- -----------------------------------------------------
          --  ���_�I���f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ktn';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- -----------------------------------------------------
          --  ���_�I���k�f�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ktn_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        END IF;
    --
      END LOOP kyoten_skbn_total_loop;
-- 2009/04/16 v1.6 T.Yoshimoto Mod End
--
      -- -----------------------------------------------------
      -- (���_����)���i�敪�I���f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_skbn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (���_����)���i�敪�I���k�f�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_skbn_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (���_����)�f�[�^�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- (���_����)���[�g�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/root';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END IF;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn;
      ov_errmsg  := xxcmn_common_pkg.get_msg(
                                              gv_application
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
    xml_data_table   XML_DATA;
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
    -- �f�[�^�擾 - �J�X�^���I�v�V�����擾  (C-1-0)
    -- =====================================================
    pro_get_cus_option
      (
        ov_errbuf   => lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode  => lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg   => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
        ov_errbuf   => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode  => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg   => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
        ov_errbuf   => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode  => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg   => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
        ov_errbuf   => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode  => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg   => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- XML�^�O�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>');
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF ((lv_errmsg IS NOT NULL)
      AND (lv_retcode = gv_status_warn)) THEN
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
    -- ���o�f�[�^���P���ȏ�̏ꍇ
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
--
--###########################  �Œ蕔 START   ###########################
--
  IS
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
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
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
END xxinv100003c;
/
