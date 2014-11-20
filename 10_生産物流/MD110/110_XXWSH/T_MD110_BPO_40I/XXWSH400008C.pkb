create or replace PACKAGE BODY xxwsh400008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400008c(body)
 * Description      : ���Y�����i�o�ׁj
 * MD.050           : �o�׈˗� T_MD050_BPO_401
 * MD.070           : �o�ג����\ T_MD070_BPO_40I
 * Version          : 1.6
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  fnc_conv_xml                   FUNCTION   : �w�l�k�^�O�ɕϊ�����B
 *  prc_out_xml_data               PROCEDURE  : �w�l�k�o�͏���
 *  prc_create_zeroken_xml_data    PROCEDURE  : �w�l�k�f�[�^�쐬�����i�O���j
 *  prc_create_xml_data            PROCEDURE  : �w�l�k�f�[�^�쐬����
 *  prc_get_chosei_data            PROCEDURE  : �o�ג����\���擾����
 *  prc_plan_confirm_marge_data    PROCEDURE  : �v�搔�E�\�����}�[�W����
 *  prc_get_drink_subtotal_data    PROCEDURE  : �h�����N�݌v���Z�o����
 *  prc_get_drink_confirm_data     PROCEDURE  : �h�����N�\�����擾����
 *  prc_get_drink_plan_data        PROCEDURE  : �h�����N�v�搔�擾����
 *  prc_get_bucket_data            PROCEDURE  : �o�P�b�g���t�擾����
 *  prc_get_drink_info             PROCEDURE  : �h�����N���擾����
 *  prc_get_leaf_zensha_data       PROCEDURE  : ���[�t�S�А��擾����
 *  prc_get_leaf_total_mon_data    PROCEDURE  : ���[�t�݌v���E���Ԑ��Z�o����
 *  prc_get_leaf_confirm_data      PROCEDURE  : ���[�t�\�����擾����
 *  prc_get_leaf_plan_data         PROCEDURE  : ���[�t�v�搔�擾����
 *  prc_get_leaf_info              PROCEDURE  : ���[�t���擾����
 *  prc_get_shipped_locat          PROCEDURE  : �o�Ɍ����擾����
 *  prc_get_profile                PROCEDURE  : ���o�ΏۃX�e�[�^�X�擾����
 *  prc_check_input_data           PROCEDURE  : ���̓p�����[�^�`�F�b�N����
 *  submain                        PROCEDURE  : ���C�������v���V�[�W��
 *  main                           PROCEDURE  : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- --------------------- -------------------------------------------------
 *  Date          Ver.  Editor                Description
 * ------------- ----- --------------------- -------------------------------------------------
 *  2008/04/10    1.0   Masakazu Yamashita    �V�K�쐬
 *  2008/06/19    1.1   Yasuhisa Yamamoto     �V�X�e���e�X�g��Q�Ή�
 *  2008/06/26    1.2   ToshikazuIshiwata     �V�X�e���e�X�g��Q�Ή�(#309)
 *  2008/07/02    1.3   Naoki Fukuda          ST�s��Ή�(#373)
 *  2008/07/02    1.4   Satoshi Yunba         �֑������Ή�
 *  2008/07/23    1.5   Naoki Fukuda          ST�s��Ή�(#475)
 *  2008/08/20    1.6   Takao Ohashi          �ύX#183,T_S_612�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--
  -- �p�b�P�[�W��
  gv_pkg_name                   CONSTANT VARCHAR2(20) := 'XXWSH400008C' ;
  -- ���[ID
  gc_report_id                  CONSTANT VARCHAR2(12) := 'XXWSH400008T' ;
--
  -- �����敪
  gv_syori_kbn_leaf             CONSTANT VARCHAR2(1) := '1';                    -- ���[�t
  gv_syori_kbn_drink            CONSTANT VARCHAR2(1) := '2';                    -- �h�����N
  -- �X�e�[�^�X�i�o�׎��ьv��ρj
  gv_req_status                 CONSTANT VARCHAR2(10) := '04';
  -- �N�C�b�N�R�[�h�i�o�ג������o�ΏۃX�e�[�^�X��ʁj
  gv_lookup_type1               CONSTANT VARCHAR2(100) := 'XXWSH_401J_EXTRACT_STATUS';
  -- �v�揤�i�t���O
  gv_plan_syohin_flg            CONSTANT VARCHAR2(1) := '1';                    -- �v�揤�i�Ώ�
  -- �t�H�[�L���X�g���ށi�v�揤�i����v��j
  gv_forecast_kbn_ksyohin       CONSTANT VARCHAR2(10) := '09';
  -- �t�H�[�L���X�g���ށi����v��j
  gv_forecast_kbn_hkeikaku      CONSTANT VARCHAR2(10) := '01';
  -- ���o�ΏۃX�e�[�^�X�i���_�p�^�[���j
  --gv_select_status_kyoten       CONSTANT VARCHAR2(10) := '1';   --2008/07/02 ST�s��Ή�(#373)
  gv_select_status_kyoten       CONSTANT VARCHAR2(10) := '2';     --2008/07/02 ST�s��Ή�(#373)
--
  -- �G���[���b�Z�[�W�֘A
  gc_application_cmn            CONSTANT VARCHAR2(10) := 'XXCMN' ;
  gv_msg_xxcmn10002             CONSTANT VARCHAR2(50) := 'APP-XXCMN-10002';
  gv_msg_xxcmn10122             CONSTANT VARCHAR2(50) := 'APP-XXCMN-10122';
--
  gc_application_wsh            CONSTANT VARCHAR2(10) := 'XXWSH';
  gv_msg_xxwsh11402             CONSTANT VARCHAR2(50) := 'APP-XXWSH-11402';
  gv_msg_tkn_pram               CONSTANT VARCHAR2(10) := 'PARAMETER';
  gv_msg_contents               CONSTANT VARCHAR2(10) := '����';
  gv_msg_xxwsh11403             CONSTANT VARCHAR2(50) := 'APP-XXWSH-11403';
--
  -- �g�[�N���F�v���t�@�C����
  gv_tkn_profile                CONSTANT VARCHAR2(10) := 'NG_PROFILE';
  -- �v���t�@�C��ID
  gv_profile_id                 CONSTANT VARCHAR2(50) := 'XXWSH_EXTRACT_PATTERN_401J';
  -- �v���t�@�C������
  gv_profile_name               CONSTANT VARCHAR2(50) := 'XXWSH:�o�ג����\���o�p�^�[��';
--
  -- ���t�t�H�[�}�b�g
  gv_date_format1               CONSTANT VARCHAR2(18) := 'YYYY/MM/DD HH24:MI';  -- �N��������
  gv_date_format2               CONSTANT VARCHAR2(18) := 'YYYY/MM/DD';          -- �N����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ���[�t�v�搔�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE type_leaf_plan_data_rec IS RECORD (
        -- ���_�R�[�h
        head_sales_branch           mrp_forecast_designators.attribute3%TYPE
        -- �i�ڃR�[�h
       ,item_code                   xxcmn_item_mst_v.item_no%TYPE
        -- �i�ږ�
       ,item_name                   xxcmn_item_mst_v.item_short_name%TYPE
        -- ����
       ,arrival_date                mrp_forecast_dates.forecast_date%TYPE
       -- �v�搔
       ,plan_quantity               NUMBER
    ) ;
  TYPE type_leaf_plan_data_tbl IS TABLE OF type_leaf_plan_data_rec INDEX BY PLS_INTEGER ;
--
  -- ���[�t�\�����f�[�^�i�[�p���R�[�h�ϐ�
  TYPE type_leaf_confirm_data_rec IS RECORD (
        -- ���_�R�[�h
        head_sales_branch           xxwsh_order_headers_all.head_sales_branch%TYPE
        -- �i�ڃR�[�h
       ,item_code                   xxwsh_order_lines_all.request_item_code%TYPE
        -- �i�ږ�
       ,item_name                   xxcmn_item_mst_v.item_short_name%TYPE
        -- ����
       ,arrival_date                xxwsh_order_headers_all.schedule_arrival_date%TYPE
        -- �v�搔
       ,confirm_quantity            NUMBER
    ) ;
  TYPE type_leaf_confirm_data_tbl IS TABLE OF type_leaf_confirm_data_rec INDEX BY PLS_INTEGER ;
--
  -- ���[�t�݌v���E���Ԑ��i�[�p���R�[�h�ϐ�
  TYPE type_leaf_total_mon_rec IS RECORD 
    (
        -- ���_�R�[�h
        head_sales_branch           xxwsh_ship_adjust_days_tmp.head_sales_branch%TYPE
        -- �i�ڃR�[�h
       ,item_code                   xxwsh_ship_adjust_days_tmp.item_code%TYPE
        -- �i�ږ�
       ,item_name                   xxwsh_ship_adjust_days_tmp.item_name%TYPE
       -- ����
       ,arrival_date                xxwsh_ship_adjust_days_tmp.arrival_date%TYPE
        -- �v�搔�i�����j
       ,plan_quantity               xxwsh_ship_adjust_days_tmp.plan_quantity%TYPE
        -- �\�����i�����j
       ,confirm_quantity            xxwsh_ship_adjust_days_tmp.confirm_quantity%TYPE
        -- �v�搔�i�݌v�j
       ,plan_subtotal_quantity      xxwsh_ship_adjust_days_tmp.plan_quantity%TYPE
        -- �\�����i�݌v�j
       ,confirm_subtotal_quantity   xxwsh_ship_adjust_days_tmp.confirm_quantity%TYPE
        -- �v�搔�i���ԁj
       ,plan_monthly_quantity       xxwsh_ship_adjust_days_tmp.plan_quantity%TYPE
        -- �\�����i���ԁj
       ,confirm_monthly_quantity    xxwsh_ship_adjust_days_tmp.confirm_quantity%TYPE
    ) ;
  TYPE type_leaf_total_mon_tbl IS TABLE OF type_leaf_total_mon_rec INDEX BY BINARY_INTEGER ;
--
  -- ���[�t�S�А��i�[�p���R�[�h�ϐ�
  TYPE type_leaf_zensha_data_rec IS RECORD 
    (
        -- �i�ڃR�[�h
        item_code                   xxwsh_ship_adjust_all_tmp.item_code%TYPE
        -- �v�搔
       ,plan_quantity               xxwsh_ship_adjust_all_tmp.plan_quantity%TYPE
        -- �\����
       ,confirm_quantity            xxwsh_ship_adjust_all_tmp.confirm_quantity%TYPE
    ) ;
  TYPE type_leaf_zensha_data_tbl IS TABLE OF type_leaf_zensha_data_rec INDEX BY BINARY_INTEGER ;
--
  -- �h�����N�v�搔�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE type_drink_plan_data_rec IS RECORD (
        -- ���_�R�[�h
        head_sales_branch           xxcmn_sourcing_rules.base_code%TYPE
        -- �i�ڃR�[�h
       ,item_code                   xxcmn_sourcing_rules.item_code%TYPE
        -- �i�ږ�
       ,item_name                   xxcmn_item_mst_v.item_short_name%TYPE
        -- ����
       ,arrival_date                mrp_forecast_dates.forecast_date%TYPE
        -- �v�搔
       ,plan_quantity               NUMBER
    ) ;
  TYPE type_drink_plan_data_tbl IS TABLE OF type_drink_plan_data_rec INDEX BY PLS_INTEGER ;
--
  -- �h�����N�\�����f�[�^�i�[�p���R�[�h�ϐ�
  TYPE type_drink_confirm_data_rec IS RECORD (
        -- ���_�R�[�h
        head_sales_branch           xxwsh_order_headers_all.head_sales_branch%TYPE
        -- �i�ڃR�[�h
       ,item_code                   xxwsh_order_lines_all.request_item_code%TYPE
        -- �i�ږ�
       ,item_name                   xxcmn_item_mst_v.item_short_name%TYPE
        -- ����
       ,arrival_date                xxwsh_order_headers_all.schedule_arrival_date%TYPE
        -- �\����
       ,confirm_quantity            NUMBER
    ) ;
  TYPE type_drink_confirm_data_tbl IS TABLE OF type_drink_confirm_data_rec INDEX BY PLS_INTEGER ;
--
  -- �h�����N�݌v���i�[�p���R�[�h�ϐ�
  TYPE type_drink_total_mon_rec IS RECORD 
    (
        -- ���_�R�[�h
        head_sales_branch           xxwsh_ship_adjust_days_tmp.head_sales_branch%TYPE
        -- �i�ڃR�[�h
       ,item_code                   xxwsh_ship_adjust_days_tmp.item_code%TYPE
        -- �i�ږ�
       ,item_name                   xxwsh_ship_adjust_days_tmp.item_name%TYPE
        -- ����
       ,arrival_date                xxwsh_ship_adjust_days_tmp.arrival_date%TYPE
        -- �v�搔�i�����j
       ,plan_quantity               xxwsh_ship_adjust_days_tmp.plan_quantity%TYPE
        -- �\�����i�����j
       ,confirm_quantity            xxwsh_ship_adjust_days_tmp.confirm_quantity%TYPE
        -- �v�搔�i�݌v�j
       ,plan_subtotal_quantity      xxwsh_ship_adjust_days_tmp.plan_quantity%TYPE
        -- �\�����i�݌v�j
       ,confirm_subtotal_quantity   xxwsh_ship_adjust_days_tmp.confirm_quantity%TYPE
        -- �v�搔�i���ԁj
       ,plan_monthly_quantity       NUMBER
        -- �\�����i���ԁj
       ,confirm_monthly_quantity    NUMBER
    ) ;
  TYPE type_drink_total_mon_tbl IS TABLE OF type_drink_total_mon_rec INDEX BY BINARY_INTEGER ;
--
  -- �o�ג����\�f�[�^���R�[�h�ϐ�
  TYPE type_chosei_data_rec IS RECORD 
    (
        -- ���_�R�[�h
        head_sales_branch           xxwsh_ship_adjust_total_tmp.head_sales_branch%TYPE
        -- ���_��
       ,kyoten_nm                   xxcmn_cust_accounts2_v.party_short_name%TYPE
        -- �i�ڃR�[�h
       ,item_code                   xxwsh_ship_adjust_total_tmp.item_code%TYPE
        -- �i�ږ�
       ,item_name                   xxwsh_ship_adjust_total_tmp.item_name%TYPE
        -- ����
       ,arrival_date                xxwsh_ship_adjust_total_tmp.arrival_date%TYPE
        -- �v�搔�i�����j
       ,plan_quantity               xxwsh_ship_adjust_total_tmp.plan_quantity%TYPE
        -- �\�����i�����j
       ,confirm_quantity            xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
        -- �v�搔�i�݌v�j
       ,plan_subtotal_quantity      xxwsh_ship_adjust_total_tmp.plan_subtotal_quantity%TYPE
        -- �\�����i�݌v�j
       ,confirm_subtotal_quantity   xxwsh_ship_adjust_total_tmp.confirm_subtotal_quantity%TYPE
        -- �v�搔�i���ԁj
       ,monthly_plan_quantity       xxwsh_ship_adjust_total_tmp.monthly_plan_quantity%TYPE
        -- �\�����i���ԁj
       ,monthly_confirm_quantity    xxwsh_ship_adjust_total_tmp.monthly_confirm_quantity%TYPE
        -- �v�搔�i�S�Ёj
       ,zensha_plan_quantity        xxwsh_ship_adjust_all_tmp.plan_quantity%TYPE
        -- �\�����i�S�Ёj
       ,zensha_confirm_quantity     xxwsh_ship_adjust_all_tmp.confirm_quantity%TYPE
    ) ;
  TYPE type_chosei_data_tbl IS TABLE OF type_chosei_data_rec INDEX BY BINARY_INTEGER ;
--
  -- �o�ג����\���ʒ��ԃe�[�u�����(FORALL�ł�INSERT�p)
  TYPE day_head_sales_branch                                             -- ���_�R�[�h
    IS TABLE OF xxwsh_ship_adjust_days_tmp.head_sales_branch%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE day_item_code                                                     -- �i�ڃR�[�h
    IS TABLE OF xxwsh_ship_adjust_days_tmp.item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE day_item_name                                                     -- �i�ږ�
    IS TABLE OF xxwsh_ship_adjust_days_tmp.item_name%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE day_arrival_date                                                  -- ����
    IS TABLE OF xxwsh_ship_adjust_days_tmp.arrival_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE day_plan_quantity                                                 -- �v�搔
    IS TABLE OF xxwsh_ship_adjust_days_tmp.plan_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE day_confirm_quantity                                              -- �\����
    IS TABLE OF xxwsh_ship_adjust_days_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  -- �o�ג����\�S�В��ԃe�[�u�����(FORALL�ł�INSERT�p)
  TYPE all_item_code                                                     -- �i�ڃR�[�h
    IS TABLE OF xxwsh_ship_adjust_all_tmp.item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE all_plan_quantity                                                 -- �v�搔
    IS TABLE OF xxwsh_ship_adjust_all_tmp.plan_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE all_confirm_quantity                                              -- �\����
    IS TABLE OF xxwsh_ship_adjust_all_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  -- �o�ג����\�\�����ԃe�[�u��
  TYPE plan_head_sales_branch                                            -- ���_�R�[�h
    IS TABLE OF xxwsh_shippng_adj_plan_act_tmp.head_sales_branch%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE plan_item_code                                                    -- �i�ڃR�[�h
    IS TABLE OF xxwsh_shippng_adj_plan_act_tmp.item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE plan_item_name                                                    -- �i�ږ�
    IS TABLE OF xxwsh_shippng_adj_plan_act_tmp.item_name%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE plan_arrival_date                                                 -- ����
    IS TABLE OF xxwsh_shippng_adj_plan_act_tmp.arrival_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE plan_confirm_quantity                                             -- �\����
    IS TABLE OF xxwsh_shippng_adj_plan_act_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  -- �o�ג����\�W�v���ԃe�[�u��
  TYPE i_head_sales_branch                                               -- ���_�R�[�h
    IS TABLE OF xxwsh_ship_adjust_total_tmp.head_sales_branch%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_code                                                       -- �i�ڃR�[�h
    IS TABLE OF xxwsh_ship_adjust_total_tmp.item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_name                                                       -- �i�ږ�
    IS TABLE OF xxwsh_ship_adjust_total_tmp.item_name%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_arrival_date                                                    -- ����
    IS TABLE OF xxwsh_ship_adjust_total_tmp.arrival_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_plan_quantity                                                   -- �v�搔�i�����j
    IS TABLE OF xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_confirm_quantity                                                -- �\�����i�����j
    IS TABLE OF xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_plan_subtotal_quantity                                          -- �v�搔�i�݌v�j
    IS TABLE OF xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_confirm_subtotal_quantity                                       -- �\�����i�݌v�j
    IS TABLE OF xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_plan_monthly_quantity                                           -- �v�搔�i���ԁj
    IS TABLE OF xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_confirm_monthly_quantity                                        -- �\�����i���ԁj
    IS TABLE OF xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- �o�ג����\�o�P�b�g���ԃe�[�u��
  TYPE i_bucket_date
    IS TABLE OF xxwsh_shippng_adj_bucket_tmp.bucket_date%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- �o�ג����\���ʒ��ԃe�[�u��(FORALL�ł�INSERT�p)
  gt_day_head_sales_branch              day_head_sales_branch;           -- ���_�R�[�h
  gt_day_item_code                      day_item_code;                   -- �i�ڃR�[�h
  gt_day_item_name                      day_item_name;                   -- �i�ږ�
  gt_day_arrival_date                   day_arrival_date;                -- ����
  gt_day_plan_quantity                  day_plan_quantity;               -- �v�搔�i�����j
  gt_day_confirm_quantity               day_confirm_quantity;            -- �\�����i�����j
  -- �o�ג����\�S�В��ԃe�[�u��(FORALL�ł�INSERT�p)
  gt_all_item_code                      all_item_code;                   -- �i�ڃR�[�h
  gt_all_plan_quantity                  all_plan_quantity;               -- �v�搔
  gt_all_confirm_quantity               all_confirm_quantity;            -- �\����
  -- �o�ג����\�\�����ԃe�[�u��(FORALL�ł�INSERT�p)
  gt_plan_head_sales_branch             plan_head_sales_branch;          -- ���_�R�[�h
  gt_plan_item_code                     plan_item_code;                  -- �i�ڃR�[�h
  gt_plan_item_name                     plan_item_name;                  -- �i�ږ�
  gt_plan_arrival_date                  plan_arrival_date;                  -- ����
  gt_plan_confirm_quantity              plan_confirm_quantity;           -- �\�����i�����j
  -- �o�ג����\�W�v���ԃe�[�u��(FORALL�ł�INSERT�p)
  gt_i_head_sales_branch            i_head_sales_branch;                 -- ���_�R�[�h
  gt_i_item_code                    i_item_code;                         -- �i�ڃR�[�h
  gt_i_item_name                    i_item_name;                         -- �i�ږ�
  gt_i_arrival_date                 i_arrival_date;                      -- ����
  gt_i_plan_quantity                i_plan_quantity;                     -- �v�搔�i�����j
  gt_i_confirm_quantity             i_confirm_quantity;                  -- �\�����i�����j
  gt_i_plan_subtotal_quantity       i_plan_subtotal_quantity;            -- �v�搔�i�݌v�j
  gt_i_confirm_subtotal_quantity    i_confirm_subtotal_quantity;         -- �\�����i�݌v�j
  gt_i_plan_monthly_quantity        i_plan_monthly_quantity;             -- �v�搔�i���ԁj
  gt_i_confirm_monthly_quantity     i_confirm_monthly_quantity;          -- �\�����i���ԁj
  -- �o�ג����\�o�P�b�g���ԃe�[�u��(FORALL�ł�INSERT�p)
  gt_i_bucket_data                      i_bucket_date;                   -- �o�P�b�g���t
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_syukkomoto_cd         xxcmn_item_locations_v.segment1%TYPE;
  gv_syukkomoto_nm         xxcmn_item_locations_v.description%TYPE;
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER ;                  -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml
    (
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_out_xml_data
   * Description      : �w�l�k�o�͏���
   ***********************************************************************************/
  PROCEDURE prc_out_xml_data
    (
      ov_errbuf     OUT NOCOPY VARCHAR2             --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT NOCOPY VARCHAR2             --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT NOCOPY VARCHAR2             --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_out_xml_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    lv_xml_string           VARCHAR2(32000) ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==================================================
    -- �w�l�k�o�͏���
    -- ==================================================
    -- �J�n�^�O�o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_chosei_info>' ) ;
--
    <<xml_data_table>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      -- �ҏW�����f�[�^���^�O�ɕϊ�
      lv_xml_string := fnc_conv_xml
                        (
                          iv_name   => gt_xml_data_table(i).tag_name    -- �^�O�l�[��
                         ,iv_value  => gt_xml_data_table(i).tag_value   -- �^�O�f�[�^
                         ,ic_type   => gt_xml_data_table(i).tag_type    -- �^�O�^�C�v
                        ) ;
      -- �w�l�k�^�O�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_data_table ;
--
    -- �I���^�O�o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_chosei_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
  EXCEPTION
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
  END prc_out_xml_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_zeroken_xml_data
   * Description      : �擾�����O�����w�l�k�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_zeroken_xml_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_zeroken_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- ���[�^�C�g��
    lv_chohyo_title           VARCHAR2(10) DEFAULT NULL;
--
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- �����f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_chosei' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- ���b�Z�[�W�o�̓^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'msg';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_msg( gc_application_cmn
                                                                        ,gv_msg_xxcmn10122 ) ;
--
    -- -----------------------------------------------------
    -- ����LG�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- ����G�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- ����G�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- ����LG�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- �����f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_chosei' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--
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
  END prc_create_zeroken_xml_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬����
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      iv_syori_kbn      IN  VARCHAR2                 -- �����敪
     ,it_chosei_data    IN  type_chosei_data_tbl     -- �o�ג����\���
     ,ov_errbuf         OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- ���_�R�[�h�u���C�N�p�ϐ�
    lv_head_sales_branch_break      VARCHAR2(10) DEFAULT '*';
    -- ���񃌃R�[�h
    ln_break_init                   NUMBER DEFAULT 1;
    -- ���_�v�v�搔�i�����j�T�}���p�ϐ�
    ln_plan_arrive_total            NUMBER DEFAULT 0;
    -- ���_�v�\�����i�����j�T�}���p�ϐ�
    ln_confirm_arrive_total         NUMBER DEFAULT 0;
    -- ���_�v�v�搔�i�݌v�j�T�}���p�ϐ�
    ln_plan_subtotal_total          NUMBER DEFAULT 0;
    -- ���_�v�\�����i�݌v�j�T�}���p�ϐ�
    ln_confirm_subtotal_total       NUMBER DEFAULT 0;
    -- ���_�v�v�搔�i���ԁj�T�}���p�ϐ�
    ln_plan_monthly_total           NUMBER DEFAULT 0;
    -- ���_�v�\�����i���ԁj�T�}���p�ϐ�
    ln_confirm_monthly_total        NUMBER DEFAULT 0;
    -- ���s���t
    ld_now_date                     DATE DEFAULT SYSDATE;
--
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- �o�ג����\���[�v
    -- -----------------------------------------------------
    <<chosei_data_loop>>
    FOR l_cnt IN 1..it_chosei_data.COUNT + 1 LOOP
--
      -- �I���^�O�o�͔���
      -- �u���C�N����
      IF (   l_cnt > it_chosei_data.COUNT
          OR lv_head_sales_branch_break <> it_chosei_data(l_cnt).head_sales_branch) THEN
--
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( l_cnt <> ln_break_init ) THEN
          ------------------------------
          -- ���ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���׍��vLG�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_total_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���׍��vG�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei_total_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- �W�v�l�o��
          ------------------------------
          -- ���[�t�̏ꍇ�o��
          IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
            -- ���_�v�v�搔�i�����j
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_arrive_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_plan_arrive_total ;
            -- ���_�v�\�����i�����j
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_arrive_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_confirm_arrive_total ;
            -- ���_�v���ِ��i�����j
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_arrive_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_plan_arrive_total
                                                                  - ln_confirm_arrive_total ;
          END IF;
          -- ���_�v�v�搔�i�݌v�j
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_subtotal_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_plan_subtotal_total ;
          -- ���_�v�\�����i�݌v�j
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_subtotal_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_confirm_subtotal_total ;
          -- ���_�v���ِ��i�݌v�j
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_subtotal_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_plan_subtotal_total
                                                                  - ln_confirm_subtotal_total ;
          -- ���[�t�̏ꍇ�o��
          IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
            -- ���_�v�v�搔�i���ԁj
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_monthly_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_plan_monthly_total ;
            -- ���_�v�\�����i���ԁj
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_monthly_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_confirm_monthly_total ;
            -- ���_�v���ِ��i���ԁj
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_monthly_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_plan_monthly_total
                                                                  - ln_confirm_monthly_total ;
-- 2008/06/19 Y.Yamamoto V1.1 Update Start
-- 0���Z�Ή�
            -- ���_�v�B�����i���ԁj
          IF (ln_plan_monthly_total <> 0) THEN
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'tassei_ritu_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := TRUNC(ln_confirm_monthly_total /
                                                                  ln_plan_monthly_total * 100, 2) ;
          END IF;
-- 2008/06/19 Y.Yamamoto V1.1 Update End
          END IF;
          -- -----------------------------------------------------
          -- �W�v�l�N���A����
          -- -----------------------------------------------------
          -- ���_�v�v�搔�i�����j�T�}���p�ϐ�
          ln_plan_arrive_total           := 0;
          -- ���_�v�\�����i�����j�T�}���p�ϐ�
          ln_confirm_arrive_total        := 0;
          -- ���_�v�v�搔�i�݌v�j�T�}���p�ϐ�
          ln_plan_subtotal_total         := 0;
          -- ���_�v�\�����i�݌v�j�T�}���p�ϐ�
          ln_confirm_subtotal_total      := 0;
          -- ���_�v�v�搔�i���ԁj�T�}���p�ϐ�
          ln_plan_monthly_total          := 0;
          -- ���_�v�\�����i���ԁj�T�}���p�ϐ�
          ln_confirm_monthly_total       := 0;
--
          ------------------------------
          -- ���׍��vG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei_total_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- ���׍��vLG�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_total_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- -----------------------------------------------------
          -- �o�ג����f�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_chosei' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF;
--
        -- �o�͏����I��
        EXIT WHEN (l_cnt > it_chosei_data.COUNT);
--
        -- -----------------------------------------------------
        -- �o�ג����f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_chosei' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- �y�f�[�^�z���[ID
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'chohyo_id';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
--
        -- �y�f�[�^�z���s��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_time';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ld_now_date, gv_date_format1);
--
        -- �y�f�[�^�z���_�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kyoten_cd';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).head_sales_branch;
--
        -- �y�f�[�^�z���_����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kyoten_nm';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).kyoten_nm;
--
        -- �y�f�[�^�z����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_date';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( it_chosei_data(l_cnt).arrival_date
                                                           ,gv_date_format2);
--
        -- �y�f�[�^�z�o�Ɍ��R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'syukkomoto_cd';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_syukkomoto_cd;
--
        -- �y�f�[�^�z�o�Ɍ�����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'syukkomoto_nm';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_syukkomoto_nm;
--
        -- �y�f�[�^�z�S������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tanto_busho';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value 
                                     := xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID);
--
        -- �y�f�[�^�z�S������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tanto_nm';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value 
                                     := xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID);
--
        -- -----------------------------------------------------
        -- ���׏��f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- �u���C�N�L�[�X�V
        lv_head_sales_branch_break := it_chosei_data(l_cnt).head_sales_branch;
--
      END IF ;
--
--=========================================================================
      -- -----------------------------------------------------
      -- ���׃f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- �y�f�[�^�z�i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).item_code ;
--
      -- �y�f�[�^�z�i�ږ�
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).item_name ;
--
      -- ���[�t�̏ꍇ�o��
      IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
        -- �y�f�[�^�z�v�搔�i�����j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_arrive';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).plan_quantity ;
--
        -- �y�f�[�^�z�\�����i�����j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_arrive';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).confirm_quantity ;
--
        -- �y�f�[�^�z���ِ��i�����j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_arrive';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).plan_quantity
                                                     - it_chosei_data(l_cnt).confirm_quantity;
      END IF;
--
      -- �y�f�[�^�z�v�搔�i�݌v�j
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_subtotal';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).plan_subtotal_quantity ;
--
      -- �y�f�[�^�z�\�����i�݌v�j
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_subtotal';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).confirm_subtotal_quantity ;
--
      -- �y�f�[�^�z���ِ��i�݌v�j
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_subtotal';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).plan_subtotal_quantity 
                                                  - it_chosei_data(l_cnt).confirm_subtotal_quantity;
--
      -- ���[�t�̏ꍇ�o��
      IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
      -- �y�f�[�^�z�v�搔�i���ԁj
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_monthly';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).monthly_plan_quantity ;
--
        -- �y�f�[�^�z�\�����i���ԁj
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_monthly';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).monthly_confirm_quantity ;
--
        -- �y�f�[�^�z���ِ��i���ԁj
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_monthly';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).monthly_plan_quantity
                                                   - it_chosei_data(l_cnt).monthly_confirm_quantity;
--
        -- �y�f�[�^�z�B�����i���ԁj
        IF (it_chosei_data(l_cnt).monthly_plan_quantity <> 0) THEN
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tassei_ritu';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
                   := TRUNC(it_chosei_data(l_cnt).monthly_confirm_quantity
                                           / it_chosei_data(l_cnt).monthly_plan_quantity * 100, 2);
        END IF;

--
        -- �y�f�[�^�z�v�搔�i�S�Ёj
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_zensha';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).zensha_plan_quantity ;
--
        -- �y�f�[�^�z�\�����i�S�Ёj
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_zensha';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).zensha_confirm_quantity ;
      END IF;
--
      -- -----------------------------------------------------
      -- ���׃f�[�^�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- ���v�l�Z�o
      -- -----------------------------------------------------
      -- ���[�t�̏ꍇ�̂݌v�Z
      IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
        -- ���_�v�v�搔�i�����j�T�}���p�ϐ�
        ln_plan_arrive_total
                    := ln_plan_arrive_total + it_chosei_data(l_cnt).plan_quantity;
        -- ���_�v�\�����i�����j�T�}���p�ϐ�
        ln_confirm_arrive_total
                    := ln_confirm_arrive_total + it_chosei_data(l_cnt).confirm_quantity;
      END IF;
      -- ���_�v�v�搔�i�݌v�j�T�}���p�ϐ�
      ln_plan_subtotal_total
                    := ln_plan_subtotal_total + it_chosei_data(l_cnt).plan_subtotal_quantity;
      -- ���_�v�\�����i�݌v�j�T�}���p�ϐ�
      ln_confirm_subtotal_total
                    := ln_confirm_subtotal_total + it_chosei_data(l_cnt).confirm_subtotal_quantity;
      -- ���[�t�̏ꍇ�o��
      IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
        -- ���_�v�v�搔�i���ԁj�T�}���p�ϐ�
        ln_plan_monthly_total
                    := ln_plan_monthly_total + it_chosei_data(l_cnt).monthly_plan_quantity;
        -- ���_�v�\�����i���ԁj�T�}���p�ϐ�
        ln_confirm_monthly_total
                    := ln_confirm_monthly_total + it_chosei_data(l_cnt).monthly_confirm_quantity;
      END IF;
--
    END LOOP chosei_data_loop;
--
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
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
  END prc_create_xml_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_chosei_data
   * Description      : �o�ג����\���擾����
   ***********************************************************************************/
  PROCEDURE prc_get_chosei_data
    (
      id_arrival_date       IN  DATE
     ,ot_chosei_data        OUT NOCOPY type_chosei_data_tbl
     ,ov_errbuf             OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_get_chosei_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT xsatt.head_sales_branch            AS head_sales_branch          -- ���_�R�[�h
          ,xcav.party_short_name              AS kyoten_name                -- ���_��
          ,xsatt.item_code                    AS item_code                  -- �i�ڃR�[�h
          ,xsatt.item_name                    AS item_name                  -- �i�ږ�
          ,xsatt.arrival_date                 AS arrival_date               -- ����
          ,xsatt.plan_quantity                AS plan_quantity              -- �v�搔�i�����j
          ,xsatt.confirm_quantity             AS confirm_quantity           -- �\�����i�����j
          ,xsatt.plan_subtotal_quantity       AS plan_subtotal_quantity     -- �v�搔�i�݌v�j
          ,xsatt.confirm_subtotal_quantity    AS confirm_subtotal_quantity  -- �\�����i�݌v�j
          ,xsatt.monthly_plan_quantity        AS monthly_plan_quantity      -- �v�搔�i���ԁj
          ,xsatt.monthly_confirm_quantity     AS monthly_confirm_quantity   -- �\�����i���ԁj
          ,xsaat.plan_quantity                AS zensha_plan_quantity       -- �v�搔�i�S�Ёj
          ,xsaat.confirm_quantity             AS zensha_confirm_quantity    -- �\�����i�S�Ёj
--
    BULK COLLECT INTO ot_chosei_data
--
    FROM   xxwsh_ship_adjust_total_tmp   xsatt               -- �o�ג����\�W�v���ԃe�[�u��
          ,xxwsh_ship_adjust_all_tmp     xsaat               -- �o�ג����\�S�В��ԃe�[�u��
          ,xxcmn_cust_accounts2_v        xcav                -- �ڋq���VIEW2
--
    WHERE
    ------------------------------------------------------------------------
    -- �o�ג����\�W�v���ԃe�[�u��
        xsatt.arrival_date                        = id_arrival_date
    ------------------------------------------------------------------------
    -- �o�ג����\�S�В��ԃe�[�u��
    AND xsatt.item_code                           = xsaat.item_code(+)
    ------------------------------------------------------------------------
    -- �ڋq���VIEW2
    AND xsatt.head_sales_branch                    = xcav.party_number
    AND xcav.start_date_active                    <= id_arrival_date
    AND xcav.end_date_active                      >= id_arrival_date
    ------------------------------------------------------------------------
    ORDER BY xsatt.head_sales_branch
            ,xsatt.item_code
    ;
--
  EXCEPTION
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
  END prc_get_chosei_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_plan_confirm_marge_data
   * Description      : ���[�t�v�搔�E�\�����}�[�W����
   ***********************************************************************************/
  PROCEDURE prc_plan_confirm_marge_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_plan_confirm_marge_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
    -- =====================================================
    -- �}�[�W����
    -- =====================================================
    MERGE INTO xxwsh_ship_adjust_days_tmp         xsadt
    USING      xxwsh_shippng_adj_plan_act_tmp     xsaat
    ON  (    xsadt.head_sales_branch = xsaat.head_sales_branch
         AND xsadt.item_code         = xsaat.item_code
         AND xsadt.arrival_date      = xsaat.arrival_date)
--
    WHEN MATCHED THEN
    UPDATE SET xsadt.confirm_quantity = xsaat.confirm_quantity
    WHEN NOT MATCHED THEN
    INSERT (
        head_sales_branch
       ,item_code
       ,item_name
       ,arrival_date
       ,plan_quantity
       ,confirm_quantity
    ) VALUES (
        xsaat.head_sales_branch
       ,xsaat.item_code
       ,xsaat.item_name
       ,xsaat.arrival_date
       ,0
       ,xsaat.confirm_quantity
     );
--
  EXCEPTION
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
  END prc_plan_confirm_marge_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_drink_subtotal_data
   * Description      : �h�����N�݌v���Z�o����
   ***********************************************************************************/
  PROCEDURE prc_get_drink_subtotal_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_get_drink_subtotal_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- �݌v���E���Ԑ��Z�o�f�[�^
    lt_drink_total_mon_data           type_drink_total_mon_tbl;
    -- �擾�f�[�^��
    ln_cnt                            NUMBER DEFAULT 0;
--
  BEGIN
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT xsadt.head_sales_branch         AS head_sales_branch                 -- ���_�R�[�h
          ,xsadt.item_code                 AS item_code                         -- �i�ڃR�[�h
          ,xsadt.item_name                 AS item_name                         -- �i�ږ�
          ,xsadt.arrival_date              AS arrival_date                      -- ����
          ,xsadt.plan_quantity             AS plan_quantity                     -- �v�搔�i�����j
          ,xsadt.confirm_quantity          AS confirm_quantity                  -- �\�����i�����j
          ,xsadt.plan_quantity             AS plan_subtotal_quantity            -- �v�搔�i�݌v�j
          ,SUM(xsadt.confirm_quantity)                                          -- �\�����i�݌v�j
             OVER (PARTITION BY xsadt.head_sales_branch, xsadt.item_code)
          ,0                               AS plan_monthly_quantity             -- �v�搔�i���ԁj
          ,0                               AS confirm_monthly_quantity          -- �\�����i���ԁj
--
    BULK COLLECT INTO lt_drink_total_mon_data
--
    FROM xxwsh_ship_adjust_days_tmp   xsadt                       -- �o�ג����\���ʒ��ԃe�[�u��
    ;
--
    -- ====================================================
    -- �f�[�^�o�^
    -- ====================================================
    ln_cnt := lt_drink_total_mon_data.COUNT;
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_i_head_sales_branch(ln_move_cnt)                                    -- ���_�R�[�h
        := lt_drink_total_mon_data(ln_move_cnt).head_sales_branch;
      gt_i_item_code(ln_move_cnt)                                            -- �i�ڃR�[�h
        := lt_drink_total_mon_data(ln_move_cnt).item_code;
      gt_i_item_name(ln_move_cnt)                                            -- �i�ږ�
        := lt_drink_total_mon_data(ln_move_cnt).item_name;
      gt_i_arrival_date(ln_move_cnt)                                         -- ����
        := lt_drink_total_mon_data(ln_move_cnt).arrival_date;
      gt_i_plan_quantity(ln_move_cnt)                                        -- �v�搔�i�����j
        := lt_drink_total_mon_data(ln_move_cnt).plan_quantity;
      gt_i_confirm_quantity(ln_move_cnt)                                     -- �\�����i�����j
        := lt_drink_total_mon_data(ln_move_cnt).confirm_quantity;
      gt_i_plan_subtotal_quantity(ln_move_cnt)                               -- �v�搔�i�݌v�j
        := lt_drink_total_mon_data(ln_move_cnt).plan_subtotal_quantity;
      gt_i_confirm_subtotal_quantity(ln_move_cnt)                            -- �\�����i�݌v�j
        := lt_drink_total_mon_data(ln_move_cnt).confirm_subtotal_quantity;
      gt_i_plan_monthly_quantity(ln_move_cnt)                                -- �v�搔�i���ԁj
        := lt_drink_total_mon_data(ln_move_cnt).plan_monthly_quantity;
      gt_i_confirm_monthly_quantity(ln_move_cnt)                             -- �\�����i���ԁj
        := lt_drink_total_mon_data(ln_move_cnt).confirm_monthly_quantity;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_ship_adjust_total_tmp(
        head_sales_branch,                         -- ���_�R�[�h
        item_code,                                 -- �i�ڃR�[�h
        item_name,                                 -- �i�ږ�
        arrival_date,                              -- ����
        plan_quantity,                             -- �v�搔�i�����j
        confirm_quantity,                          -- �\�����i�����j
        plan_subtotal_quantity,                    -- �v�搔�i�݌v�j
        confirm_subtotal_quantity,                 -- �\�����i�݌v�j
        monthly_plan_quantity,                     -- �v�搔�i���ԁj
        monthly_confirm_quantity                   -- �\�����i���ԁj
      )VALUES(
        gt_i_head_sales_branch(ln_move_cnt),
        gt_i_item_code(ln_move_cnt),
        gt_i_item_name(ln_move_cnt),
        gt_i_arrival_date(ln_move_cnt),
        gt_i_plan_quantity(ln_move_cnt),
        gt_i_confirm_quantity(ln_move_cnt),
        gt_i_plan_subtotal_quantity(ln_move_cnt),
        gt_i_confirm_subtotal_quantity(ln_move_cnt),
        gt_i_plan_monthly_quantity(ln_move_cnt),
        gt_i_confirm_monthly_quantity(ln_move_cnt)
      );
--
  EXCEPTION
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
  END prc_get_drink_subtotal_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_drink_confirm_data
   * Description      : �h�����N�\�����擾����
   ***********************************************************************************/
  PROCEDURE prc_get_drink_confirm_data(
      iv_select_status         IN         VARCHAR2      -- �v���t�@�C��.���o�ΏۃX�e�[�^�X
     ,iv_kyoten_cd             IN         VARCHAR2      -- ���_
     ,iv_shipped_locat         IN         VARCHAR2      -- �o�Ɍ�
     ,id_arrival_date          IN         DATE          -- ����
     ,id_bucket_date_from      IN         DATE          -- �o�P�b�g����(FROM)
     ,id_bucket_date_to        IN         DATE          -- �o�P�b�g����(TO)
     ,on_confirm_cnt           OUT        NUMBER        -- �擾����
     ,ov_errbuf                OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode               OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_drink_confirm_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- �\�����f�[�^
    lt_drink_confirm_data                  type_drink_confirm_data_tbl;
    -- �擾�f�[�^��
    ln_cnt                                 NUMBER DEFAULT 0;
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
    -- �f�[�^���o
    -- ====================================================
    SELECT xoha.head_sales_branch                    AS head_sales_branch      -- �Ǌ����_
          ,xola.request_item_code                    AS item_code              -- �o�וi��
          ,MAX(ximv.item_short_name)                 AS item_name              -- ����
          ,xoha.schedule_arrival_date                AS arrival_date           -- ���ח\���
          ,SUM(CASE
                 -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X=�u�o�׎��ьv��ρv�̏ꍇ
                 WHEN  (xoha.req_status = gv_req_status) THEN
                   CASE WHEN (ximv.conv_unit IS NULL) THEN
                     xola.shipped_quantity
                   ELSE
                     TRUNC(xola.shipped_quantity / CASE
                                                     WHEN ximv.num_of_cases IS NULL THEN '1'
                                                     WHEN ximv.num_of_cases = '0'   THEN '1'
                                                     ELSE ximv.num_of_cases
                                                   END, 3)
                   END
--
                 ELSE
--
                   -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X=�u�o�׎��ьv��ρv�ȊO�̏ꍇ
                   CASE WHEN (ximv.conv_unit IS NULL) THEN
                     xola.quantity
                   ELSE
                     TRUNC(xola.quantity / CASE
                                             WHEN ximv.num_of_cases IS NULL THEN '1'
                                             WHEN ximv.num_of_cases = '0'   THEN '1'
                                             ELSE ximv.num_of_cases
                                           END, 3)
                   END
                 END)                                 AS confirm_quantity     -- �\����
--
    BULK COLLECT INTO lt_drink_confirm_data
--
    FROM  xxcmn_sourcing_rules      xsr               -- �����\���A�h�I���}�X�^
         ,xxwsh_order_headers_all   xoha              -- �󒍃w�b�_�A�h�I��
         ,xxwsh_order_lines_all     xola              -- �󒍖��׃A�h�I��
         ,xxcmn_item_mst2_v         ximv              -- OPM�i�ڏ��VIEW
-- mod start ver1.6
--         ,xxcmn_item_categories4_v  xicv              -- OPM�i�ڃJ�e�S���������VIEW4
         ,xxcmn_item_categories5_v  xicv              -- OPM�i�ڃJ�e�S���������VIEW5
-- mod end ver1.6
         ,xxcmn_lookup_values2_v    xlvv1             -- �N�C�b�N�R�[�h1
         ,xxcmn_lookup_values2_v    xlvv2             -- �N�C�b�N�R�[�h2
--
    WHERE
    ------------------------------------------------------------------------
    -- �N�C�b�N�R�[�h�P
        xlvv1.lookup_type                      = gv_lookup_type1
    AND xlvv1.lookup_code                      = iv_select_status
    ------------------------------------------------------------------------
    -- �N�C�b�N�R�[�h�Q
    AND xlvv2.lookup_type                      = xlvv1.meaning
    ------------------------------------------------------------------------
    -- �����\���A�h�I���}�X�^
    AND xsr.plan_item_flag                     = gv_plan_syohin_flg
    AND xsr.base_code                          = NVL(iv_kyoten_cd, xsr.base_code)
    AND xsr.delivery_whse_code                 = NVL(iv_shipped_locat, xsr.delivery_whse_code)
    AND xsr.item_code                          = xola.request_item_code
    AND xsr.base_code                          = xoha.head_sales_branch
    AND xsr.delivery_whse_code                 = xoha.deliver_from
    AND xsr.start_date_active                 <= id_arrival_date
    AND xsr.end_date_active                   >= id_arrival_date
    ------------------------------------------------------------------------
    -- �󒍃w�b�_�A�h�I��
    AND xoha.latest_external_flag              = 'Y'
    AND xoha.schedule_arrival_date            >= id_bucket_date_from
    AND xoha.schedule_arrival_date            <= id_bucket_date_to
    AND xoha.req_status                        = xlvv2.lookup_code
    ------------------------------------------------------------------------
    -- �󒍖��׃A�h�I������
    AND xoha.order_header_id                   = xola.order_header_id
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��view
    AND xola.request_item_code                 = ximv.item_no
    AND ximv.start_date_active                <= id_arrival_date
    AND ximv.end_date_active                  >= id_arrival_date
    ------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW4����
    AND ximv.item_id                           = xicv.item_id
    AND xicv.prod_class_code                   = gv_syori_kbn_drink
    ------------------------------------------------------------------------
    GROUP BY xoha.head_sales_branch                        -- �󒍃w�b�_�A�h�I��.�Ǌ����_
            ,xola.request_item_code                        -- �󒍃w�b�_����.�o�וi��
            ,xoha.schedule_arrival_date                    -- �󒍃w�b�_�A�h�I��.���ח\���
    ;
--
    -- ====================================================
    -- �f�[�^�o�^
    -- ====================================================
    ln_cnt := lt_drink_confirm_data.COUNT;
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_plan_head_sales_branch(ln_move_cnt)                           -- ���_�R�[�h
        := lt_drink_confirm_data(ln_move_cnt).head_sales_branch;
      gt_plan_item_code(ln_move_cnt)                                   -- �i�ڃR�[�h
        := lt_drink_confirm_data(ln_move_cnt).item_code;
      gt_plan_item_name(ln_move_cnt)                                   -- �i�ږ�
        := lt_drink_confirm_data(ln_move_cnt).item_name;
      gt_plan_arrival_date(ln_move_cnt)                                -- ����
        := lt_drink_confirm_data(ln_move_cnt).arrival_date;
      gt_plan_confirm_quantity(ln_move_cnt)                            -- �\�����i�����j
        := lt_drink_confirm_data(ln_move_cnt).confirm_quantity;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_shippng_adj_plan_act_tmp(
        head_sales_branch,                         -- ���_�R�[�h
        item_code,                                 -- �i�ڃR�[�h
        item_name,                                 -- �i�ږ�
        arrival_date,                              -- ����
        confirm_quantity                           -- �\�����i�����j
      )VALUES(
        gt_plan_head_sales_branch(ln_move_cnt),
        gt_plan_item_code(ln_move_cnt),
        gt_plan_item_name(ln_move_cnt),
        gt_plan_arrival_date(ln_move_cnt),
        gt_plan_confirm_quantity(ln_move_cnt)
      );
--
    on_confirm_cnt := ln_cnt;
--
  EXCEPTION
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_drink_confirm_data;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_drink_plan_data
   * Description      : �h�����N�v�搔�擾����
   ***********************************************************************************/
  PROCEDURE prc_get_drink_plan_data(
      iv_kyoten_cd             IN         VARCHAR2      -- ���_
     ,iv_shipped_locat         IN         VARCHAR2      -- �o�Ɍ�
     ,id_arrival_date          IN         DATE          -- ����
     ,id_bucket_from           IN         DATE          -- �o�P�b�g���t(FROM)
     ,id_bucket_to             IN         DATE          -- �o�P�b�g���t(TO)
     ,on_plan_cnt              OUT        NUMBER        -- �擾����
     ,ov_errbuf                OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode               OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_drink_plan_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- �C���f�b�N�X
    ln_cnt                        NUMBER DEFAULT 1;
    -- �h�����N�v�搔�f�[�^
    lt_drink_plan_data            type_drink_plan_data_tbl;
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
    -- �f�[�^���o
    -- ====================================================
    SELECT  xsr.base_code
           ,xsr.item_code
           ,ximv.item_short_name
           ,xsabt.bucket_date
           ,NVL(sub.plan_quantity, 0)
--
    BULK COLLECT INTO lt_drink_plan_data
--
    FROM xxcmn_sourcing_rules             xsr                      -- �����\���A�h�I���}�X�^
        ,xxwsh_shippng_adj_bucket_tmp     xsabt                    -- �o�ג����\�o�P�b�g���ԃe�[�u��
        ,xxcmn_item_mst2_v                ximv                     -- OPM�i�ڏ��VIEW
-- mod start ver1.6
--        ,xxcmn_item_categories4_v         xicv                     -- OPM�i�ڃJ�e�S���������VIEW4
        ,xxcmn_item_categories5_v         xicv                     -- OPM�i�ڃJ�e�S���������VIEW5
-- mod end ver1.6
        ,(SELECT mfde.attribute3          AS head_sales_branch     -- �t�H�[�L���X�g��.���_
                ,MAX(ximv.item_no)        AS item_code             -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
                ,SUM(CASE
                       -- OPM�i�ڃ}�X�^.���o�Ɋ��Z�P�ʂ����ݒ�̏ꍇ
                       WHEN (ximv.conv_unit IS NULL) THEN
                         mfda.original_forecast_quantity
                       ELSE
                         TRUNC(mfda.original_forecast_quantity / 
                                                           CASE
                                                             WHEN ximv.num_of_cases IS NULL THEN '1'
                                                             WHEN ximv.num_of_cases = '0'   THEN '1'
                                                             ELSE ximv.num_of_cases
                                                           END, 3)
                       END)               AS plan_quantity
--
          FROM  mrp_forecast_designators  mfde                     -- �t�H�[�L���X�g��
               ,mrp_forecast_dates        mfda                     -- �t�H�[�L���X�g���t
               ,xxcmn_item_mst2_v         ximv                     -- OPM�i�ڏ��VIEW
-- mod start ver1.6
--               ,xxcmn_item_categories4_v  xicv                     -- OPM�i�ڃJ�e�S���������VIEW4
               ,xxcmn_item_categories5_v  xicv                     -- OPM�i�ڃJ�e�S���������VIEW5
-- mod end ver1.6
--
          WHERE
          ------------------------------------------------------------------------
          -- �t�H�[�L���X�g��
              mfde.attribute1          = gv_forecast_kbn_ksyohin
          AND mfde.attribute3          = NVL(iv_kyoten_cd, mfde.attribute3)
          AND mfde.attribute2          = NVL(iv_shipped_locat, mfde.attribute2)
          ------------------------------------------------------------------------
          -- �t�H�[�L���X�g���t
          AND mfde.forecast_designator = mfda.forecast_designator
          AND mfde.organization_id     = mfda.organization_id
          AND mfda.forecast_date       >= id_bucket_from
          AND mfda.forecast_date       <= id_bucket_to
          ------------------------------------------------------------------------
          -- OPM�i�ڏ��VIEW����
          AND mfda.inventory_item_id   = ximv.inventory_item_id
          AND ximv.start_date_active   <= id_arrival_date
          AND ximv.end_date_active     >= id_arrival_date
          ------------------------------------------------------------------------
          -- OPM�i�ڃJ�e�S���������VIEW4
          AND ximv.item_id             =  xicv.item_id
          AND xicv.prod_class_code     = gv_syori_kbn_drink
          ------------------------------------------------------------------------
          GROUP BY mfde.attribute3                                  -- �t�H�[�L���X�g��.���_
                  ,mfda.inventory_item_id                           -- �t�H�[�L���X�g���t.�i��ID
          ) sub
--
    WHERE
    ------------------------------------------------------------------------
    -- �����\���A�h�I���}�X�^
        xsr.plan_item_flag        = gv_plan_syohin_flg
    AND xsr.base_code             = NVL(iv_kyoten_cd, xsr.base_code)
    AND xsr.delivery_whse_code    = NVL(iv_shipped_locat, xsr.delivery_whse_code)
    AND xsr.start_date_active     <= id_arrival_date
    AND xsr.end_date_active       >= id_arrival_date
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW����
    AND xsr.item_code             = ximv.item_no
    AND ximv.start_date_active   <= id_arrival_date
    AND ximv.end_date_active     >= id_arrival_date
    ------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW4
    AND ximv.item_id             =  xicv.item_id
    AND xicv.prod_class_code     = gv_syori_kbn_drink
    ------------------------------------------------------------------------
    -- ���ʃZ�b�g�A
    AND xsr.base_code             = sub.head_sales_branch(+)
    AND xsr.item_code             = sub.item_code(+)
    ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    ln_cnt := lt_drink_plan_data.COUNT;
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_day_head_sales_branch(ln_move_cnt)                         -- ���_�R�[�h
        := lt_drink_plan_data(ln_move_cnt).head_sales_branch;
      gt_day_item_code(ln_move_cnt)                                 -- �i�ڃR�[�h
        := lt_drink_plan_data(ln_move_cnt).item_code;
      gt_day_item_name(ln_move_cnt)                                 -- �i�ږ�
        := lt_drink_plan_data(ln_move_cnt).item_name;
      gt_day_arrival_date(ln_move_cnt)                              -- ����
        := lt_drink_plan_data(ln_move_cnt).arrival_date;
      gt_day_plan_quantity(ln_move_cnt)                             -- �v�搔�i�����j
        := lt_drink_plan_data(ln_move_cnt).plan_quantity;
      gt_day_confirm_quantity(ln_move_cnt)                          -- �\�����i�����j
        := 0;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_ship_adjust_days_tmp(
        head_sales_branch,                         -- ���_�R�[�h
        item_code,                                 -- �i�ڃR�[�h
        item_name,                                 -- �i�ږ�
        arrival_date,                              -- ����
        plan_quantity,                             -- �v�搔�i�����j
        confirm_quantity                           -- �\�����i�����j
      )VALUES(
        gt_day_head_sales_branch(ln_move_cnt),
        gt_day_item_code(ln_move_cnt),
        gt_day_item_name(ln_move_cnt),
        gt_day_arrival_date(ln_move_cnt),
        gt_day_plan_quantity(ln_move_cnt),
        gt_day_confirm_quantity(ln_move_cnt)
      );
--
    on_plan_cnt := ln_cnt;
--
  EXCEPTION
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_drink_plan_data;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_bucket_data
   * Description      : �o�P�b�g���t�擾����
   ***********************************************************************************/
  PROCEDURE prc_get_bucket_data(
      iv_kyoten_cd             IN  VARCHAR2            -- ���_
     ,iv_shipped_locat         IN  VARCHAR2            -- �o�Ɍ�
     ,id_arrival_date          IN  DATE                -- ����
     ,od_bucket_from           OUT DATE                -- �o�P�b�g���t(FROM)
     ,od_bucket_to             OUT DATE                -- �o�P�b�g���t(TO)
     ,ov_errbuf                OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode               OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_bucket_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- �C���f�b�N�X
    ln_cnt                  NUMBER DEFAULT 1;
    -- ���[�N�o�P�b�g���t(FROM)
    ld_from                 DATE DEFAULT NULL;
    -- ���[�N�o�P�b�g���t(TO)
    ld_to                   DATE DEFAULT NULL;
    -- ���[�J���E��O
    no_data_expt            EXCEPTION;
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
    -- �f�[�^���o
    -- ====================================================
    SELECT MIN(mfda.forecast_date)    AS start_date      -- �t�H�[�L���X�g���t.�J�n��
          ,MAX(mfda.rate_end_date)    AS end_date        -- �t�H�[�L���X�g���t.�I����
--
    INTO ld_from, ld_to
--
    FROM  mrp_forecast_designators    mfde                      -- �t�H�[�L���X�g��
         ,mrp_forecast_dates          mfda                      -- �t�H�[�L���X�g���t
--
    WHERE
    ------------------------------------------------------------------------
    -- �t�H�[�L���X�g��
        mfde.attribute1               = gv_forecast_kbn_ksyohin
    AND mfde.attribute3               = NVL(iv_kyoten_cd, mfde.attribute3)
    AND mfde.attribute2               = NVL(iv_shipped_locat, mfde.attribute2)
    ------------------------------------------------------------------------
    -- �t�H�[�L���X�g���t
    AND mfde.forecast_designator      = mfda.forecast_designator
    AND mfde.organization_id          = mfda.organization_id
    AND mfda.forecast_date            <= id_arrival_date
    AND mfda.rate_end_date            >= id_arrival_date
    ;
--
    IF (ld_from IS NULL OR ld_to IS NULL) THEN
      RAISE no_data_expt ;
    END IF;
--
    -- ====================================================
    -- �o�^����
    -- ====================================================
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����
    -- �o�P�b�g���t(FROM)�i�[
    od_bucket_from := ld_from;
    od_bucket_to := ld_to;
--
    LOOP
      gt_i_bucket_data(ln_cnt) := ld_from;
--
      EXIT WHEN (ld_from = od_bucket_to);
--
      ld_from := ld_from + 1;
      ln_cnt  := ln_cnt + 1;
--
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_shippng_adj_bucket_tmp(
        bucket_date                                             -- �o�P�b�g���t
      )VALUES(
        gt_i_bucket_data(ln_move_cnt)
      );
--
  EXCEPTION
--
    WHEN no_data_expt THEN
      ov_retcode := gv_status_error ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_wsh
                                             ,gv_msg_xxwsh11403  ) ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_bucket_data;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_drink_info
   * Description      : �h�����N���擾����
   ***********************************************************************************/
  PROCEDURE prc_get_drink_info(
      iv_syori_kbn             IN         VARCHAR2
     ,iv_kyoten_cd             IN         VARCHAR2
     ,iv_shipped_locat         IN         VARCHAR2
     ,id_arrival_date          IN         DATE
     ,iv_select_status         IN         VARCHAR2
     ,ov_errbuf                OUT NOCOPY VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode               OUT NOCOPY VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                OUT NOCOPY VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_drink_info'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- �o�P�b�g���t�iFROM)
    ld_bucket_from           DATE DEFAULT NULL;
    -- �o�P�b�g���t�iTO)
    ld_bucket_to             DATE DEFAULT NULL;
    -- �o�ג����\�f�[�^
    lt_chosei_data           type_chosei_data_tbl;
    -- �v�搔�擾����
    ln_plan_cnt              NUMBER DEFAULT 0;
    -- �\�����擾����
    ln_confirm_cnt           NUMBER DEFAULT 0;
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
    -- �o�P�b�g���t�擾����
    -- ====================================================
    prc_get_bucket_data(
        iv_kyoten_cd         =>     iv_kyoten_cd      -- ���_
       ,iv_shipped_locat     =>     iv_shipped_locat  -- �o�Ɍ�
       ,id_arrival_date      =>     id_arrival_date   -- ����
       ,od_bucket_from       =>     ld_bucket_from    -- �o�P�b�g���t(FROM)
       ,od_bucket_to         =>     ld_bucket_to      -- �o�P�b�g���t(TO)
       ,ov_errbuf            =>     lv_errbuf         -- �G���[�E���b�Z�[�W
       ,ov_retcode           =>     lv_retcode        -- ���^�[���E�R�[�h
       ,ov_errmsg            =>     lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- �h�����N�v�搔�擾����
    -- ====================================================
    prc_get_drink_plan_data(
        iv_kyoten_cd         =>     iv_kyoten_cd         -- ���_
       ,iv_shipped_locat     =>     iv_shipped_locat     -- �o�Ɍ�
       ,id_arrival_date      =>     id_arrival_date      -- ����
       ,id_bucket_from       =>     ld_bucket_from       -- �o�P�b�g���t(FROM)
       ,id_bucket_to         =>     ld_bucket_to         -- �o�P�b�g���t(TO)
       ,on_plan_cnt          =>     ln_plan_cnt          -- �擾����
       ,ov_errbuf            =>     lv_errbuf            -- �G���[�E���b�Z�[�W
       ,ov_retcode           =>     lv_retcode           -- ���^�[���E�R�[�h
       ,ov_errmsg            =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- �h�����N�\�����擾����
    -- ====================================================
    prc_get_drink_confirm_data(
        iv_select_status     =>     iv_select_status     -- ���o�ΏۃX�e�[�^�X
       ,iv_kyoten_cd         =>     iv_kyoten_cd         -- ���_
       ,iv_shipped_locat     =>     iv_shipped_locat     -- �o�Ɍ�
       ,id_arrival_date      =>     id_arrival_date      -- ����
       ,id_bucket_date_from  =>     ld_bucket_from       -- �o�P�b�g����(FROM)
       ,id_bucket_date_to    =>     ld_bucket_to         -- �o�P�b�g����(TO)
       ,on_confirm_cnt       =>     ln_confirm_cnt       -- �擾����
       ,ov_errbuf            =>     lv_errbuf            -- �G���[�E���b�Z�[�W
       ,ov_retcode           =>     lv_retcode           -- ���^�[���E�R�[�h
       ,ov_errmsg            =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (ln_plan_cnt <> 0 OR ln_confirm_cnt <> 0) THEN
      -- ====================================================
      -- �h�����N�v�搔�E�\�����}�[�W����
      -- ====================================================
      prc_plan_confirm_marge_data(
          ov_errbuf            =>     lv_errbuf            -- �G���[�E���b�Z�[�W
         ,ov_retcode           =>     lv_retcode           -- ���^�[���E�R�[�h
         ,ov_errmsg            =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- ====================================================
      -- �h�����N�݌v���Z�o����
      -- ====================================================
      prc_get_drink_subtotal_data(
          ov_errbuf            =>     lv_errbuf            -- �G���[�E���b�Z�[�W
         ,ov_retcode           =>     lv_retcode           -- ���^�[���E�R�[�h
         ,ov_errmsg            =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- ====================================================
      -- �o�ג����\���擾����
      -- ====================================================
      prc_get_chosei_data(
          id_arrival_date      =>     id_arrival_date      -- ����
         ,ot_chosei_data       =>     lt_chosei_data       -- �擾���R�[�h�\�i�h�����N���j
         ,ov_errbuf            =>     lv_errbuf            -- �G���[�E���b�Z�[�W
         ,ov_retcode           =>     lv_retcode           -- ���^�[���E�R�[�h
         ,ov_errmsg            =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    IF (lt_chosei_data.COUNT <> 0) THEN
--
      -- ====================================================
      -- �w�l�k�f�[�^�쐬����
      -- ====================================================
      prc_create_xml_data(
          iv_syori_kbn         =>     iv_syori_kbn       -- �����敪
         ,it_chosei_data       =>     lt_chosei_data     -- �o�ג����\�f�[�^
         ,ov_errbuf            =>     lv_errbuf          -- �G���[�E���b�Z�[�W
         ,ov_retcode           =>     lv_retcode         -- ���^�[���E�R�[�h
         ,ov_errmsg            =>     lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
    ELSE
--
      -- ====================================================
      -- �w�l�k�f�[�^�쐬�����i�O���j
      -- ====================================================
      prc_create_zeroken_xml_data(
          ov_errbuf            =>     lv_errbuf          -- �G���[�E���b�Z�[�W
         ,ov_retcode           =>     lv_retcode         -- ���^�[���E�R�[�h
         ,ov_errmsg            =>     lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- �w�l�k�o�͏���
    -- ====================================================
    prc_out_xml_data(
        ov_errbuf            =>     lv_errbuf            -- �G���[�E���b�Z�[�W
       ,ov_retcode           =>     lv_retcode           -- ���^�[���E�R�[�h
       ,ov_errmsg            =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- �f�[�^�Ȃ����A���[�j���O�Z�b�g
    -- ====================================================
    IF (lt_chosei_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
    END IF;
--
  EXCEPTION
      -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_drink_info;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_leaf_zensha_data
   * Description      : ���[�t�S�А��擾����
   ***********************************************************************************/
  PROCEDURE prc_get_leaf_zensha_data
    (
      iv_select_status  IN         VARCHAR2          -- ���o�ΏۃX�e�[�^�X
     ,iv_kyoten_cd      IN         VARCHAR2          -- ���_
     ,iv_shipped_locat  IN         VARCHAR2          -- �o�Ɍ�
     ,id_arrival_date   IN         DATE              -- ����
     ,ov_errbuf         OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_get_leaf_zensha_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- �S�А��f�[�^
    lt_leaf_zensha_data                     type_leaf_zensha_data_tbl;
    -- �擾���R�[�h��
    ln_cnt                                  NUMBER DEFAULT 0;
--
  BEGIN
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT 
          -- 2008/07/23 ST�s��Ή�#475 start
          -- sub3.request_item_code                 AS item_code           -- �i�ڃR�[�h
          --,sub2.plan_quantity                     AS plan_quantity       -- �v�搔
          --,sub3.confirm_quantity                  AS confirm_quantity    -- �\����
           ximv.item_no                           AS item_code           -- �i�ڃR�[�h
          ,NVL(sub2.plan_quantity,0)              AS plan_quantity       -- �v�搔
          ,NVL(sub3.confirm_quantity,0)           AS confirm_quantity    -- �\����
          -- 2008/07/23 ST�s��Ή�#475 End
--
    BULK COLLECT INTO lt_leaf_zensha_data
--
    FROM  ------------------------------------------------------------------------
          -- �o�ג����\�W�v���ԃe�[�u��
          ------------------------------------------------------------------------
          (SELECT DISTINCT(xsatt.item_code)  AS item_code
           FROM   xxwsh_ship_adjust_total_tmp   xsatt            -- �o�ג����\�W�v���ԃe�[�u��
          )                                     sub1
          ------------------------------------------------------------------------
          ------------------------------------------------------------------------
          -- �t�H�[�L���X�g���
          ------------------------------------------------------------------------
         ,(SELECT  mfda.inventory_item_id    AS inventory_item_id
                  ,SUM(CASE
                         -- OPM�i�ڃ}�X�^.���o�Ɋ��Z�P�ʂ����ݒ�̏ꍇ
                         WHEN (ximv.conv_unit IS NULL) THEN
                           mfda.original_forecast_quantity
                         ELSE
                           TRUNC(mfda.original_forecast_quantity /
                                                     CASE
                                                       WHEN ximv.num_of_cases IS NULL THEN '1'
                                                       WHEN ximv.num_of_cases = '0'   THEN '1'
                                                       ELSE ximv.num_of_cases
                                                     END, 3)
                         END
                      )                                   AS plan_quantity    -- �t�H�[�L���X�g���t.����
           FROM   mrp_forecast_designators              mfde
                 ,mrp_forecast_dates                    mfda
                 ,xxcmn_item_mst2_v                     ximv             -- OPM�i�ڏ��VIEW
           WHERE
           ------------------------------------------------------------------------
           -- �t�H�[�L���X�g��
               mfde.attribute1                     = gv_forecast_kbn_hkeikaku
           ------------------------------------------------------------------------
           -- �t�H�[�L���X�g���t
           AND mfde.forecast_designator            = mfda.forecast_designator
           AND mfde.organization_id                = mfda.organization_id
-- mod start ver1.6
--           AND mfda.forecast_date                  = id_arrival_date
           AND mfda.forecast_date                  >=  TRUNC(id_arrival_date, 'MONTH')
           AND mfda.forecast_date                  <=  id_arrival_date
-- mod end ver1.6
           ------------------------------------------------------------------------
           -- OPM�i�ڏ��VIEW
           AND mfda.inventory_item_id              = ximv.inventory_item_id
           AND ximv.start_date_active             <= id_arrival_date
           AND ximv.end_date_active               >= id_arrival_date
           ------------------------------------------------------------------------
           GROUP BY mfda.inventory_item_id
          )                                       sub2
          ------------------------------------------------------------------------
          ------------------------------------------------------------------------
          -- �󒍃f�[�^���
          ------------------------------------------------------------------------
         ,(SELECT  xola.request_item_code      AS request_item_code
                  ,SUM(CASE
                         -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X=�u�o�׎��ьv��ρv�̏ꍇ
                         WHEN  (xoha.req_status = gv_req_status) THEN
                           CASE
                             WHEN (ximv.conv_unit IS NULL) THEN
                               xola.shipped_quantity
                             ELSE
                               TRUNC(xola.shipped_quantity / CASE
                                                               WHEN ximv.num_of_cases IS NULL THEN '1'
                                                               WHEN ximv.num_of_cases = '0'   THEN '1'
                                                               ELSE ximv.num_of_cases
                                                             END, 3)
                             END
                         ELSE
                           -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X=�u�o�׎��ьv��ρv�ȊO�̏ꍇ
                           CASE
                             WHEN (ximv.conv_unit IS NULL) THEN
                               xola.quantity
                             ELSE
                               TRUNC(xola.quantity / CASE
                                                       WHEN ximv.num_of_cases IS NULL THEN '1'
                                                       WHEN ximv.num_of_cases = '0'   THEN '1'
                                                       ELSE ximv.num_of_cases
                                                     END, 3)
                             END
                         END
                       )                                   AS confirm_quantity -- �\����
           FROM  xxwsh_order_headers_all               xoha             -- �󒍃w�b�_�A�h�I��
                ,xxwsh_order_lines_all                 xola             -- �󒍖��׃A�h�I��
                ,xxcmn_lookup_values2_v                xlvv1            -- �N�C�b�N�R�[�h1
                ,xxcmn_lookup_values2_v                xlvv2            -- �N�C�b�N�R�[�h2
                ,xxcmn_item_mst2_v                     ximv             -- OPM�i�ڏ��VIEW
           WHERE
           ------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�P
               xlvv1.lookup_type                   = gv_lookup_type1
           AND xlvv1.lookup_code                   = iv_select_status
           ------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�Q
           AND xlvv2.lookup_type                   = xlvv1.meaning
           ------------------------------------------------------------------------
           -- �󒍃w�b�_�A�h�I������
           AND xoha.req_status                     = xlvv2.lookup_code
           AND xoha.latest_external_flag           = 'Y'
-- mod start ver1.6
--           AND xoha.schedule_arrival_date          = id_arrival_date
           AND xoha.schedule_arrival_date          >= TRUNC(id_arrival_date, 'MONTH')
           AND xoha.schedule_arrival_date          <= id_arrival_date
-- mod end ver1.6
           ------------------------------------------------------------------------
           -- �󒍖��׃A�h�I������
           AND xoha.order_header_id                = xola.order_header_id
           ------------------------------------------------------------------------
           -- OPM�i�ڏ��VIEW����
           AND xola.request_item_code              = ximv.item_no
           AND ximv.start_date_active             <= id_arrival_date
           AND ximv.end_date_active               >= id_arrival_date
           ------------------------------------------------------------------------
           GROUP BY xola.request_item_code
          )                                sub3
         ,xxcmn_item_mst2_v                     ximv             -- OPM�i�ڏ��VIEW
         ------------------------------------------------------------------------
--
    WHERE
    ------------------------------------------------------------------------
    -- �o�ג����\�W�v���ԃe�[�u��
        sub1.item_code                       = ximv.item_no
    ------------------------------------------------------------------------
    -- �t�H�[�L���X�g
    --AND sub2.inventory_item_id               = ximv.inventory_item_id  -- 2008/07/23 ST�s��Ή�#475
    AND sub2.inventory_item_id(+)              = ximv.inventory_item_id  -- 2008/07/23 ST�s��Ή�#475
    ------------------------------------------------------------------------
    -- �󒍃f�[�^
    --AND sub3.request_item_code               = ximv.item_no  -- 2008/07/23 ST�s��Ή�#475
    AND sub3.request_item_code(+)            = ximv.item_no    -- 2008/07/23 ST�s��Ή�#475
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW����
    AND ximv.start_date_active             <= id_arrival_date
    AND ximv.end_date_active               >= id_arrival_date
    ------------------------------------------------------------------------
    ;
--
    -- ====================================================
    -- �f�[�^�o�^
    -- ====================================================
    ln_cnt := lt_leaf_zensha_data.COUNT;
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_all_item_code(ln_move_cnt)                              -- ���_�R�[�h
        := lt_leaf_zensha_data(ln_move_cnt).item_code;
      gt_all_plan_quantity(ln_move_cnt)                          -- �i�ڃR�[�h
        := lt_leaf_zensha_data(ln_move_cnt).plan_quantity;
      gt_all_confirm_quantity(ln_move_cnt)                       -- �i�ږ�
        := lt_leaf_zensha_data(ln_move_cnt).confirm_quantity;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_ship_adjust_all_tmp(
        item_code,                                               -- �i�ڃR�[�h
        plan_quantity,                                           -- �v�搔
        confirm_quantity                                         -- �\����
      )VALUES(
        gt_all_item_code(ln_move_cnt),
        gt_all_plan_quantity(ln_move_cnt),
        gt_all_confirm_quantity(ln_move_cnt)
      );
--
  EXCEPTION
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
  END prc_get_leaf_zensha_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_subtotal_monthly_data
   * Description      : ���[�t�݌v���E���Ԑ��Z�o����
   ***********************************************************************************/
  PROCEDURE prc_get_leaf_total_mon_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_get_leaf_total_mon_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- �݌v���E���Ԑ��Z�o�f�[�^
    lt_leaf_subtotal_monthly_data        type_leaf_total_mon_tbl;
    -- �擾���R�[�h��
    ln_cnt                               NUMBER DEFAULT 0;
--
  BEGIN
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT xsadt.head_sales_branch         AS head_sales_branch                 -- ���_�R�[�h
          ,xsadt.item_code                 AS item_code                         -- �i�ڃR�[�h
          ,xsadt.item_name                 AS item_name                         -- �i�ږ�
          ,xsadt.arrival_date              AS arrival_date                      -- ����
          ,xsadt.plan_quantity             AS plan_quantity                     -- �v�搔�i�����j
          ,xsadt.confirm_quantity          AS confirm_quantity                  -- �\�����i�����j
          ,SUM(xsadt.plan_quantity)
             OVER (PARTITION BY xsadt.head_sales_branch ,xsadt.item_code        -- �v�搔�i�݌v�j
                   ORDER BY xsadt.arrival_date
                   RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                           AS plan_subtotal_quantity
          ,SUM(xsadt.confirm_quantity)
             OVER (PARTITION BY xsadt.head_sales_branch ,xsadt.item_code        -- �\�����i�݌v�j
                   ORDER BY xsadt.arrival_date
                   RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                           AS confirm_subtotal_quantity
          ,SUM(xsadt.plan_quantity)
             OVER (PARTITION BY xsadt.head_sales_branch, xsadt.item_code)
                                           AS plan_monthly_quantity             -- �v�搔�i���ԁj
          ,SUM(xsadt.confirm_quantity)
             OVER (PARTITION BY xsadt.head_sales_branch, xsadt.item_code)
                                           AS confirm_monthly_quantity          -- �\�����i���ԁj
--
    BULK COLLECT INTO lt_leaf_subtotal_monthly_data
--
    FROM   xxwsh_ship_adjust_days_tmp   xsadt               -- �o�ג����\���ʒ��ԃe�[�u��
    ORDER BY xsadt.arrival_date                             -- ����
    ;
--
    -- ====================================================
    -- �f�[�^�o�^
    -- ====================================================
    ln_cnt := lt_leaf_subtotal_monthly_data.COUNT;
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_i_head_sales_branch(ln_move_cnt)                                         -- ���_�R�[�h
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).head_sales_branch;
      gt_i_item_code(ln_move_cnt)                                                 -- �i�ڃR�[�h
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).item_code;
      gt_i_item_name(ln_move_cnt)                                                 -- �i�ږ�
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).item_name;
      gt_i_arrival_date(ln_move_cnt)                                              -- ����
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).arrival_date;
      gt_i_plan_quantity(ln_move_cnt)                                             -- �v�搔�i�����j
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).plan_quantity;
      gt_i_confirm_quantity(ln_move_cnt)                                          -- �\�����i�����j
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).confirm_quantity;
      gt_i_plan_subtotal_quantity(ln_move_cnt)                                    -- �v�搔�i�݌v�j
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).plan_subtotal_quantity;
      gt_i_confirm_subtotal_quantity(ln_move_cnt)                                 -- �\�����i�݌v�j
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).confirm_subtotal_quantity;
      gt_i_plan_monthly_quantity(ln_move_cnt)                                     -- �v�搔�i���ԁj
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).plan_monthly_quantity;
      gt_i_confirm_monthly_quantity(ln_move_cnt)                                  -- �\�����i���ԁj
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).confirm_monthly_quantity;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_ship_adjust_total_tmp(
        head_sales_branch,                         -- ���_�R�[�h
        item_code,                                 -- �i�ڃR�[�h
        item_name,                                 -- �i�ږ�
        arrival_date,                              -- ����
        plan_quantity,                             -- �v�搔�i�����j
        confirm_quantity,                          -- �\�����i�����j
        plan_subtotal_quantity,                    -- �v�搔�i�݌v�j
        confirm_subtotal_quantity,                 -- �\�����i�݌v�j
        monthly_plan_quantity,                     -- �v�搔�i���ԁj
        monthly_confirm_quantity                   -- �\�����i���ԁj
      )VALUES(
        gt_i_head_sales_branch(ln_move_cnt),
        gt_i_item_code(ln_move_cnt),
        gt_i_item_name(ln_move_cnt),
        gt_i_arrival_date(ln_move_cnt),
        gt_i_plan_quantity(ln_move_cnt),
        gt_i_confirm_quantity(ln_move_cnt),
        gt_i_plan_subtotal_quantity(ln_move_cnt),
        gt_i_confirm_subtotal_quantity(ln_move_cnt),
        gt_i_plan_monthly_quantity(ln_move_cnt),
        gt_i_confirm_monthly_quantity(ln_move_cnt)
      );
--
  EXCEPTION
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
  END prc_get_leaf_total_mon_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_leaf_confirm_data
   * Description      : ���[�t�\�����擾����
   ***********************************************************************************/
  PROCEDURE prc_get_leaf_confirm_data(
      iv_select_status      IN         VARCHAR2       -- �v���t�@�C��.���o�ΏۃX�e�[�^�X
     ,iv_kyoten_cd          IN         VARCHAR2       -- ���_
     ,iv_shipped_locat      IN         VARCHAR2       -- �o�Ɍ�
     ,id_arrival_date       IN         DATE           -- ����
     ,on_confirm_cnt        OUT        NUMBER         -- �擾����
     ,ov_errbuf             OUT NOCOPY VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT NOCOPY VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT NOCOPY VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_leaf_confirm_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- �擾�f�[�^
    lt_leaf_confirm_data_tbl          type_leaf_confirm_data_tbl;
    -- �擾�f�[�^��
    ln_cnt                            NUMBER DEFAULT 0;
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
    -- �f�[�^���o
    -- ====================================================
    SELECT xoha.head_sales_branch                  AS head_sales_branch     -- �Ǌ����_
          ,xola.request_item_code                  AS item_code             -- �o�וi��
          ,MAX(ximv.item_short_name)               AS item_name             -- �i�ږ���
          ,xoha.schedule_arrival_date              AS arrival_date          -- ���ח\���
          ,SUM(CASE
              -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X=�u�o�׎��ьv��ρv�̏ꍇ
              WHEN  (xoha.req_status = gv_req_status) THEN
                CASE WHEN (ximv.conv_unit IS NULL) THEN
                       xola.shipped_quantity
                     ELSE
                       TRUNC(xola.shipped_quantity / CASE
                                                       WHEN ximv.num_of_cases IS NULL THEN '1'
                                                       WHEN ximv.num_of_cases = '0'   THEN '1'
                                                       ELSE ximv.num_of_cases
                                                     END, 3)
                     END
              -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X=�u�o�׎��ьv��ρv�̏ꍇ
              ELSE
                CASE WHEN (ximv.conv_unit IS NULL) THEN
                       xola.quantity
                     ELSE
                       TRUNC(xola.quantity
                             / CASE
                                 WHEN ximv.num_of_cases IS NULL THEN '1'
                                 WHEN ximv.num_of_cases = '0'   THEN '1'
                                 ELSE ximv.num_of_cases
                               END, 3)
                     END
              END)                                  AS confirm_quantity     -- �\����
--
    BULK COLLECT INTO lt_leaf_confirm_data_tbl
--
    FROM   xxwsh_order_headers_all    xoha        -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all      xola        -- �󒍖��׃A�h�I��
          ,xxcmn_item_mst2_v          ximv        -- OPM�i�ڏ��VIEW
-- mod start ver1.6
--          ,xxcmn_item_categories4_v   xicv        -- OPM�i�ڃJ�e�S���������VIEW4
          ,xxcmn_item_categories5_v   xicv        -- OPM�i�ڃJ�e�S���������VIEW5
-- mod end ver1.6
          ,xxcmn_lookup_values2_v     xlvv1       -- �N�C�b�N�R�[�h1
          ,xxcmn_lookup_values2_v     xlvv2       -- �N�C�b�N�R�[�h2
    WHERE
    ------------------------------------------------------------------------
    -- �N�C�b�N�R�[�h�P
        xlvv1.lookup_type                      = gv_lookup_type1
    AND xlvv1.lookup_code                      = iv_select_status
    ------------------------------------------------------------------------
    -- �N�C�b�N�R�[�h�Q
    AND xlvv2.lookup_type                      = xlvv1.meaning
    ------------------------------------------------------------------------
    -- �󒍃w�b�_�A�h�I������
    AND   xoha.req_status                     = xlvv2.lookup_code
    AND   xoha.latest_external_flag           = 'Y'
    AND   xoha.head_sales_branch              = NVL(iv_kyoten_cd, xoha.head_sales_branch)
    AND   xoha.deliver_from                   = NVL(iv_shipped_locat, xoha.deliver_from)
    AND   xoha.schedule_arrival_date          >= TRUNC(id_arrival_date, 'MONTH')
    AND   xoha.schedule_arrival_date          <= LAST_DAY(id_arrival_date)
    ------------------------------------------------------------------------
    -- �󒍖��׃A�h�I������
    AND   xoha.order_header_id                = xola.order_header_id
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��view
    AND   xola.request_item_code             = ximv.item_no
    AND   ximv.start_date_active              <= id_arrival_date
    AND   ximv.end_date_active                >= id_arrival_date
    ------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW4����
    AND   ximv.item_id = xicv.item_id
    AND   xicv.prod_class_code                = gv_syori_kbn_leaf
    ------------------------------------------------------------------------
    GROUP BY xoha.head_sales_branch                        -- �󒍃w�b�_�A�h�I��.�Ǌ����_
            ,xola.request_item_code                       -- �󒍃w�b�_����.�o�וi��
            ,xoha.schedule_arrival_date                    -- �󒍃w�b�_�A�h�I��.���ח\���
    ;
--
    -- ====================================================
    -- �f�[�^�o�^
    -- ====================================================
    ln_cnt := lt_leaf_confirm_data_tbl.COUNT;
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_plan_head_sales_branch(ln_move_cnt)                           -- ���_�R�[�h
        := lt_leaf_confirm_data_tbl(ln_move_cnt).head_sales_branch;
      gt_plan_item_code(ln_move_cnt)                                   -- �i�ڃR�[�h
        := lt_leaf_confirm_data_tbl(ln_move_cnt).item_code;
      gt_plan_item_name(ln_move_cnt)                                   -- �i�ږ�
        := lt_leaf_confirm_data_tbl(ln_move_cnt).item_name;
      gt_plan_arrival_date(ln_move_cnt)                                -- ����
        := lt_leaf_confirm_data_tbl(ln_move_cnt).arrival_date;
      gt_plan_confirm_quantity(ln_move_cnt)                            -- �\�����i�����j
        := lt_leaf_confirm_data_tbl(ln_move_cnt).confirm_quantity;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_shippng_adj_plan_act_tmp(
        head_sales_branch,                         -- ���_�R�[�h
        item_code,                                 -- �i�ڃR�[�h
        item_name,                                 -- �i�ږ�
        arrival_date,                              -- ����
        confirm_quantity                           -- �\�����i�����j
      )VALUES(
        gt_plan_head_sales_branch(ln_move_cnt),
        gt_plan_item_code(ln_move_cnt),
        gt_plan_item_name(ln_move_cnt),
        gt_plan_arrival_date(ln_move_cnt),
        gt_plan_confirm_quantity(ln_move_cnt)
      );
--
    on_confirm_cnt := ln_cnt;
--
  EXCEPTION
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_leaf_confirm_data;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_leaf_plan_data
   * Description      : ���[�t�v�搔�擾����
   ***********************************************************************************/
  PROCEDURE prc_get_leaf_plan_data(
      iv_kyoten_cd             IN         VARCHAR2       -- ���_
     ,iv_shipped_locat         IN         VARCHAR2       -- �o�Ɍ�
     ,id_arrival_date          IN         DATE           -- ����
     ,on_plan_cnt              OUT        NUMBER         -- �擾����
     ,ov_errbuf                OUT NOCOPY VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode               OUT NOCOPY VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                OUT NOCOPY VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_leaf_plan_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- �v�搔�f�[�^
    lt_leaf_plan_data              type_leaf_plan_data_tbl;
    -- �擾�f�[�^��
    ln_cnt                         NUMBER DEFAULT 0;
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
    -- �f�[�^���o
    -- ====================================================
    SELECT mfde.attribute3                AS head_sales_branch    -- �t�H�[�L���X�g��.���_
          ,MAX(ximv.item_no)              AS item_code            -- OPM�i�ڏ��VIEW.�i�ڃR�[�h
          ,MAX(ximv.item_short_name)      AS item_name            -- OPM�i�ڏ��VIEW.�i�ږ���
          ,mfda.forecast_date             AS arrival_date         -- �t�H�[�L���X�g���t.�J�n��
          ,SUM(CASE
                 -- OPM�i�ڃ}�X�^.���o�Ɋ��Z�P�ʂ����ݒ�̏ꍇ
                 WHEN (ximv.conv_unit IS NULL) THEN
                   mfda.original_forecast_quantity
                 ELSE
                   TRUNC(mfda.original_forecast_quantity / CASE
                                                             WHEN ximv.num_of_cases IS NULL THEN '1'
                                                             WHEN ximv.num_of_cases = '0'   THEN '1'
                                                             ELSE ximv.num_of_cases
                                                           END, 3)
                 END
              )                           AS plan_quantity        -- �t�H�[�L���X�g���t.����
--
    BULK COLLECT INTO lt_leaf_plan_data
--
    FROM  mrp_forecast_designators  mfde                          -- �t�H�[�L���X�g��
         ,mrp_forecast_dates        mfda                          -- �t�H�[�L���X�g���t
         ,xxcmn_item_mst2_v         ximv                          -- OPM�i�ڏ��VIEW
-- mod start ver1.6
--         ,xxcmn_item_categories4_v  xicv                          -- OPM�i�ڃJ�e�S���������VIEW4
         ,xxcmn_item_categories5_v  xicv                          -- OPM�i�ڃJ�e�S���������VIEW5
-- mod end ver1.6
--
    WHERE
    ------------------------------------------------------------------------
    -- �t�H�[�L���X�g��
        mfde.attribute1               = gv_forecast_kbn_hkeikaku
    AND mfde.attribute3               = NVL(iv_kyoten_cd, mfde.attribute3)
    AND mfde.attribute2               = NVL(iv_shipped_locat, mfde.attribute2)
    ------------------------------------------------------------------------
    -- �t�H�[�L���X�g���t
    AND mfde.forecast_designator      = mfda.forecast_designator
    AND mfde.organization_id          = mfda.organization_id
    AND mfda.forecast_date            >= TRUNC(id_arrival_date, 'MONTH')
    AND mfda.forecast_date            <= LAST_DAY(id_arrival_date)
    ------------------------------------------------------------------------
    -- OPM�i�ڏ��VIEW����
    AND mfda.inventory_item_id        = ximv.inventory_item_id
    AND ximv.start_date_active        <= id_arrival_date
    AND ximv.end_date_active          >= id_arrival_date
    ------------------------------------------------------------------------
    -- OPM�i�ڃJ�e�S���������VIEW4
    AND ximv.item_id                  = xicv.item_id
    AND xicv.prod_class_code          = gv_syori_kbn_leaf
    ------------------------------------------------------------------------
    GROUP BY mfde.attribute3                                      -- �t�H�[�L���X�g��.���_
            ,mfda.inventory_item_id                               -- �t�H�[�L���X�g���t.�i��ID
            ,mfda.forecast_date                                   -- �t�H�[�L���X�g���t.�J�n��
    ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    ln_cnt := lt_leaf_plan_data.COUNT;
--
    -- FORALL�Ŏg�p�ł���悤�Ƀ��R�[�h�ϐ��𕪊��i�[����
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_day_head_sales_branch(ln_move_cnt)                           -- ���_�R�[�h
        := lt_leaf_plan_data(ln_move_cnt).head_sales_branch;
      gt_day_item_code(ln_move_cnt)                                   -- �i�ڃR�[�h
        := lt_leaf_plan_data(ln_move_cnt).item_code;
      gt_day_item_name(ln_move_cnt)                                   -- �i�ږ�
        := lt_leaf_plan_data(ln_move_cnt).item_name;
      gt_day_arrival_date(ln_move_cnt)                                -- ����
        := lt_leaf_plan_data(ln_move_cnt).arrival_date;
      gt_day_plan_quantity(ln_move_cnt)                               -- �v�搔�i�����j
        := lt_leaf_plan_data(ln_move_cnt).plan_quantity;
      gt_day_confirm_quantity(ln_move_cnt)                            -- �\�����i�����j
        := 0;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_ship_adjust_days_tmp(
        head_sales_branch,                         -- ���_�R�[�h
        item_code,                                 -- �i�ڃR�[�h
        item_name,                                 -- �i�ږ�
        arrival_date,                              -- ����
        plan_quantity,                             -- �v�搔�i�����j
        confirm_quantity                           -- �\�����i�����j
      )VALUES(
        gt_day_head_sales_branch(ln_move_cnt),
        gt_day_item_code(ln_move_cnt),
        gt_day_item_name(ln_move_cnt),
        gt_day_arrival_date(ln_move_cnt),
        gt_day_plan_quantity(ln_move_cnt),
        gt_day_confirm_quantity(ln_move_cnt)
      );
--
    on_plan_cnt := ln_cnt;
--
  EXCEPTION
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_leaf_plan_data;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_leaf_info
   * Description      : ���[�t���擾����
   ***********************************************************************************/
  PROCEDURE prc_get_leaf_info(
      iv_syori_kbn             IN  VARCHAR2         -- 01 : �����敪
     ,iv_kyoten_cd             IN  VARCHAR2         -- 02 : ���_
     ,iv_shipped_locat         IN  VARCHAR2         -- 03 : �o�Ɍ�
     ,id_arrival_date          IN  DATE             -- 04 : ����
     ,iv_select_status         IN  VARCHAR2         -- 05 : ���o�ΏۃX�e�[�^�X
     ,ov_errbuf                OUT VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode               OUT VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                OUT VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_leaf_info'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- ���[�t���
    lt_chosei_data           type_chosei_data_tbl;
    -- �v�搔�擾����
    ln_plan_cnt              NUMBER DEFAULT 0;
    -- �\�����擾����
    ln_confirm_cnt           NUMBER DEFAULT 0;
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
    -- ���[�t�v�搔�擾����
    -- ====================================================
    prc_get_leaf_plan_data(
        iv_kyoten_cd         =>     iv_kyoten_cd         -- ���_
       ,iv_shipped_locat     =>     iv_shipped_locat     -- �o�Ɍ�
       ,id_arrival_date      =>     id_arrival_date      -- ����
       ,on_plan_cnt          =>     ln_plan_cnt          -- �擾����
       ,ov_errbuf            =>     lv_errbuf            -- �G���[�E���b�Z�[�W
       ,ov_retcode           =>     lv_retcode           -- ���^�[���E�R�[�h
       ,ov_errmsg            =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- ���[�t�\�����擾����
    -- ====================================================
    prc_get_leaf_confirm_data(
        iv_select_status     =>     iv_select_status     -- ���o�ΏۃX�e�[�^�X
       ,iv_kyoten_cd         =>     iv_kyoten_cd         -- ���_
       ,iv_shipped_locat     =>     iv_shipped_locat     -- �o�Ɍ�
       ,id_arrival_date      =>     id_arrival_date      -- ����
       ,on_confirm_cnt       =>     ln_confirm_cnt       -- �擾����
       ,ov_errbuf            =>     lv_errbuf            -- �G���[�E���b�Z�[�W
       ,ov_retcode           =>     lv_retcode           -- ���^�[���E�R�[�h
       ,ov_errmsg            =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (ln_plan_cnt <> 0 OR ln_confirm_cnt <> 0) THEN
--
      -- ====================================================
      -- ���[�t�v�搔�E�\�����}�[�W����
      -- ====================================================
      prc_plan_confirm_marge_data(
          ov_errbuf            =>     lv_errbuf            -- �G���[�E���b�Z�[�W
         ,ov_retcode           =>     lv_retcode           -- ���^�[���E�R�[�h
         ,ov_errmsg            =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- ====================================================
      -- ���[�t�݌v���E���Ԑ��Z�o����
      -- ====================================================
      prc_get_leaf_total_mon_data(
          ov_errbuf          =>     lv_errbuf            -- �G���[�E���b�Z�[�W
         ,ov_retcode         =>     lv_retcode           -- ���^�[���E�R�[�h
         ,ov_errmsg          =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- ���o�ΏۃX�e�[�^�X<>�u���_�p�^�[���v�̏ꍇ
      IF (iv_select_status <> gv_select_status_kyoten) THEN
--
        -- ====================================================
        -- ���[�t�S�А��擾����
        -- ====================================================
        prc_get_leaf_zensha_data(
            iv_select_status     =>     iv_select_status     -- �v���t�@�C��.���o�ΏۃX�e�[�^�X
           ,iv_kyoten_cd         =>     iv_kyoten_cd         -- ���_
           ,iv_shipped_locat     =>     iv_shipped_locat     -- �o�Ɍ�
           ,id_arrival_date      =>     id_arrival_date      -- ����
           ,ov_errbuf            =>     lv_errbuf            -- �G���[�E���b�Z�[�W
           ,ov_retcode           =>     lv_retcode           -- ���^�[���E�R�[�h
           ,ov_errmsg            =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt ;
        END IF ;
--
      END IF;
--
      -- ====================================================
      -- �o�ג����\���擾����
      -- ====================================================
      prc_get_chosei_data(
          id_arrival_date      =>     id_arrival_date      -- ����
         ,ot_chosei_data       =>     lt_chosei_data       -- �擾���R�[�h�\�i���[�t���j
         ,ov_errbuf            =>     lv_errbuf            -- �G���[�E���b�Z�[�W
         ,ov_retcode           =>     lv_retcode           -- ���^�[���E�R�[�h
         ,ov_errmsg            =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    IF (lt_chosei_data.COUNT <> 0) THEN
      -- ====================================================
      -- �w�l�k�f�[�^�쐬����
      -- ====================================================
      prc_create_xml_data(
          iv_syori_kbn         =>     iv_syori_kbn       -- �����敪
         ,it_chosei_data       =>     lt_chosei_data     -- �o�ג����\�f�[�^
         ,ov_errbuf            =>     lv_errbuf          -- �G���[�E���b�Z�[�W
         ,ov_retcode           =>     lv_retcode         -- ���^�[���E�R�[�h
         ,ov_errmsg            =>     lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
    ELSE
--
      -- ====================================================
      -- �w�l�k�f�[�^�쐬�����i�O���j
      -- ====================================================
      prc_create_zeroken_xml_data(
          ov_errbuf            =>     lv_errbuf          -- �G���[�E���b�Z�[�W
         ,ov_retcode           =>     lv_retcode         -- ���^�[���E�R�[�h
         ,ov_errmsg            =>     lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
      
    -- ====================================================
    -- �w�l�k�o�͏���
    -- ====================================================
    prc_out_xml_data(
        ov_errbuf            =>     lv_errbuf            -- �G���[�E���b�Z�[�W
       ,ov_retcode           =>     lv_retcode           -- ���^�[���E�R�[�h
       ,ov_errmsg            =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- �f�[�^�Ȃ����A���[�j���O�Z�b�g
    -- ====================================================
    IF (lt_chosei_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
    END IF;
--
  EXCEPTION
      -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_leaf_info;
--
--
  /***********************************************************************************
   * Procedure Name   : prc_get_shipped_locat
   * Description      : �o�Ɍ����擾����
   ***********************************************************************************/
  PROCEDURE prc_get_shipped_locat(
  
    iv_shipped_locat  IN         VARCHAR2,
    id_arrival_date   IN         DATE,
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_shipped_locat'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    SELECT xilv.segment1             AS syukkomoto_cd           -- �o�Ɍ��R�[�h
          ,xilv.description          AS syukkomoto_nm           -- �o�Ɍ���
--
    INTO gv_syukkomoto_cd, gv_syukkomoto_nm
--
    FROM   xxcmn_item_locations2_v        xilv                   -- OPM�ۊǏꏊ�}�X�^���VIEW
--
    WHERE
    ------------------------------------------------------------------------
    -- OPM�ۊǏꏊ�}�X�^���VIEW
        xilv.segment1       = iv_shipped_locat
    ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
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
--#####################################  �Œ蕔 END   #############################################
--
  END prc_get_shipped_locat;
--
--
  /***********************************************************************************
   * Procedure Name   : prc_get_profile
   * Description      : �v���t�@�C�����E�Ӄ��x���̒��o�ΏۃX�e�[�^�X���擾���܂��B
   ***********************************************************************************/
  PROCEDURE prc_get_profile(
    ov_select_status  OUT NOCOPY VARCHAR2,
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_profile'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
--
    -- ���o�ΏۃX�e�[�^�X
    ov_select_status := FND_PROFILE.VALUE(gv_profile_id);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (ov_select_status IS NULL) THEN
--
      lv_errbuf := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gc_application_cmn,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10002,         -- ���b�Z�[�W�F�v���t�@�C���擾�G���[
                            gv_tkn_profile,            -- �g�[�N���FNG_PROFILE
                            gv_profile_name            -- �v���t�@�C������
                          ),1,5000);
--
      RAISE global_api_expt;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
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
--#####################################  �Œ蕔 END   #############################################
--
  END prc_get_profile;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_check_input_data
   * Description      : ���̓p�����[�^�`�F�b�N����
   ***********************************************************************************/
  PROCEDURE prc_check_input_data
    (
      iv_arrival_date     IN         VARCHAR2       -- �����i�����j
     ,od_arrival_date     OUT NOCOPY DATE           -- �����i���t�j
     ,ov_errbuf           OUT NOCOPY VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          OUT NOCOPY VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           OUT NOCOPY VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_check_input_data'; -- �v���O������
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
    -- �K�{�`�F�b�N
    -- -----------------------------------------------------
    IF (iv_arrival_date IS NOT NULL) THEN
--
      -- ���t�ϊ�
      od_arrival_date := FND_DATE.STRING_TO_DATE(iv_arrival_date
                                                ,gv_date_format2) ;
--
    ELSE
--
      -- �G���[���b�Z�[�W�o��
      ov_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gv_msg_xxwsh11402
                                            ,gv_msg_tkn_pram
                                            ,gv_msg_contents) ;
--
      ov_errbuf  := ov_errmsg ;
      ov_retcode := gv_status_error;
--
    END IF;
--
  EXCEPTION
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_check_input_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_init
   * Description      : ��������
   ***********************************************************************************/
  PROCEDURE prc_init
    (
      ov_errbuf           OUT NOCOPY VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          OUT NOCOPY VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           OUT NOCOPY VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_init'; -- �v���O������
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
    -- ���ԃe�[�u���폜����
    -- -----------------------------------------------------
    -- �o�ג����\�o�P�b�g���ԃe�[�u��
    DELETE FROM xxwsh_shippng_adj_bucket_tmp;
--
    -- �o�ג����\�S�В��ԃe�[�u��
    DELETE FROM xxwsh_ship_adjust_all_tmp;
--
    -- �o�ג����\���ʒ��ԃe�[�u��
    DELETE FROM xxwsh_ship_adjust_days_tmp;
--
    -- �o�ג����\�\�����ԃe�[�u��
    DELETE FROM xxwsh_shippng_adj_plan_act_tmp;
--
    -- �o�ג����\�W�v���ԃe�[�u��
    DELETE FROM xxwsh_ship_adjust_total_tmp;
--
  EXCEPTION
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
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_init ;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_syori_kbn         IN      VARCHAR2         -- 01 : �������
     ,iv_kyoten_cd         IN      VARCHAR2         -- 02 : ���_
     ,iv_shipped_locat     IN      VARCHAR2         -- 03 : �o�Ɍ�
     ,iv_arrival_date      IN      VARCHAR2         -- 04 : ����
     ,ov_errbuf            OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT     VARCHAR2         -- ���^�[���E�R�[�h            --# �Œ� #
     ,ov_errmsg            OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- �����i���t�j
    ld_arrival_date         DATE DEFAULT NULL;
    -- �v���t�@�C��.���o�ΏۃX�e�[�^�X
    lv_select_status        VARCHAR(10) DEFAULT NULL;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- ���ԃe�[�u���f�[�^�폜����
    -- ====================================================
    prc_init(
          ov_errbuf         =>   lv_errbuf          -- �G���[�E���b�Z�[�W
         ,ov_retcode        =>   lv_retcode         -- ���^�[���E�R�[�h
         ,ov_errmsg         =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- ���̓p�����[�^�`�F�b�N����
    -- ====================================================
    prc_check_input_data(
        iv_arrival_date    => iv_arrival_date     -- �����i�����j
       ,od_arrival_date    => ld_arrival_date     -- �����i���t�j
       ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- �v���t�@�C���擾����
    -- ====================================================
    prc_get_profile(
        ov_select_status   => lv_select_status    -- �v���t�@�C��.���o�ΏۃX�e�[�^�X
       ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- �o�Ɍ����擾����
    -- ====================================================
    IF (iv_shipped_locat IS NOT NULL) THEN
--
      prc_get_shipped_locat(
          iv_shipped_locat   => iv_shipped_locat    -- �o�Ɍ�
         ,id_arrival_date    => ld_arrival_date     -- ����
         ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
         ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
         ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
--
    -- ====================================================
    -- ���[�t���擾����
    -- ====================================================
      prc_get_leaf_info(
          iv_syori_kbn      =>   iv_syori_kbn       -- 01 : �����敪
         ,iv_kyoten_cd      =>   iv_kyoten_cd       -- 02 : ���_
         ,iv_shipped_locat  =>   iv_shipped_locat   -- 03 : �o�Ɍ�
         ,id_arrival_date   =>   ld_arrival_date    -- 04 : ����
         ,iv_select_status  =>   lv_select_status   -- 05 : ���o�ΏۃX�e�[�^�X
         ,ov_errbuf         =>   lv_errbuf          -- �G���[�E���b�Z�[�W
         ,ov_retcode        =>   lv_retcode         -- ���^�[���E�R�[�h
         ,ov_errmsg         =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
    ELSE
--
    -- ====================================================
    -- �h�����N���擾����
    -- ====================================================
      prc_get_drink_info(
          iv_syori_kbn      =>   iv_syori_kbn       -- 01 : �����敪
         ,iv_kyoten_cd      =>   iv_kyoten_cd       -- 02 : ���_
         ,iv_shipped_locat  =>   iv_shipped_locat   -- 03 : �o�Ɍ�
         ,id_arrival_date   =>   ld_arrival_date    -- 04 : ����
         ,iv_select_status  =>   lv_select_status   -- 05 : ���o�ΏۃX�e�[�^�X
         ,ov_errbuf         =>   lv_errbuf          -- �G���[�E���b�Z�[�W
         ,ov_retcode        =>   lv_retcode         -- ���^�[���E�R�[�h
         ,ov_errmsg         =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
    END IF;
--
    IF (lv_retcode = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    ELSIF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF;
--
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
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
  END submain ;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_syori_kbn          IN     VARCHAR2         -- 01 : �������
     ,iv_kyoten_cd          IN     VARCHAR2         -- 02 : ���_
     ,iv_shipped_locat      IN     VARCHAR2         -- 03 : �o�Ɍ�
     ,iv_arrival_date       IN     VARCHAR2         -- 04 : ����
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain(
        iv_syori_kbn          => iv_syori_kbn         -- 01 : �������
       ,iv_kyoten_cd          => iv_kyoten_cd         -- 02 : ���_
       ,iv_shipped_locat      => iv_shipped_locat     -- 03 : �o�Ɍ�
       ,iv_arrival_date       => iv_arrival_date      -- 04 : ����
       ,ov_errbuf             => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
--
    -- ====================================================
    -- ���[���o�b�N����
    -- ====================================================
    ROLLBACK;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh400008c ;
/
