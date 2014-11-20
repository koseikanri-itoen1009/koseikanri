CREATE OR REPLACE PACKAGE BODY xxwsh620005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620005c(body)
 * Description      : �o�Ɏw���m�F�\
 * MD.050           : ����/�z��(���[) T_MD050_BPO_621
 * MD.070           : �o�Ɏw���m�F�\ T_MD070_BPO_62G
 * Version          : 1.11
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  fnc_conv_xml                   FUNCTION   : �w�l�k�^�O�ɕϊ�����B
 *  prc_out_xml_data               PROCEDURE  : �w�l�k�o�͏���
 *  prc_create_zeroken_xml_data    PROCEDURE  : �w�l�k�f�[�^�쐬�����i�O���j
 *  prc_create_xml_data            PROCEDURE  : �w�l�k�f�[�^�쐬����
 *  prc_get_report_data            PROCEDURE  : ���[���擾����
 *  prc_get_profile                PROCEDURE  : �v���t�@�C���擾����
 *  prc_chk_input_param            PROCEDURE  : ���̓p�����[�^�`�F�b�N����
 *  submain                        PROCEDURE  : ���C�������v���V�[�W��
 *  main                           PROCEDURE  : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- --------------------- -------------------------------------------------
 *  Date          Ver.  Editor                Description
 * ------------- ----- --------------------- -------------------------------------------------
 *  2008/05/12    1.0   Masakazu Yamashita    �V�K�쐬
 *  2008/06/04    1.1   Jun Nakada            �N�C�b�N�R�[�h�x���敪�̌������O�������ɕύX(�o�׈ړ�)
 *  2008/06/17    1.2   Masao Hokkanji        �V�X�e���e�X�g�s�No150�Ή�
 *  2008/06/18    1.3   Kazuo Kumamoto        ���Ə����VIEW�̌������O�������ɕύX
 *  2008/06/19    1.4   SCS yamane            �z�Ԕz�����VIEW�̌������O�������ɕύX
 *  2008/07/02    1.5   Akiyoshi Shiina       �ύX�v���Ή�#92
 *                                            �֑������u'�v�u"�v�u<�v�u>�v�u���v�Ή�
 *  2008/07/11    1.6   Kazuo Kumamoto        �����e�X�g��Q�Ή�(�P�ʏo�͐���)
 *  2008/08/05    1.7   Yasuhisa Yamamoto     �����ύX�v���Ή�
 *  2008/09/25    1.8   Yasuhisa Yamamoto     T_TE080_BPO_620 #36,41�A�g�p�s����QT_S_479,501
 *  2008/11/14    1.9   Naoki Fukuda          �ۑ�#62(�����ύX#168)�Ή�(�w���������т����O����)
 *  2009/05/28    1.10  Hitomi Itou           �{�ԏ�Q#1398
 *  2009/09/14    1.11  Hitomi Itou           �{�ԏ�Q#1632
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
  gv_pkg_name                CONSTANT  VARCHAR2(12) := 'xxwsh620005c' ;  -- �p�b�P�[�W��
  gv_report_id               CONSTANT  VARCHAR2(12) := 'XXWSH620005T' ;  -- ���[ID
  -- ���t�t�H�[�}�b�g
  gv_date_fmt_mi             CONSTANT  VARCHAR2(10) := 'MI' ;
  gv_date_fmt_hh24mi         CONSTANT  VARCHAR2(10) := 'HH24:MI' ;
  gv_date_fmt_ymd            CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD' ;
  gv_date_fmt_ymdhm          CONSTANT  VARCHAR2(30) := 'YYYY/MM/DD HH24:MI' ;
  gv_date_fmt_ymdhm_ja       CONSTANT  VARCHAR2(40) := 'YYYY"�N"MM"��"DD"��"HH24"��"MI"��' ;
  gv_date_fmt_all            CONSTANT  VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
  gv_min_time                CONSTANT  VARCHAR2(10) := '0000' ;
  gv_max_time                CONSTANT  VARCHAR2(10) := '2359' ;
--
  ------------------------------
  -- ���b�Z�[�W�֘A
  ------------------------------
  --�A�v���P�[�V������
  gv_application_wsh         CONSTANT  VARCHAR2(5)  := 'XXWSH' ;
  gv_application_cmn         CONSTANT  VARCHAR2(10) := 'XXCMN' ;
  --���b�Z�[�WID�i�v���t�@�C���擾�G���[�j
  gv_msg_id_not_get_prof     CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12251' ;
  --���b�Z�[�WID�i�f�[�^�Ȃ��G���[�j
  gv_msg_not_data_found      CONSTANT  VARCHAR2(50) := 'APP-XXCMN-10122';
  --���b�Z�[�WID�i�p�����[�^�`�F�b�N�G���[�j
  gv_msg_err_param           CONSTANT  VARCHAR2(50) := 'APP-XXWSH-12256';
  --���b�Z�[�W-�g�[�N�����i�v���t�@�C�����j
  gv_msg_tkn_nm_prof         CONSTANT  VARCHAR2(10) := 'PROF_NAME' ;
  --���b�Z�[�W-�g�[�N���l
  gv_msg_tkn_val_prof_wei    CONSTANT  VARCHAR2(30) := 'XXWSH:�o�׏d�ʒP��' ;
  gv_msg_tkn_val_prof_cap    CONSTANT  VARCHAR2(30) := 'XXWSH:�o�חe�ϒP��' ;
  gv_msg_tkn_val_prof_prod   CONSTANT  VARCHAR2(30) := 'XXCMN�F���i�敪(�Z�L�����e�B)' ;
  ------------------------------
  -- �v���t�@�C���֘A
  ------------------------------
  gv_prof_name_weight        CONSTANT  VARCHAR2(30) := 'XXWSH_WEIGHT_UOM' ;        -- �o�׏d�ʒP��
  gv_prof_name_capacity      CONSTANT  VARCHAR2(30) := 'XXWSH_CAPACITY_UOM' ;      -- �o�חe�ϒP��
  gv_prof_name_item_div      CONSTANT  VARCHAR2(30) := 'XXCMN_ITEM_DIV_SECURITY' ; -- ���i�敪
    ------------------------------
  -- �o�ׁE�ړ�����
  ------------------------------
  -- �Ɩ����
  gv_biz_type_cd_ship        CONSTANT  VARCHAR2(1)  := '1' ;        -- �o��
  gv_biz_type_cd_move        CONSTANT  VARCHAR2(1)  := '3' ;        -- �ړ�
  gv_biz_type_nm_ship        CONSTANT  VARCHAR2(4)  := '�o��' ;     -- �o��
  gv_biz_type_nm_move        CONSTANT  VARCHAR2(4)  := '�ړ�' ;     -- �ړ�
  -- �_��O�^���敪
  gv_no_cont_freight_kbn_obj CONSTANT  VARCHAR2(1)  := '1' ;        -- �Ώ�
  -- �i�ځE���i�敪
  gv_prod_cd_drink           CONSTANT  VARCHAR2(1)  := '2' ;        -- ���i�敪:�h�����N
  gv_item_cd_prdct           CONSTANT  VARCHAR2(1)  := '5' ;        -- �i�ڋ敪:���i
-- 2008/09/29 Y.Yamamoto v1.8 ADD Start
  gv_item_cd_genryo          CONSTANT  VARCHAR2(1)  := '1' ;        -- �i�ڋ敪:����
  gv_item_cd_sizai           CONSTANT  VARCHAR2(1)  := '2' ;        -- �i�ڋ敪:����
  gv_item_cd_hanseihin       CONSTANT  VARCHAR2(1)  := '4' ;        -- �i�ڋ敪:�����i
-- 2008/09/29 Y.Yamamoto v1.8 ADD End
  -- �����蓮�����敪
  gv_auto_manual_kbn_a       CONSTANT  VARCHAR2(10) := '10' ;       -- ����
  -- �����敪
  gv_small_kbn_obj           CONSTANT  VARCHAR2(1)  := '1' ;        -- �Ώ�
  gv_small_kbn_not_obj       CONSTANT  VARCHAR2(1)  := '0' ;        -- �ΏۊO
  -- �d�ʗe�ϋ敪
  gv_wei_cap_kbn_w           CONSTANT  VARCHAR2(1)  := '1' ;        -- �d��
  gv_wei_cap_kbn_c           CONSTANT  VARCHAR2(1)  := '2' ;        -- �e��
  ------------------------------
  -- �o�׊֘A
  ------------------------------
  -- �o�׈˗��X�e�[�^�X
  gv_ship_status_close       CONSTANT  VARCHAR2(2)  := '03' ;       -- ���ߍς�
  gv_ship_status_delete      CONSTANT  VARCHAR2(2)  := '99' ;       -- ���
  -- �o�׎x���敪
  gv_ship_pro_kbn_s          CONSTANT  VARCHAR2(1)  := '1' ;        -- �o�׈˗�
  -- �󒍃J�e�S��
  gv_order_cate_ret          CONSTANT  VARCHAR2(10) := 'RETURN' ;   -- �ԕi�i�󒍂̂݁j
  -- �����^�C�v
  gv_document_type_ship_req  CONSTANT  VARCHAR2(10) := '10' ;       -- �o�׈˗�
  -- ���R�[�h�^�C�v
  record_type_siji           CONSTANT  VARCHAR2(10) := '10' ;       -- �w��
  ------------------------------
  -- �ړ��֘A
  ------------------------------
  -- �����^�C�v
  gv_document_type_move      CONSTANT  VARCHAR2(10) := '20' ;       -- �ړ�
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  -- �^���敪
  gv_lookup_cd_freight       CONSTANT  VARCHAR2(30)  := 'XXWSH_FREIGHT_CLASS' ;
  -- �_��O�^���敪
  gv_lookup_cd_no_freight    CONSTANT  VARCHAR2(30)  := 'XXCMN_INCLUDE_EXCLUDE' ;
  -- �m�F�˗�
  gv_lookup_cd_conreq        CONSTANT  VARCHAR2(30)  := 'XXWSH_LG_CONFIRM_REQ_CLASS' ;
  -- ���b�g�X�e�[�^�X�敪
  gv_lookup_cd_lot_status    CONSTANT  VARCHAR2(30)  := 'XXCMN_LOT_STATUS' ;
  -- �x���敪
  gv_lookup_cd_warn          CONSTANT  VARCHAR2(30)  := 'XXWSH_WARNING_CLASS' ;
  -- �����敪
  gv_lookup_cd_reserve       CONSTANT  VARCHAR2(30)  := 'XXINV_AM_RESERVE_CLASS' ;
  -- �����敪
  gv_lookup_cd_move_type     CONSTANT  VARCHAR2(30)  := 'XXINV_MOVE_TYPE' ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  ------------------------------
  -- ���̓p�����[�^�֘A
  ------------------------------
  -- ���̓p�����[�^�i�[�p���R�[�h
  TYPE rec_param_data IS RECORD(
     gyoumu_kbn            VARCHAR2(10)    -- 01:�Ɩ����
    ,block1                VARCHAR2(10)    -- 02:�u���b�N1
    ,block2                VARCHAR2(10)    -- 03:�u���b�N2 
    ,block3                VARCHAR2(10)    -- 04:�u���b�N3
    ,deliver_from_code     VARCHAR2(10)    -- 05:�o�Ɍ�
    ,tanto_code            VARCHAR2(50)    -- 06:�S���҃R�[�h
    ,input_date_time_from  VARCHAR2(30)    -- 07:���͓���FROM
    ,input_date_time_to    VARCHAR2(30)    -- 08:���͓���TO
  );
--
  -- ���[�o�̓f�[�^�i�[�p���R�[�h�ϐ�
  TYPE type_report_data_rec IS RECORD (
    -- �˗�No/�ړ�No
     req_mov_no                       xxwsh_order_headers_all.request_no%TYPE
    -- �z��No
    ,delivery_no                      xxwsh_order_headers_all.delivery_no%TYPE
    -- �o�ɓ�
    ,schedule_ship_date               xxwsh_order_headers_all.schedule_ship_date%TYPE
    -- ����
    ,schedule_arrival_date            xxwsh_order_headers_all.schedule_arrival_date%TYPE
    -- �o�Ɍ��i�R�[�h�j
    ,deliver_from_code                xxwsh_order_headers_all.deliver_from%TYPE
    -- �o�Ɍ��i���́j
    ,deliver_from_name                xxcmn_item_locations2_v.description%TYPE
    -- �z���敪
    ,shipping_method_code             xxwsh_order_headers_all.shipping_method_code%TYPE
    -- �z���敪�i���́j
    ,shipping_method_name             xxwsh_ship_method2_v.ship_method_meaning%TYPE
    -- �^���Ǝ�
    ,freight_carrier_code             xxwsh_order_headers_all.freight_carrier_code%TYPE
    -- �^���Ǝҁi���́j
    ,freight_carrier_name             xxcmn_carriers2_v.party_short_name%TYPE
    -- �^���敪
    ,freight_charge_kbn               xxcmn_lookup_values2_v.meaning%TYPE
    -- �Ɩ����
    ,gyoumu_shubetsu                  VARCHAR(10)
    -- �Ǌ����_
    ,head_sales_branch                xxwsh_order_headers_all.head_sales_branch%TYPE
    -- �Ǌ����_�i���́j
    ,head_sales_branch_name           xxcmn_cust_accounts2_v.party_short_name%TYPE
    -- �o�Ɍ`��
    ,transaction_type_name            xxwsh_oe_transaction_types2_v.transaction_type_name%TYPE
    -- ���ڌ�No
    ,mixed_no                         xxwsh_order_headers_all.mixed_no%TYPE
    -- �p���b�g�������
    ,collected_pallet_qty             xxwsh_order_headers_all.collected_pallet_qty%TYPE
    -- PO#
    ,cust_po_number                   xxwsh_order_headers_all.cust_po_number%TYPE
    -- �z����/���ɐ�i�R�[�h�j
    ,deliver_to_code                  xxwsh_order_headers_all.deliver_to%TYPE
    -- �z����/���ɐ�i���́j
    ,deliver_to_name                  xxcmn_cust_acct_sites2_v.party_site_full_name%TYPE
    -- �_��O�^���敪
    ,keyaku_gai_freight_charge_kbn    xxcmn_lookup_values2_v.meaning%TYPE
    -- �U�֐敔��
    ,frkae_busho_name                 xxcmn_locations2_v.location_short_name%TYPE
    -- �m�F�˗�
    ,check_irai_kbn                   xxcmn_lookup_values2_v.meaning%TYPE
    -- �E�v
    ,tekiyou                          xxwsh_order_headers_all.shipping_instructions%TYPE
    -- ���׎���FROM
    ,arrival_time_from                xxwsh_order_headers_all.arrival_time_from%TYPE
    -- ���׎���TO
    ,arrival_time_to                  xxwsh_order_headers_all.arrival_time_to%TYPE
    -- �S���҃R�[�h
    ,tanto_code                       per_all_people_f.employee_number%TYPE
    -- ��ʍX�V����
    ,screen_update_date               xxwsh_order_headers_all.screen_update_date%TYPE
    -- ���הԍ�
    ,meisai_number                    xxwsh_order_lines_all.order_line_number%TYPE
    -- �i���i�R�[�h�j
    ,item_code                        xxwsh_order_lines_all.shipping_item_code%TYPE
    -- �i���i���́j
    ,item_name                        xxcmn_item_mst2_v.item_short_name%TYPE
    -- �˗�����
    ,request_quantity                 xxwsh_order_lines_all.based_request_quantity%TYPE
    -- �˗�����_�P��
    ,request_quantity_unit            xxcmn_item_mst2_v.conv_unit%TYPE
    -- ����
    ,quantity                         xxwsh_order_lines_all.quantity%TYPE
    -- �p���b�g����
    ,pallet_quantity                  xxwsh_order_lines_all.pallet_quantity%TYPE
    -- �i��
    ,layer_quantity                   xxwsh_order_lines_all.layer_quantity%TYPE
    -- �P�[�X��
    ,case_quantity                    xxwsh_order_lines_all.case_quantity%TYPE
    -- ������
    ,make_date                        ic_lots_mst.attribute1%TYPE
    -- �ܖ�����
    ,shomi_kigen                      ic_lots_mst.attribute3%TYPE
    -- �ŗL�L��
    ,koyu_kigou                       ic_lots_mst.attribute2%TYPE
    -- ���b�gNo
    ,lot_no                           xxinv_mov_lot_details.lot_no%TYPE
    -- �i��
    ,lot_status_name                  xxcmn_lookup_values2_v.meaning%TYPE
    -- ���b�g��������
    ,actual_quantity                  xxinv_mov_lot_details.actual_quantity%TYPE
    -- �x��
    ,warrning_name                    xxcmn_lookup_values2_v.meaning%TYPE
    -- �p���b�g���v����
    ,pallet_sum_quantity              xxwsh_order_headers_all.pallet_sum_quantity%TYPE
    -- �˗��d�ʑ̐ύ��v
    ,req_weight_volume_total          NUMBER
    -- �˗��d�ʑ̐ρi�P�ʁj
    ,req_weight_volume_unit           VARCHAR(10)
    -- �ύڌ���
    ,loading_efficiency               NUMBER
    -- �����敪
    ,reserved_kbn                     xxcmn_lookup_values2_v.meaning%TYPE
-- 2008/07/02 A.Shiina v1.5 ADD Start
    -- �^���敪(�R�[�h)
    ,freight_charge_code              xxcmn_lookup_values2_v.lookup_code%TYPE
    -- �����o�͋敪
    ,complusion_output_kbn            xxcmn_carriers2_v.complusion_output_code%TYPE
-- 2008/07/02 A.Shiina v1.5 ADD End
-- 2008/09/25 Y.Yamamoto v1.8 ADD Start
    -- ���b�gID
    ,lot_id                       ic_lots_mst.lot_id%TYPE
    -- �i�ڋ敪
    ,item_class_code            xxcmn_item_categories5_v.item_class_code%TYPE
-- 2008/09/25 Y.Yamamoto v1.8 ADD End
  );
  TYPE type_report_data_tbl IS TABLE OF type_report_data_rec INDEX BY PLS_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gr_param              rec_param_data ;        -- ���̓p�����[�^���
--
  -- �v���t�@�C���l�擾���ʊi�[�p
  gv_weight_uom         VARCHAR2(3);            -- �o�׏d�ʒP��
  gv_capacity_uom       VARCHAR2(3);            -- �o�חe�ϒP��
  gv_prod_kbn           VARCHAR2(1);            -- ���i�敪
--
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
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
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
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_chohyo_info>' ) ;
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
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_chohyo_info>' ) ;
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
--
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- �f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_chohyo_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ----------------------------
    -- ���b�Z�[�W�o�̓^�O
    -- ----------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'msg';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_msg( gv_application_cmn
                                                                        ,gv_msg_not_data_found ) ;
--
    -- -----------------------------------------------------
    -- �����f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_chohyo_info' ;
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
      it_report_data    IN  type_report_data_tbl     -- �o�ג����\���
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
    -- �˗�No/�ړ�No�u���C�N�p�ϐ�
    lv_req_mov_no_break             VARCHAR2(20) DEFAULT '*';
    -- �i�ڃu���C�N�p�ϐ�
    lv_item_code_break              VARCHAR2(20) DEFAULT '*';
    -- ���s���t
    ld_now_date                     DATE DEFAULT SYSDATE;
    -- �˗����ʁi���v�j
    ln_request_quantity_total       NUMBER DEFAULT 0;
    -- ���ʁi���v�j
    ln_quantity_total               NUMBER DEFAULT 0;
--
  BEGIN
--
    -- -----------------------------------------------------
    -- �w�b�_�[���G�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_chohyo_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- �y�f�[�^�z���[ID
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
--
    -- �y�f�[�^�z�o�͓��t
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_time';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ld_now_date, gv_date_fmt_all);
--
    -- �y�f�[�^�z�S���i�����j
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_busho_name';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := SUBSTRB(xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID), 1, 10);
--
    -- �y�f�[�^�z�S���i�����j
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_name';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := SUBSTRB(xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID), 1, 14);
--
    -- �y�f�[�^�z���͓���FROM
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'input_time_from';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(FND_DATE.STRING_TO_DATE( gr_param.input_date_time_from
                                         ,gv_date_fmt_ymdhm)
                                         ,gv_date_fmt_ymdhm_ja);
--
    -- �y�f�[�^�z���͓���TO
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'input_time_to';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(FND_DATE.STRING_TO_DATE( gr_param.input_date_time_to
                                         ,gv_date_fmt_ymdhm)
                                         ,gv_date_fmt_ymdhm_ja);
--
    -- -----------------------------------------------------
    -- ���׏��LG�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- �o�Ɏw���m�F�\���[�v
    -- -----------------------------------------------------
    <<report_data_loop>>
    FOR l_cnt IN 1..it_report_data.COUNT LOOP
--
      -- �u���C�N����
      IF (lv_req_mov_no_break <> it_report_data(l_cnt).req_mov_no) THEN
--
        -- -----------------------------------------------------
        -- ���׏��f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- �y�f�[�^�z�˗�No/�ړ�No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'req_mov_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).req_mov_no ;
--
        -- �y�f�[�^�z�z��No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).delivery_no;
--
        -- �y�f�[�^�z�o�ɓ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'schedule_ship_date';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
          := TO_CHAR(it_report_data(l_cnt).schedule_ship_date, gv_date_fmt_ymd);
--
        -- �y�f�[�^�z����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'schedule_arrival_date';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
          := TO_CHAR(it_report_data(l_cnt).schedule_arrival_date, gv_date_fmt_ymd);
--
        -- �y�f�[�^�z�o�Ɍ��i�R�[�h�j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).deliver_from_code;
--
        -- �y�f�[�^�z�o�Ɍ��i���́j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).deliver_from_name;
--
        -- �y�f�[�^�z�z���敪�i�R�[�h�j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipping_method_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).shipping_method_code;
--
        -- �y�f�[�^�z�z���敪�i���́j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'shipping_method_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).shipping_method_name;
--
-- 2008/07/02 A.Shiina v1.5 Update Start
   -- �^���敪�������́A�����o�͋敪���u�Ώہv�̂Ƃ��ɁA�^����Џ����o�͂���B
   IF  (it_report_data(l_cnt).freight_charge_code   = '1')
    OR (it_report_data(l_cnt).complusion_output_kbn = '1') THEN
        -- �y�f�[�^�z�^���Ǝҁi�R�[�h�j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_carrier_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).freight_carrier_code;
--
        -- �y�f�[�^�z�^���Ǝҁi���́j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_carrier_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).freight_carrier_name;
   END IF;
-- 2008/07/02 A.Shiina v1.5 Update End
--
        -- �y�f�[�^�z�^���敪�i���́j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_charge_kbn';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).freight_charge_kbn;
--
        -- �y�f�[�^�z�Ɩ����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'gyoumu_shubetsu';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).gyoumu_shubetsu;
--
        -- �y�f�[�^�z�Ǌ����_�i�R�[�h�j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'head_sales_branch';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).head_sales_branch;
--
        -- �y�f�[�^�z�Ǌ����_�i���́j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'head_sales_branch_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).head_sales_branch_name;
--
        -- �y�f�[�^�z�o�Ɍ`��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'transaction_type_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).transaction_type_name;
--
        -- �y�f�[�^�z���ڌ�No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'mixed_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).mixed_no;
--
        -- �y�f�[�^�z�p���b�g�������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'collected_pallet_qty';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).collected_pallet_qty;
--
        -- �y�f�[�^�zPO#
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'cust_po_number';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).cust_po_number;
--
        -- �y�f�[�^�z�z����/���ɐ�i�R�[�h�j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'haisou_nyuko_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).deliver_to_code;
--
        -- �y�f�[�^�z�z����/���ɐ�i���́j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'haisou_nyuko_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).deliver_to_name;
--
        -- �y�f�[�^�z�_��O�^���敪
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_charge_kbn_gai';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
          := it_report_data(l_cnt).keyaku_gai_freight_charge_kbn;
--
        -- �y�f�[�^�z�U�֐敔��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'frkae_busho_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).frkae_busho_name ;
--
        -- �y�f�[�^�z�m�F�˗�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'check_irai_kbn';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).check_irai_kbn;
--
        -- �y�f�[�^�z�E�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tekiyou';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).tekiyou;
--
        -- �y�f�[�^�z���Ԏw��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_time';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
          :=    it_report_data(l_cnt).arrival_time_from
             || '-'
             || it_report_data(l_cnt).arrival_time_to;
--
        -- �y�f�[�^�z�S���҃R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tanto_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).tanto_code;
--
        -- -----------------------------------------------------
        -- ���׏ڍ׏��f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- �u���C�N�L�[�X�V
        lv_req_mov_no_break := it_report_data(l_cnt).req_mov_no;
--
      END IF;
--
      -- -----------------------------------------------------
      -- ���׏ڍ׏��f�[�^�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      IF (lv_item_code_break <> it_report_data(l_cnt).item_code) THEN
--
        -- �y�f�[�^�z�i���i�R�[�h�j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).item_code ;
--
        -- �y�f�[�^�z�i���i���́j
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).item_name;
--
        -- �y�f�[�^�z�˗�����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_quantity';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).request_quantity;
--
        -- �y�f�[�^�z�˗����ʒP��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_quantity_unit';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.5
--        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).request_quantity_unit;
        IF (it_report_data(l_cnt).request_quantity IS NOT NULL) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).request_quantity_unit;
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
        END IF;
--mod end 1.5
--
        IF (it_report_data(l_cnt).request_quantity = it_report_data(l_cnt).quantity) THEN
          NULL;
        ELSIF ((it_report_data(l_cnt).request_quantity IS NULL) AND
               (it_report_data(l_cnt).quantity IS NULL)) THEN
          NULL;
        ELSE
          -- �y�f�[�^�z����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quantity';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).quantity;
--
          -- �y�f�[�^�z���ʒP��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quantity_unit';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.5
--          gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).request_quantity_unit;
          IF (it_report_data(l_cnt).quantity IS NOT NULL) THEN
            gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).request_quantity_unit;
          ELSE
            gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          END IF;
--mod end 1.5
--
        END IF;
--
        -- �y�f�[�^�z�p���b�g����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pallet_quantity';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).pallet_quantity;
--
        -- �y�f�[�^�z�i��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'layer_quantity';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).layer_quantity;
--
        -- �y�f�[�^�z�P�[�X��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'case_quantity';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).case_quantity;
--
        -- -----------------------------------------------------
        -- ���v�l�Z�o
        -- -----------------------------------------------------
        -- �˗����ʁi���v�j
        ln_request_quantity_total
                      := ln_request_quantity_total + it_report_data(l_cnt).request_quantity;
        -- ���ʁi���v�j
        ln_quantity_total
                      := ln_quantity_total + it_report_data(l_cnt).quantity;
--
        -- �u���C�N�L�[�X�V
        lv_item_code_break := it_report_data(l_cnt).item_code;
--
      END IF;
--
      -- �y�f�[�^�z������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'make_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).make_date ;
--
      -- �y�f�[�^�z�ܖ�����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'shomi_kigen';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).shomi_kigen;
--
      -- �y�f�[�^�z�ŗL�L��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'koyu_kigou';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).koyu_kigou;
--
      -- �y�f�[�^�z���b�gNo
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).lot_no;
--
      -- �y�f�[�^�z�i��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_status_name';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).lot_status_name;
--
      -- �y�f�[�^�z���b�g��������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'actual_quantity';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).actual_quantity;
--
      -- �y�f�[�^�z�����敪
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'reserved_kbn';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).reserved_kbn;
--
      -- �y�f�[�^�z�x��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'warrning';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).warrning_name;
--
      -- -----------------------------------------------------
      -- ���׏ڍ׏��f�[�^�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- -----------------------------------------------------
      -- �t�b�^�[���^�O�o��
      -- -----------------------------------------------------
      -- �ŏI���R�[�h�܂��́A�����R�[�h���u���C�N����ꍇ
      IF (   l_cnt = it_report_data.COUNT
          OR lv_req_mov_no_break <> it_report_data(l_cnt + 1).req_mov_no) THEN
--
        --------------------------------------------------------
        -- ���׏ڍ׏��k�f�I���^�O
        --------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        --------------------------------------------------------
        -- �t�b�^�[���LG�J�n�^�O
        --------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_total_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        --------------------------------------------------------
        -- �t�b�^�[���G�J�n�^�O
        --------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl_total_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        --------------------------------------------------------
        -- �t�b�^�[���o��
        --------------------------------------------------------
        -- �y�f�[�^�z�˗����ʍ��v�i�˗�No�P�ʁj
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_quantity_total' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := ln_request_quantity_total ;
--
        -- �y�f�[�^�z���ʍ��v�i�˗�No�P�ʁj
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quantity_total' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := ln_quantity_total ;
--
        -- �y�f�[�^�z�p���b�g�����i�˗�No�P�ʁj
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pallet_quantity_total' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).pallet_sum_quantity ;
--
        -- �y�f�[�^�z�˗��d�ʑ̐ύ��v�i�˗�No�P�ʁj
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'req_weight_volume_total' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).req_weight_volume_total ;
--
        -- �y�f�[�^�z�˗��d�ʑ̐ϒP�ʁi�˗�No�P�ʁj
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'req_weight_volume_unit' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.5
--        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).req_weight_volume_unit ;
        IF (it_report_data(l_cnt).req_weight_volume_total IS NOT NULL) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).req_weight_volume_unit ;
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
        END IF;
--mod end 1.5
--
        -- �y�f�[�^�z�ύڌ����i�˗�No�P�ʁj
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'loading_efficiency' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_report_data(l_cnt).loading_efficiency ;
--
        --------------------------------------------------------
        -- �t�b�^�[���G�I���^�O
        --------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl_total_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        --------------------------------------------------------
        -- �t�b�^�[���LG�I���^�O
        --------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_total_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        --------------------------------------------------------
        -- ���׏��G�I���^�O
        --------------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- �N���A����
        -- -----------------------------------------------------
        -- �i�ڃu���C�N�L�[
        lv_item_code_break                  := '*';
        -- �˗����ʍ��v
        ln_request_quantity_total           := 0;
        -- ���ʍ��v
        ln_quantity_total                   := 0;
--
      END IF;
--
    END LOOP report_data_loop;
--
    -- -----------------------------------------------------
    -- ���׏��LG�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- ���[���G�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_chohyo_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
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
   * Procedure Name   : prc_get_report_data
   * Description      : ���[���擾����
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ot_report_data  OUT NOCOPY type_report_data_tbl    -- �擾���R�[�h
     ,ov_errbuf       OUT NOCOPY VARCHAR2                -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      OUT NOCOPY VARCHAR2                -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- �v���O������
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
    lv_select          VARCHAR2(32000) DEFAULT NULL;
    lv_ship_select     VARCHAR2(32000) DEFAULT NULL;
    lv_ship_from       VARCHAR2(32000) DEFAULT NULL;
    lv_ship_where      VARCHAR2(32000) DEFAULT NULL;
    lv_move_select     VARCHAR2(32000) DEFAULT NULL;
    lv_move_from       VARCHAR2(32000) DEFAULT NULL;
    lv_move_where      VARCHAR2(32000) DEFAULT NULL;
    lv_order_by        VARCHAR2(32000) DEFAULT NULL;
    lv_sql             VARCHAR2(32000) DEFAULT NULL;
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
    -- SQL������
    -- ====================================================
    -- ----------------------------------------------------
    -- SELECT�吶��
    -- ----------------------------------------------------
    lv_select := ' SELECT '
    || '  req_mov_no '                      -- �˗�No/�ړ�No
    || ' ,delivery_no '                     -- �z��No
    || ' ,schedule_ship_date '              -- �o�ɓ�
    || ' ,schedule_arrival_date '           -- ����
    || ' ,deliver_from_code '               -- �o�Ɍ��i�R�[�h�j
    || ' ,deliver_from_name '               -- �o�Ɍ��i���́j
    || ' ,shipping_method_code '            -- �z���敪
    || ' ,shipping_method_name '            -- �z���敪�i���́j
    || ' ,freight_carrier_code '            -- �^���Ǝ�
    || ' ,freight_carrier_name '            -- �^���Ǝҁi���́j
    || ' ,freight_charge_kbn '              -- �^���敪
    || ' ,gyoumu_shubetsu '                 -- �Ɩ����
    || ' ,head_sales_branch '               -- �Ǌ����_
    || ' ,head_sales_branch_name '          -- �Ǌ����_�i���́j
    || ' ,transaction_type_name '           -- �o�Ɍ`��
    || ' ,mixed_no '                        -- ���ڌ�No
    || ' ,collected_pallet_qty '            -- �p���b�g�������
    || ' ,cust_po_number '                  -- PO#
    || ' ,deliver_to_code '                 -- �z����/���ɐ�i�R�[�h�j
    || ' ,deliver_to_name '                 -- �z����/���ɐ�i���́j
    || ' ,keyaku_gai_freight_charge_kbn '   -- �_��O�^���敪
    || ' ,frkae_busho_name '                -- �U�֐敔��
    || ' ,check_irai_kbn '                  -- �m�F�˗�
    || ' ,tekiyou '                         -- �E�v
    || ' ,arrival_time_from '               -- ���׎���FROM
    || ' ,arrival_time_to '                 -- ���׎���TO
    || ' ,tanto_code '                      -- �S���҃R�[�h
    || ' ,screen_update_date '              -- ��ʍX�V����
    || ' ,meisai_number '                   -- ���הԍ�
    || ' ,item_code '                       -- �i���i�R�[�h�j
    || ' ,item_name '                       -- �i���i���́j
    || ' ,request_quantity '                -- �˗�����
    || ' ,request_quantity_unit '           -- �˗�����_�P��
    || ' ,quantity '                        -- ����
    || ' ,pallet_quantity '                 -- �p���b�g����
    || ' ,layer_quantity '                  -- �i��
    || ' ,case_quantity '                   -- �P�[�X��
    || ' ,make_date '                       -- ������
    || ' ,shomi_kigen '                     -- �ܖ�����
    || ' ,koyu_kigou '                      -- �ŗL�L��
    || ' ,lot_no '                          -- ���b�gNo
    || ' ,lot_status_name '                 -- �i��
    || ' ,actual_quantity '                 -- ���b�g��������
    || ' ,warrning_name '                   -- �x��
    || ' ,pallet_sum_quantity '             -- �p���b�g���v����
    || ' ,req_weight_volume_total '         -- �˗��d�ʑ̐ύ��v
    || ' ,req_weight_volume_unit '          -- �˗��d�ʑ̐ρi�P�ʁj
    || ' ,loading_efficiency '              -- �ύڌ���
    || ' ,reserved_kbn '                    -- �����敪
-- 2008/07/02 A.Shiina v1.5 ADD Start
    || ' ,freight_charge_code '             -- �^���敪(�R�[�h)
    || ' ,complusion_output_kbn '           -- �����o�͋敪
-- 2008/07/02 A.Shiina v1.5 ADD End
-- 2008/09/25 Y.Yamamoto v1.8 ADD Start
    || ' ,lot_id '                          -- ���b�gID
    || ' ,item_class_code '                 -- �i�ڋ敪
-- 2008/09/25 Y.Yamamoto v1.8 ADD End
    ;
--
    IF ( gr_param.gyoumu_kbn = gv_biz_type_cd_ship OR gr_param.gyoumu_kbn IS NULL ) THEN
      -- ================================================================================
      -- �y�o�ׁzSELECT�吶��
      -- ================================================================================
      lv_ship_select := ' SELECT '
      || '  xoha.request_no                  AS  req_mov_no'              -- �˗�No/�ړ�No
      || ' ,xoha.delivery_no                 AS  delivery_no'             -- �z��No
      || ' ,xoha.schedule_ship_date          AS  schedule_ship_date'      -- �o�ɓ�
      || ' ,xoha.schedule_arrival_date       AS  schedule_arrival_date'   -- ����
      || ' ,xoha.deliver_from                AS  deliver_from_code'       -- �o�Ɍ��i�R�[�h�j
      || ' ,xil2v.description                AS  deliver_from_name'       -- �o�Ɍ��i���́j
      || ' ,xoha.shipping_method_code        AS  shipping_method_code'    -- �z���敪
      || ' ,xsm2v.ship_method_meaning        AS  shipping_method_name'    -- �z���敪�i���́j
      || ' ,xoha.freight_carrier_code        AS  freight_carrier_code'    -- �^���Ǝ�
      || ' ,xc2v.party_short_name            AS  freight_carrier_name'    -- �^���Ǝҁi���́j
      || ' ,xlv2v1.meaning                   AS  freight_charge_kbn'      -- �^���敪
      || ' ,''' || gv_biz_type_nm_ship || '''AS  gyoumu_shubetsu'         -- �Ɩ����
      || ' ,xoha.head_sales_branch           AS  head_sales_branch'       -- �Ǌ����_
      || ' ,xca2v.party_short_name           AS  head_sales_branch_name'  -- �Ǌ����_�i���́j
      || ' ,xott2v.transaction_type_name     AS  transaction_type_name'   -- �o�Ɍ`��
      || ' ,xoha.mixed_no                    AS  mixed_no'                -- ���ڌ�No
      || ' ,xoha.collected_pallet_qty        AS  collected_pallet_qty'    -- �p���b�g�������
      || ' ,xoha.cust_po_number              AS  cust_po_number'          -- PO#
      || ' ,xoha.deliver_to                  AS  deliver_to_code'         -- �z����/���ɐ�(�R�[�h)
      || ' ,xcas2v.party_site_full_name      AS  deliver_to_name'         -- �z����/���ɐ�i���́j
      || ' ,xlv2v2.meaning                   AS  keyaku_gai_freight_charge_kbn'   -- �_��O�^���敪
      || ' ,CASE'
      || '    WHEN xoha.no_cont_freight_class = ''' || gv_no_cont_freight_kbn_obj || ''' THEN'
      || '      xl2v.location_short_name'
      || '    ELSE'
      || '      NULL'
      || '    END                            AS  frkae_busho_name'        -- �U�֐敔��
      || ' ,xlv2v3.meaning                   AS  check_irai_kbn'          -- �m�F�˗�
      || ' ,xoha.shipping_instructions       AS  tekiyou'                 -- �E�v
      || ' ,xoha.arrival_time_from           AS  arrival_time_from'       -- ���׎���FROM
      || ' ,xoha.arrival_time_to             AS  arrival_time_to'         -- ���׎���TO
      || ' ,papf.employee_number             AS  tanto_code'              -- �S���҃R�[�h
      || ' ,xoha.screen_update_date          AS  screen_update_date'      -- ��ʍX�V����
      || ' ,xola.order_line_number           AS  meisai_number'           -- ���הԍ�
      || ' ,xola.shipping_item_code          AS  item_code'               -- �i���i�R�[�h�j
      || ' ,xim2v.item_short_name            AS  item_name'               -- �i���i���́j
      || ' ,CASE'
      || '    WHEN  ( ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '    AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '      TRUNC(xola.based_request_quantity / TO_NUMBER('
      || '                                        CASE'
      || '                                          WHEN ( xim2v.num_of_cases > 0 ) THEN'
      || '                                            xim2v.num_of_cases'
      || '                                          ELSE'
      || '                                            TO_CHAR(1)'
      || '                                        END'
      || '                                      ), 3)'
      || '    ELSE'
      || '      xola.based_request_quantity'
      || '    END                              AS  request_quantity'      -- �˗�����
      || ' ,CASE'
      || '    WHEN  ( ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '    AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '      xim2v.conv_unit'
      || '    ELSE'
      || '      xim2v.item_um'
      || '    END                            AS  request_quantity_unit'   -- �˗�����_�P��
      || ' ,CASE'
      || '    WHEN  ( ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '    AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '      TRUNC(xola.quantity / TO_NUMBER('
      || '                                        CASE'
      || '                                          WHEN ( xim2v.num_of_cases > 0 ) THEN'
      || '                                            xim2v.num_of_cases'
      || '                                          ELSE'
      || '                                            TO_CHAR(1)'
      || '                                        END'
      || '                                      ), 3)'
      || '    ELSE'
      || '      xola.quantity'
      || '    END                            AS  quantity'                 -- ����
      || ' ,xola.pallet_quantity             AS  pallet_quantity'          -- �p���b�g����
      || ' ,xola.layer_quantity              AS  layer_quantity'           -- �i��
      || ' ,xola.case_quantity               AS  case_quantity'            -- �P�[�X��
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      TO_CHAR(xola.designated_production_date, ''' || gv_date_fmt_ymd || ''')'
      || '    ELSE'
      || '      ilm.attribute1'
      || '    END                            AS  make_date'               -- ������
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      NULL'
      || '    ELSE'
      || '      ilm.attribute3'
      || '    END                            AS  shomi_kigen'             -- �ܖ�����
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      NULL'
      || '    ELSE'
      || '      ilm.attribute2'
      || '    END                            AS  koyu_kigou'              -- �ŗL�L��
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      NULL'
      || '    ELSE'
      || '      xmld.lot_no'
      || '    END                            AS  lot_no'                  -- ���b�gNo
      || ' ,xlv2v4.meaning                   AS  lot_status_name'         -- �i��
      || ' ,CASE'
              -- ��������Ă���ꍇ
      || '    WHEN ( xola.reserved_quantity > 0 ) THEN'
      || '      CASE'
      || '        WHEN  ( ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '        AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '          TRUNC(xmld.actual_quantity / TO_NUMBER('
      || '                                            CASE'
      || '                                              WHEN ( xim2v.num_of_cases > 0 ) THEN'
      || '                                                xim2v.num_of_cases'
      || '                                              ELSE'
      || '                                                TO_CHAR(1)'
      || '                                            END'
      || '                                          ), 3)'
      || '        ELSE'
      || '          xmld.actual_quantity'
      || '        END'
              -- ��������Ă��Ȃ��ꍇ
      || '    WHEN  ( ( xola.reserved_quantity IS NULL ) OR ( xola.reserved_quantity = 0 ) ) THEN'
      || '      NULL'
      || '    END                            AS  actual_quantity'         -- ���b�g��������
      || ' ,xlv2v5.meaning                   AS  warrning_name'           -- �x��
      || ' ,xoha.pallet_sum_quantity         AS  pallet_sum_quantity'     -- �p���b�g���v����
      || ' ,CASE'
      || '    WHEN xsm2v.small_amount_class = ''' || gv_small_kbn_obj || ''' THEN'
      || '      CASE'
      || '        WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''''
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '        THEN xoha.sum_weight'
      || '        THEN CEIL(TRUNC(xoha.sum_weight,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '        WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''''
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '        THEN xoha.sum_capacity'
      || '        THEN CEIL(TRUNC(xoha.sum_capacity,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '      END'
      || '    WHEN xsm2v.small_amount_class = ''' || gv_small_kbn_not_obj || ''' THEN'
      || '      CASE'
      || '        WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''' THEN'
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '          xoha.sum_pallet_weight + xoha.sum_weight'
      || '          CEIL(TRUNC(xoha.sum_pallet_weight + xoha.sum_weight,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '        WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''' THEN'
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '          xoha.sum_pallet_weight + xoha.sum_capacity'
      || '          CEIL(TRUNC(xoha.sum_pallet_weight + xoha.sum_capacity,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '      END'
      || '    WHEN xsm2v.small_amount_class IS NULL THEN'
      || '      NULL '
      || '    END                            AS  req_weight_volume_total' -- �˗��d�ʑ̐ρi���v�j
      || ' ,CASE'
      || '    WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''''
      || '    THEN ''' || gv_weight_uom || ''''
      || '    WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''''
      || '    THEN ''' || gv_capacity_uom || ''''
      || '    END                            AS  req_weight_volume_unit'  -- �˗��d�ʑ̐ρi�P�ʁj
      || ' ,CASE'
      || '    WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''''
      || '    THEN xoha.loading_efficiency_weight'
      || '    WHEN xoha.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''''
      || '    THEN xoha.loading_efficiency_capacity'
      || '    END                            AS  loading_efficiency'      -- �ύڌ���
      || ' ,xlv2v6.attribute1                AS  reserved_kbn'            -- �����敪
-- 2008/07/02 A.Shiina v1.5 ADD Start
      || ' ,xlv2v1.lookup_code               AS  freight_charge_code'     -- �^���敪(�R�[�h)
      || ' ,xc2v.complusion_output_code      AS  complusion_output_kbn'   -- �����o�͋敪
-- 2008/07/02 A.Shiina v1.5 ADD End
-- 2008/09/25 Y.Yamamoto v1.8 ADD Start
      || ' ,NVL(ilm.lot_id, 0)               AS  lot_id '                 -- ���b�gID
      || ' ,xic4v.item_class_code            AS  item_class_code'         -- �i�ڋ敪
-- 2008/09/25 Y.Yamamoto v1.8 ADD End
      ;
--
      -- ================================================================================
      -- �y�o�ׁzFROM�吶��
      -- ================================================================================
      lv_ship_from := ' FROM '
      || '  xxwsh_order_headers_all           xoha'       -- �󒍃w�b�_�A�h�I��
      || ' ,xxwsh_oe_transaction_types2_v     xott2v'     -- �󒍃^�C�v���VIEW2
      || ' ,xxcmn_item_locations2_v           xil2v'      -- OPM�ۊǏꏊ���VIEW2
      || ' ,xxcmn_carriers2_v                 xc2v'       -- �^���Ǝҏ��VIEW2
      || ' ,xxcmn_cust_accounts2_v            xca2v'      -- �ڋq���VIEW2
      || ' ,xxcmn_cust_acct_sites2_v          xcas2v'     -- �ڋq�T�C�g���VIEW2
      || ' ,fnd_user                          fu'         -- ���[�U�[�}�X�^
      || ' ,per_all_people_f                  papf'       -- �]�ƈ��}�X�^
      || ' ,xxcmn_locations2_v                xl2v'       -- ���Ə����VIEW2
      || ' ,xxwsh_order_lines_all             xola'       -- �󒍖��׃A�h�I��
      || ' ,xxcmn_item_mst2_v                 xim2v'      -- OPM�i�ڏ��VIEW2
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || ' ,xxcmn_item_categories4_v          xic4v'      -- OPM�i�ڃJ�e�S���������VIEW4
      || ' ,xxcmn_item_categories5_v          xic4v'      -- OPM�i�ڃJ�e�S���������VIEW5
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || ' ,xxinv_mov_lot_details             xmld'       -- �ړ����b�g�ڍ�(�A�h�I��)
      || ' ,ic_lots_mst                       ilm'        -- OPM���b�g�}�X�^
      || ' ,xxwsh_ship_method2_v              xsm2v'      -- �z���敪���VIEW2
      || ' ,xxcmn_lookup_values2_v            xlv2v1'     -- �N�C�b�N�R�[�h(�^���敪)
      || ' ,xxcmn_lookup_values2_v            xlv2v2'     -- �N�C�b�N�R�[�h(�_��O�^���敪)
      || ' ,xxcmn_lookup_values2_v            xlv2v3'     -- �N�C�b�N�R�[�h(�����S���m�F�˗��敪)
      || ' ,xxcmn_lookup_values2_v            xlv2v4'     -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
      || ' ,xxcmn_lookup_values2_v            xlv2v5'     -- �N�C�b�N�R�[�h(�x���敪)
      || ' ,xxcmn_lookup_values2_v            xlv2v6'     -- �N�C�b�N�R�[�h(�����敪)
      ;
--
      -- ================================================================================
      -- �y�o�ׁzWHERE�吶��
      -- ================================================================================
      lv_ship_where := ' WHERE '
           -------------------------------------------------------------------------------
           -- �󒍃w�b�_�A�h�I��
           -------------------------------------------------------------------------------
      || '     xoha.req_status                   >= ''' || gv_ship_status_close || '''' -- ���ߍς�
      || ' AND xoha.req_status                   <> ''' || gv_ship_status_delete || ''''-- ���
      || ' AND   xoha.latest_external_flag = ''Y'''
-- 2008/11/14 N.Fukuda v1.9 Add Start
      || ' AND   xoha.schedule_ship_date IS NOT NULL'
-- 2008/11/14 N.Fukuda v1.9 Add End
           -------------------------------------------------------------------------------
           -- �󒍃^�C�v���VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xoha.order_type_id               = xott2v.transaction_type_id'
      || ' AND   xott2v.shipping_shikyu_class     = ''' || gv_ship_pro_kbn_s || '''' --'�o�׈˗�'
      || ' AND   xott2v.order_category_code      <> ''' || gv_order_cate_ret || '''' -- �ԕi
      || ' AND   xott2v.start_date_active        <=  xoha.schedule_ship_date'
      || ' AND   ('
      || '         xott2v.end_date_active        >=  xoha.schedule_ship_date'
      || '       OR'
      || '         xott2v.end_date_active IS NULL'
      || '       )'
           -------------------------------------------------------------------------------
           -- OPM�ۊǏꏊ���VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xoha.deliver_from_id               =   xil2v.inventory_location_id'
           -------------------------------------------------------------------------------
           -- �^���Ǝҏ��VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xoha.career_id                     =   xc2v.party_id(+)'
      || ' AND   ('
      || '         xc2v.start_date_active IS NULL'
      || '       OR'
      || '         xc2v.start_date_active          <=  xoha.schedule_ship_date'
      || '       )'
      || ' AND   ('
      || '         xc2v.end_date_active IS NULL'
      || '       OR'
      || '         xc2v.end_date_active            >=  xoha.schedule_ship_date'
      || '       )'
           -------------------------------------------------------------------------------
           -- �ڋq���VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xoha.head_sales_branch              =   xca2v.party_number'
      || ' AND   xca2v.start_date_active            <=  xoha.schedule_ship_date'
      || ' AND   ('
      || '         xca2v.end_date_active            >=  xoha.schedule_ship_date'
      || '       OR'
      || '         xca2v.end_date_active IS NULL'
      || '       )'
           -------------------------------------------------------------------------------
           -- �ڋq�T�C�g���VIEW2
           -------------------------------------------------------------------------------
-- 2009/05/28 H.Itou Mod Start �{�ԏ�Q#1398
--      || ' AND   xoha.deliver_to_id                  =   xcas2v.party_site_id'
      || ' AND   xoha.deliver_to                     =   xcas2v.party_site_number'
-- 2009/05/28 H.Itou Mod End
-- 2009/05/28 H.Itou Add Start �{�ԏ�Q#1398
      || ' AND   xcas2v.party_site_status            = ''A'' '  -- �L���ȏo�א�
      || ' AND   xcas2v.cust_acct_site_status        = ''A'' '  -- �L���ȏo�א�
-- 2009/05/28 H.Itou Add End
      || ' AND   xcas2v.start_date_active           <=  xoha.schedule_ship_date'
      || ' AND   ('
      || '         xcas2v.end_date_active           >=  xoha.schedule_ship_date'
      || '       OR'
      || '         xcas2v.end_date_active IS NULL'
      || '       )'
           -------------------------------------------------------------------------------
           -- ���[�U���
           -------------------------------------------------------------------------------
      || ' AND   xoha.screen_update_by = fu.user_id'
      || ' AND   fu.employee_id = papf.person_id'
-- 2009/09/14 H.Itou Add Start �{�ԏ�Q#1632
      || ' AND   xoha.schedule_ship_date BETWEEN papf.effective_start_date '
      || '                               AND     NVL(papf.effective_end_date,xoha.schedule_ship_date) '
-- 2009/09/14 H.Itou Add End
           -------------------------------------------------------------------------------
           -- ���Ə����VIEW2
           -------------------------------------------------------------------------------
--mod start 1.3
--      || ' AND   xoha.transfer_location_id          = xl2v.location_id'
--      || ' AND   xl2v.start_date_active            <=  xoha.schedule_ship_date'
--      || '     AND   ('
--      || '         xl2v.end_date_active            >=  xoha.schedule_ship_date'
--      || '       OR'
--      || '         xl2v.end_date_active IS NULL'
--      || '       )'
      || ' AND   xoha.transfer_location_id          = xl2v.location_id(+)'
      || ' AND   xoha.schedule_ship_date'
      || '   BETWEEN xl2v.start_date_active(+)'
      || '   AND NVL(xl2v.end_date_active(+),xoha.schedule_ship_date)'
--mod end 1.3
           -------------------------------------------------------------------------------
           -- �󒍖��׃A�h�I��
           -------------------------------------------------------------------------------
      || ' AND   xoha.order_header_id               =   xola.order_header_id'
      || ' AND   (  xola.delete_flag IS NULL'
      || '       OR'
      || '          xola.delete_flag               <>  ''Y'''
      || '       )'
-- 2008/08/05 Y.Yamamoto v1.7 ADD Start
--      || ' AND   xola.quantity                      >   0'     -- 2008/11/14 N.Fukuda v1.9 Del
-- 2008/08/05 Y.Yamamoto v1.7 ADD End
           -------------------------------------------------------------------------------
           -- OPM�i�ڏ��VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xola.shipping_inventory_item_id    =   xim2v.inventory_item_id'
      || ' AND   xim2v.start_date_active   <=  xoha.schedule_ship_date'
      || ' AND   ('
      || '         xim2v.end_date_active IS NULL'
      || '       OR'
      || '         xim2v.end_date_active    >=  xoha.schedule_ship_date'
      || '       )'
           -------------------------------------------------------------------------------
           -- OPM�i�ڃJ�e�S���������VIEW4
           -------------------------------------------------------------------------------
      || ' AND   xim2v.item_id               =   xic4v.item_id'
      || ' AND   xic4v.prod_class_code       =   ''' || gv_prod_kbn || ''''
           -------------------------------------------------------------------------------
           -- �ړ����b�g�ڍ�(�A�h�I��)
           -------------------------------------------------------------------------------
      || ' AND   xola.order_line_id          = xmld.mov_line_id(+)'
      || ' AND   xmld.document_type_code(+)  = ''' || gv_document_type_ship_req || ''''-- �o�׈˗�
      || ' AND   xmld.record_type_code(+)    = ''' || record_type_siji || ''''         -- �w��
           -------------------------------------------------------------------------------
           -- OPM���b�g�}�X�^
           -------------------------------------------------------------------------------
      || ' AND   xmld.lot_id                        =   ilm.lot_id(+)'
      || ' AND   xmld.item_id                       =   ilm.item_id(+)'
           -------------------------------------------------------------------------------
           -- �z���敪���VIEW2
           -------------------------------------------------------------------------------
      || ' AND xoha.shipping_method_code            = xsm2v.ship_method_code(+)'
           -------------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�i�^���敪�j-- 1:�ΏہA2:�ΏۊO
           -------------------------------------------------------------------------------
      || ' AND xlv2v1.lookup_type                   = ''' || gv_lookup_cd_freight || ''''
      || ' AND xoha.freight_charge_class            = xlv2v1.lookup_code'
           -------------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�i�_��O�^���敪�j-- 1:�ΏہA0:�ΏۊO
           -------------------------------------------------------------------------------
      || ' AND xlv2v2.lookup_type                   = ''' || gv_lookup_cd_no_freight || ''''
      || ' AND xoha.no_cont_freight_class           = xlv2v2.lookup_code'
           -------------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�i�����S���m�F�˗��敪�j-- 1:�v�A2:�s�v
           -------------------------------------------------------------------------------
      || ' AND xlv2v3.lookup_type                   = ''' || gv_lookup_cd_conreq || ''''
      || ' AND xoha.confirm_request_class           = xlv2v3.lookup_code'
           -------------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�iۯĽð���j-- 10:������A30:�����t�Ǖi�A50:���i�A60:�s���i�A70:�ۗ�
           -------------------------------------------------------------------------------
      || ' AND xlv2v4.lookup_type(+)                = ''' || gv_lookup_cd_lot_status || ''''
      || ' AND ilm.attribute23                      = xlv2v4.lookup_code(+)'
           -------------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�i�x���敪�j
           -------------------------------------------------------------------------------
      --MOD START 2008/06/04 NAKADA
      || ' AND xlv2v5.lookup_type(+)               = ''' || gv_lookup_cd_warn || ''''
      || ' AND xola.warning_class                  = xlv2v5.lookup_code(+)'
      --MOD END   2008/06/04 NAKADA
           -------------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�i�����敪�j
           -------------------------------------------------------------------------------
      || ' AND xlv2v6.lookup_type(+)               = ''' || gv_lookup_cd_reserve || ''''
      || ' AND xmld.automanual_reserve_class       = xlv2v6.lookup_code(+)'
      ;
--
      -- ���̓p�����[�^�ɂ�����
           -------------------------------------------------------------------------------
           -- �󒍃w�b�_�A�h�I��
           -------------------------------------------------------------------------------
      IF (  gr_param.block1 IS NOT NULL
         OR gr_param.block2 IS NOT NULL
         OR gr_param.block3 IS NOT NULL
         OR gr_param.deliver_from_code IS NOT NULL ) THEN
        lv_ship_where := lv_ship_where
        || ' AND ('
        || '         xil2v.distribution_block IN ('
        || '                                      ''' || gr_param.block1 || ''''
        || '                                     ,''' || gr_param.block2 || ''''
        || '                                     ,''' || gr_param.block3 || ''''
        || '                                     )'                               -- ����P.�u���b�N
        || '       OR'
        || '         xoha.deliver_from = ''' || gr_param.deliver_from_code || ''''-- ����P.�o�Ɍ�'
        || '       )'
        ;
      END IF;
--
      IF (   gr_param.input_date_time_from IS NOT NULL
         AND gr_param.input_date_time_to IS NOT NULL ) THEN
        lv_ship_where := lv_ship_where
        || ' AND   ('
        || '         TRUNC( xoha.screen_update_date, ''' || gv_date_fmt_mi || ''' ) '
        || '           >= FND_DATE.STRING_TO_DATE( ''' || gr_param.input_date_time_from || ''''
        || '                                      ,''' || gv_date_fmt_ymdhm || ''' ) '
        || '       AND'
        || '         TRUNC( xoha.screen_update_date, ''' || gv_date_fmt_mi || ''' ) '
        || '           <= FND_DATE.STRING_TO_DATE( ''' || gr_param.input_date_time_to || ''''
        || '                                      ,''' || gv_date_fmt_ymdhm || ''' ) '
        || '       )'
        ;
      END IF;
--
           -------------------------------------------------------------------------------
           -- ���[�U���
           -------------------------------------------------------------------------------
      IF ( gr_param.tanto_code IS NOT NULL ) THEN
        lv_ship_where := lv_ship_where
        || ' AND papf.employee_number         = ''' || gr_param.tanto_code || ''''
        ;
      END IF;
--
    END IF;
--
    IF ( gr_param.gyoumu_kbn = gv_biz_type_cd_move OR gr_param.gyoumu_kbn IS NULL ) THEN
      -- ================================================================================
      -- �y�ړ��zSELECT�吶��
      -- ================================================================================
      lv_move_select := ' SELECT '
      || '  xmrih.mov_num                         AS  req_mov_no'              -- �˗�No/�ړ�No
      || ' ,xmrih.delivery_no                     AS  delivery_no'             -- �z��No
      || ' ,xmrih.schedule_ship_date              AS  schedule_ship_date'      -- �o�ɓ�
      || ' ,xmrih.schedule_arrival_date           AS  schedule_arrival_date'   -- ����
      || ' ,xmrih.shipped_locat_code              AS  deliver_from_code'       -- �o�Ɍ��i�R�[�h�j
      || ' ,xil2v1.description                    AS  deliver_from_name'       -- �o�Ɍ��i���́j
      || ' ,xmrih.shipping_method_code            AS  shipping_method_code'    -- �z���敪(�R�[�h)
      || ' ,xsm2v.ship_method_meaning             AS  shipping_method_name'    -- �z���敪�i���́j
      || ' ,xmrih.freight_carrier_code            AS  freight_carrier_code'    -- �^���Ǝ�(�R�[�h)
      || ' ,xc2v.party_short_name                 AS  freight_carrier_name'    -- �^���Ǝҁi���́j
      || ' ,xlv2v1.meaning                        AS  freight_charge_kbn'      -- �^���敪�i���́j
      || ' ,''' || gv_biz_type_nm_move || '''     AS  gyoumu_shubetsu'         -- �Ɩ����
      || ' ,NULL                                  AS  head_sales_branch'       -- �Ǌ����_(�R�[�h)
      || ' ,NULL                                  AS  head_sales_branch_name'  -- �Ǌ����_�i���́j
      || ' ,xlv2v2.meaning                        AS  transaction_type_name'   -- �o�Ɍ`��
      || ' ,NULL                                  AS  mixed_no'                -- ���ڌ�No
      || ' ,xmrih.collected_pallet_qty            AS  collected_pallet_qty'    -- �p���b�g�������
      || ' ,NULL                                  AS  cust_po_number'          -- PO#
      || ' ,xmrih.ship_to_locat_code              AS  deliver_to_code'   -- �z����/���ɐ�i�R�[�h�j
      || ' ,xil2v2.description                    AS  deliver_to_name'   -- �z����/���ɐ�i���́j
      || ' ,CASE'
      || '    WHEN (xmrih.no_cont_freight_class = ''' || gv_no_cont_freight_kbn_obj || ''' ) THEN'
      || '      xlv2v3.meaning'
      || '    ELSE'
      || '      NULL'
      || '    END                               AS  keyaku_gai_freight_charge_kbn'-- �_��O�^���敪
      || ' ,NULL                                  AS  frkae_busho_name'        -- �U�֐敔��
      || ' ,NULL                                  AS  check_irai_kbn'          -- �m�F�˗�
      || ' ,xmrih.description                     AS  tekiyou'                 -- �E�v
      || ' ,xmrih.arrival_time_from               AS  arrival_time_from'       -- ���׎���FROM
      || ' ,xmrih.arrival_time_to                 AS  arrival_time_to'         -- ���׎���TO
      || ' ,papf.employee_number                  AS  tanto_code'              -- �S���҃R�[�h
      || ' ,xmrih.screen_update_date              AS  screen_update_date'      -- ��ʍX�V����
      || ' ,xmril.line_number                     AS  meisai_number'           -- ���הԍ�
      || ' ,xmril.item_code                       AS  item_code'               -- �i���i�R�[�h�j
      || ' ,xim2v.item_short_name                 AS  item_name'               -- �i���i���́j
      || ' ,CASE'
      || '    WHEN  (   ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '          AND ( xic4v.prod_class_code  = ''' || gv_prod_cd_drink || ''' )'
      || '          AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
-- 2008/09/25 Y.Yamamoto v1.8 Update Start
--      || '      TRUNC(xmril.request_qty / TO_NUMBER('
      || '      TRUNC(xmril.first_instruct_qty / TO_NUMBER('
-- 2008/09/25 Y.Yamamoto v1.8 Update End
      || '                                        CASE'
      || '                                          WHEN ( xim2v.num_of_cases > 0 ) THEN'
      || '                                            xim2v.num_of_cases'
      || '                                          ELSE'
      || '                                            TO_CHAR(1)'
      || '                                        END'
      || '                                      ), 3)'
      || '    ELSE'
-- 2008/09/29 Y.Yamamoto v1.8 Update Start
--      || '      xmril.request_qty'
      || '      xmril.first_instruct_qty'
-- 2008/09/29 Y.Yamamoto v1.8 Update End
      || '    END                                 AS  request_quantity'        -- �˗�����
      || ' ,CASE'
      || '    WHEN  (   ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '          AND ( xic4v.prod_class_code  = ''' || gv_prod_cd_drink || ''' )'
      || '          AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '      xim2v.conv_unit'
      || '    ELSE'
      || '      xim2v.item_um'
      || '    END                                 AS  request_quantity_unit'   -- �˗�����_�P��
      || ' ,CASE'
      || '    WHEN  (   ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '          AND ( xic4v.prod_class_code  = ''' || gv_prod_cd_drink || ''' )'
      || '          AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '      TRUNC(xmril.instruct_qty / TO_NUMBER('
      || '                                        CASE'
      || '                                          WHEN ( xim2v.num_of_cases > 0 ) THEN'
      || '                                            xim2v.num_of_cases'
      || '                                          ELSE'
      || '                                            TO_CHAR(1)'
      || '                                        END'
      || '                                      ), 3)'
      || '    ELSE'
      || '      xmril.instruct_qty'
      || '    END                                 AS  quantity'                -- ����
      || ' ,xmril.pallet_quantity                 AS  pallet_quantity'         -- �p���b�g����
      || ' ,xmril.layer_quantity                  AS  layer_quantity'          -- �i��
      || ' ,xmril.case_quantity'                                               -- �P�[�X��
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      TO_CHAR(xmril.designated_production_date, ''' || gv_date_fmt_ymd || ''' )'
      || '    ELSE'
      || '      ilm.attribute1'
      || '    END                                 AS  make_date'               -- ������
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      NULL'
      || '    ELSE'
      || '      ilm.attribute3'
      || '    END                                 AS  shomi_kigen'             -- �ܖ�����
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''' )'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      NULL'
      || '    ELSE'
      || '      ilm.attribute2'
      || '    END                                 AS  koyu_kigou'              -- �ŗL�L��
      || ' ,CASE'
      || '    WHEN ((xmld.automanual_reserve_class = ''' || gv_auto_manual_kbn_a || ''')'
      || '    AND   (xmld.lot_no IS NULL)                 ) THEN'
      || '      NULL'
      || '    ELSE'
      || '      xmld.lot_no'
      || '    END                                 AS  lot_no'                  -- ���b�gNo
      || ' ,xlv2v4.meaning                        AS  lot_status_name'         -- �i��
      || ' ,CASE'
              -- ��������Ă���ꍇ
      || '    WHEN ( xmril.reserved_quantity > 0 ) THEN'
      || '      CASE'
      || '        WHEN  ( ( xic4v.item_class_code = ''' || gv_item_cd_prdct || ''' )'
      || '        AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN'
      || '          TRUNC(xmld.actual_quantity / TO_NUMBER('
      || '                                            CASE'
      || '                                              WHEN ( xim2v.num_of_cases > 0 ) THEN'
      || '                                                xim2v.num_of_cases'
      || '                                              ELSE'
      || '                                                TO_CHAR(1)'
      || '                                            END'
      || '                                          ), 3)'
      || '        ELSE'
      || '          xmld.actual_quantity'
      || '        END'
              -- ��������Ă��Ȃ��ꍇ
      || '    WHEN  (( xmril.reserved_quantity IS NULL ) OR ( xmril.reserved_quantity = 0 )) THEN'
      || '      NULL'
      || '    END                                 AS  actual_quantity'         -- ���b�g��������
      || ' ,xlv2v5.meaning                        AS  warrning_name'           -- �x��
      || ' ,xmrih.pallet_sum_quantity             AS  pallet_sum_quantity'     -- �p���b�g���v����
      || ' ,CASE'
      || '    WHEN xsm2v.small_amount_class = ''' || gv_small_kbn_obj || ''' THEN'
      || '      CASE'
      || '        WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''''
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '        THEN xmrih.sum_weight'
      || '        THEN CEIL(TRUNC(xmrih.sum_weight,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '        WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''''
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '        THEN xmrih.sum_capacity'
      || '        THEN CEIL(TRUNC(xmrih.sum_capacity,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '      END'
      || '    WHEN xsm2v.small_amount_class = ''' || gv_small_kbn_not_obj || ''' THEN'
      || '      CASE'
      || '        WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''' THEN'
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '          xmrih.sum_pallet_weight + xmrih.sum_weight'
      || '          CEIL(TRUNC(xmrih.sum_pallet_weight + xmrih.sum_weight,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '        WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''' THEN'
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || '          xmrih.sum_pallet_weight + xmrih.sum_capacity'
      || '          CEIL(TRUNC(xmrih.sum_pallet_weight + xmrih.sum_capacity,1))'
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || '      END'
      || '    WHEN xsm2v.small_amount_class IS NULL THEN'
      || '      NULL '
      || '    END                                 AS  req_weight_volume_total' -- �˗��d�ʑ̐�_���v
      || ' ,CASE'
      || '    WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''''
      || '    THEN ''' || gv_weight_uom || ''''
      || '    WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''''
      || '    THEN ''' || gv_capacity_uom || ''''
      || '    END                                 AS  req_weight_volume_unit'  -- �˗��d�ʑ̐�_�P��
      || ' ,CASE'
      || '    WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_w || ''''
      || '    THEN xmrih.loading_efficiency_weight'
      || '    WHEN xmrih.weight_capacity_class = ''' || gv_wei_cap_kbn_c || ''''
      || '    THEN xmrih.loading_efficiency_capacity'
      || '    END                                 AS loading_efficiency'       -- �ύڌ���
      || ' ,xlv2v6.attribute1                     AS reserved_kbn'             -- �����敪
-- 2008/07/02 A.Shiina v1.5 ADD Start
      || ' ,xlv2v1.lookup_code                    AS  freight_charge_code'     -- �^���敪(�R�[�h)
      || ' ,xc2v.complusion_output_code           AS complusion_output_kbn'    -- �����o�͋敪
-- 2008/07/02 A.Shiina v1.5 ADD End
-- 2008/09/25 Y.Yamamoto v1.8 ADD Start
      || ' ,NVL(ilm.lot_id, 0)                    AS  lot_id '                 -- ���b�gID
      || ' ,xic4v.item_class_code                 AS  item_class_code'         -- �i�ڋ敪
-- 2008/09/25 Y.Yamamoto v1.8 ADD End
      ;
--
      -- ================================================================================
      -- �y�ړ��zFROM�吶��
      -- ================================================================================
      lv_move_from := ' FROM '
      || '  xxinv_mov_req_instr_headers          xmrih'        -- �ړ��˗�/�w���w�b�_�A�h�I��
      || ' ,xxcmn_item_locations2_v              xil2v1'       -- OPM�ۊǏꏊ���VIEW2
      || ' ,xxcmn_item_locations2_v              xil2v2'       -- OPM�ۊǏꏊ���VIEW2
      || ' ,xxcmn_carriers2_v                    xc2v'         -- �^���Ǝҏ��VIEW2
      || ' ,fnd_user                             fu'           -- ���[�U�[�}�X�^
      || ' ,per_all_people_f                     papf'         -- �]�ƈ��}�X�^
      || ' ,xxinv_mov_req_instr_lines            xmril'        -- �ړ��˗�/�w������(�A�h�I��)
      || ' ,xxcmn_item_mst2_v                    xim2v'        -- OPM�i�ڏ��VIEW2
-- 2008/08/05 Y.Yamamoto v1.7 Update Start
--      || ' ,xxcmn_item_categories4_v             xic4v'        -- OPM�i�ڃJ�e�S���������VIEW4
      || ' ,xxcmn_item_categories5_v             xic4v'        -- OPM�i�ڃJ�e�S���������VIEW5
-- 2008/08/05 Y.Yamamoto v1.7 Update End
      || ' ,xxinv_mov_lot_details                xmld'         -- �ړ����b�g�ڍ�(�A�h�I��)
      || ' ,ic_lots_mst                          ilm'          -- OPM���b�g�}�X�^
      || ' ,xxwsh_ship_method2_v                 xsm2v'        -- �z���敪���VIEW2
      || ' ,xxcmn_lookup_values2_v               xlv2v1'       -- �N�C�b�N�R�[�h(�^���敪)
      || ' ,xxcmn_lookup_values2_v               xlv2v2'       -- �N�C�b�N�R�[�h(�ړ��^�C�v)
      || ' ,xxcmn_lookup_values2_v               xlv2v3'       -- �N�C�b�N�R�[�h(�_��O�^���敪)
      || ' ,xxcmn_lookup_values2_v               xlv2v4'       -- �N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
      || ' ,xxcmn_lookup_values2_v               xlv2v5'       -- �N�C�b�N�R�[�h(�x���敪)
      || ' ,xxcmn_lookup_values2_v               xlv2v6'       -- �N�C�b�N�R�[�h(�����敪)
      ;
--
      -- ================================================================================
      -- �y�ړ��zWHERE�吶��
      -- ================================================================================
      lv_move_where := ' WHERE '
           -------------------------------------------------------------------------------
           -- OPM�ۊǏꏊ���VIEW2-1
           -------------------------------------------------------------------------------
      || '       xmrih.shipped_locat_id          =   xil2v1.inventory_location_id'
           -------------------------------------------------------------------------------
           -- OPM�ۊǏꏊ���VIEW2-2
           -------------------------------------------------------------------------------
      || ' AND   xmrih.ship_to_locat_id          =   xil2v2.inventory_location_id'
           -------------------------------------------------------------------------------
           -- �^���Ǝҏ��VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xmrih.career_id                 =   xc2v.party_id(+)'
      || ' AND   ('
      || '         xc2v.start_date_active IS NULL'
      || '       OR'
      || '         xc2v.start_date_active       <=  xmrih.schedule_ship_date'
      || '       )'
      || ' AND   ('
      || '         xc2v.end_date_active IS NULL'
      || '       OR'
      || '         xc2v.end_date_active         >=  xmrih.schedule_ship_date'
      || '       )'
           -------------------------------------------------------------------------------
           -- ���[�U���
           -------------------------------------------------------------------------------
      || ' AND   xmrih.screen_update_by          = fu.user_id'
      || ' AND   fu.employee_id                  = papf.person_id'
-- 2009/09/14 H.Itou Add Start �{�ԏ�Q#1632
      || ' AND   xmrih.schedule_ship_date BETWEEN papf.effective_start_date '
      || '                                AND     NVL(papf.effective_end_date,xmrih.schedule_ship_date) '
-- 2009/09/14 H.Itou Add End
           -------------------------------------------------------------------------------
           -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
           -------------------------------------------------------------------------------
-- 2008/11/14 N.Fukuda v1.9 Add Start
      || ' AND   ('
      || '          xmrih.no_instr_actual_class IS NULL'
      || '       OR'
      || '          xmrih.no_instr_actual_class            <>  ''Y'''
      || '       )'
-- 2008/11/14 N.Fukuda v1.9 Add End
           -------------------------------------------------------------------------------
           -- �ړ��˗�/�w�����׃A�h�I��
           -------------------------------------------------------------------------------
      || ' AND   xmrih.mov_hdr_id                =   xmril.mov_hdr_id'
      || ' AND   ('
      || '          xmril.delete_flg IS NULL'
      || '       OR'
      || '          xmril.delete_flg            <>  ''Y'''
      || '       )'
-- 2008/08/05 Y.Yamamoto v1.7 ADD Start
--      || ' AND   xmril.instruct_qty              >   0'     -- 2008/11/14 N.Fukuda v1.9 Del
-- 2008/08/05 Y.Yamamoto v1.7 ADD End
           -------------------------------------------------------------------------------
           -- OPM�i�ڏ��VIEW2
           -------------------------------------------------------------------------------
      || ' AND   xmril.item_id                   =   xim2v.item_id'
      || ' AND   xim2v.start_date_active        <=  xmrih.schedule_ship_date'
      || ' AND   ('
      || '         xim2v.end_date_active IS NULL'
      || '       OR'
      || '         xim2v.end_date_active        >=  xmrih.schedule_ship_date'
      || '       )'
           -------------------------------------------------------------------------------
           -- OPM�i�ڃJ�e�S���������VIEW4
           -------------------------------------------------------------------------------
      || ' AND   xim2v.item_id              =   xic4v.item_id'
      || ' AND   xic4v.prod_class_code      =   ''' || gv_prod_kbn || ''''
           -------------------------------------------------------------------------------
           -- �ړ����b�g�ڍ�(�A�h�I��)
           -------------------------------------------------------------------------------
      || ' AND   xmril.mov_line_id          = xmld.mov_line_id(+)'
      || ' AND   xmld.document_type_code(+) = ''' || gv_document_type_move || ''''    -- �ړ�
      || ' AND   xmld.record_type_code(+)   = ''' || record_type_siji || ''''         -- �w��
           -------------------------------------------------------------------------------
           -- OPM���b�g�}�X�^
           -------------------------------------------------------------------------------
      || ' AND   xmld.lot_id                     =   ilm.lot_id(+)'
      || ' AND   xmld.item_id                    =   ilm.item_id(+)'
           -------------------------------------------------------------------------------
           -- �z���敪���VIEW2
           -------------------------------------------------------------------------------
      || ' AND xmrih.shipping_method_code        = xsm2v.ship_method_code(+)'
           -------------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�i�^���敪�j-- 1:�ΏہA2:�ΏۊO
           -------------------------------------------------------------------------------
      || ' AND xlv2v1.lookup_type                = ''' || gv_lookup_cd_freight || ''''
      || ' AND xmrih.freight_charge_class        = xlv2v1.lookup_code'
           -------------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�i�ړ��^�C�v�j-- 1:�ϑ�����A2:�ϑ��Ȃ�
           -------------------------------------------------------------------------------
      || ' AND xlv2v2.lookup_type                = ''' || gv_lookup_cd_move_type || ''''
      || ' AND xmrih.mov_type                    = xlv2v2.lookup_code'
           -------------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�i�_��O�^���敪�j-- 1:�ΏہA0:�ΏۊO
           -------------------------------------------------------------------------------
      || ' AND xlv2v3.lookup_type                = ''' || gv_lookup_cd_no_freight || ''''
      || ' AND xmrih.no_cont_freight_class       = xlv2v3.lookup_code'
           -------------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�iۯĽð���j-- 10:������A30:�����t�Ǖi�A50:���i�A60:�s���i�A70:�ۗ�
           -------------------------------------------------------------------------------
      || ' AND xlv2v4.lookup_type(+)             = ''' || gv_lookup_cd_lot_status || ''''
      || ' AND ilm.attribute23                   = xlv2v4.lookup_code(+)'
           -------------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�i�x���敪�j-- 10:�ύ�(OVER)�A20:�ύ�(LOW)�A30:���b�g�t�]�A40:�N�x�s��
           -------------------------------------------------------------------------------
      --MOD START 2008/06/04 NAKADA  �N�C�b�N�R�[�h�̌������O�������ɏC��
      || ' AND xlv2v5.lookup_type(+)             = ''' || gv_lookup_cd_warn || ''''
      || ' AND xmril.warning_class               = xlv2v5.lookup_code(+)'
      --MOD END   2008/06/04 NAKADA
           -------------------------------------------------------------------------------
           -- �N�C�b�N�R�[�h�i�����敪�j
           -------------------------------------------------------------------------------
      || ' AND xlv2v6.lookup_type(+)             = ''' || gv_lookup_cd_reserve || ''''
      || ' AND xmld.automanual_reserve_class     = xlv2v6.lookup_code(+)'
      ;
--
      -- ���̓p�����[�^�ɂ�����
          -------------------------------------------------------------------------------
          -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
          -------------------------------------------------------------------------------
      IF (   gr_param.block1 IS NOT NULL
          OR gr_param.block2 IS NOT NULL
          OR gr_param.block3 IS NOT NULL
          OR gr_param.deliver_from_code IS NOT NULL ) THEN
        lv_move_where := lv_move_where
        || ' AND ('
        || '       xil2v1.distribution_block IN (  ''' || gr_param.block1 || ''''
        || '                                     , ''' || gr_param.block2 || ''''
        || '                                     , ''' || gr_param.block3 || ''''
        || '                                     )'                             -- ����P.�u���b�N
        || '     OR'
        || '       xmrih.shipped_locat_code  = ''' || gr_param.deliver_from_code || ''''
        || '     )'
        ;
      END IF;
--
      IF (    gr_param.input_date_time_from IS NOT NULL
          AND gr_param.input_date_time_to IS NOT NULL ) THEN
        lv_move_where := lv_move_where
        || ' AND   ('
        || '         TRUNC( xmrih.screen_update_date, ''' || gv_date_fmt_mi || ''' ) '
        || '           >= FND_DATE.STRING_TO_DATE( ''' || gr_param.input_date_time_from || ''''
        || '                                      ,''' || gv_date_fmt_ymdhm || ''' ) '
        || '       AND'
        || '         TRUNC( xmrih.screen_update_date, ''' || gv_date_fmt_mi || ''' ) '
        || '           <= FND_DATE.STRING_TO_DATE( ''' || gr_param.input_date_time_to || ''''
        || '                                      ,''' || gv_date_fmt_ymdhm || ''' ) '
        || '       )'
        ;
      END IF;
--
          -------------------------------------------------------------------------------
          -- ���[�U���
          -------------------------------------------------------------------------------
      IF (   gr_param.tanto_code IS NOT NULL ) THEN
        lv_move_where := lv_move_where
        || ' AND papf.employee_number      = ''' || gr_param.tanto_code || ''''
        ;
      END IF;
--
    END IF;
--
    -- ====================================================
    -- ORDER BY�吶��
    -- ====================================================
    lv_order_by := ' ORDER BY '
    || '  screen_update_date'
    || ' ,req_mov_no'
    || ' ,meisai_number'
-- 2008/09/25 Y.Yamamoto v1.8 ADD Start
    || ' ,DECODE(item_class_code, ''' || gv_item_cd_prdct     || ''', make_date )'
    || ' ,DECODE(item_class_code, ''' || gv_item_cd_prdct     || ''', koyu_kigou )'
    || ' ,DECODE(item_class_code, ''' || gv_item_cd_genryo    || ''', TO_NUMBER( DECODE( lot_id, 0 , ''0'', lot_no) )'
    || '                        , ''' || gv_item_cd_sizai     || ''', TO_NUMBER( DECODE( lot_id, 0 , ''0'', lot_no) )'
    || '                        , ''' || gv_item_cd_hanseihin || ''', TO_NUMBER( DECODE( lot_id, 0 , ''0'', lot_no) ) )'
-- 2008/09/25 Y.Yamamoto v1.8 ADD End
    ;
--
    -- ====================================================
    -- SQL������
    -- ====================================================
    lv_sql :=   lv_select 
             || ' FROM ('
             -- �o�׏��
             || lv_ship_select
             || lv_ship_from
             || lv_ship_where
             ;
             IF ( gr_param.gyoumu_kbn IS NULL ) THEN
               lv_sql := lv_sql
               || ' UNION '
               ;
             END IF;
             -- �ړ����
             lv_sql := lv_sql
             || lv_move_select
             || lv_move_from
             || lv_move_where
             || ' ) '
             || lv_order_by
             ;
--
    -- ====================================================
    -- SQL���s
    -- ====================================================
    EXECUTE IMMEDIATE lv_sql BULK COLLECT INTO ot_report_data ;
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
  END prc_get_report_data;
--
--
  /***********************************************************************************
   * Procedure Name   : prc_get_profile
   * Description      : �v���t�@�C���擾����
   ***********************************************************************************/
  PROCEDURE prc_get_profile
    (
      ov_errbuf         OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
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
    -- ====================================================
    -- �o�׏d�ʒP�ʎ擾
    -- ====================================================
    gv_weight_uom := FND_PROFILE.VALUE(gv_prof_name_weight) ;
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_weight_uom IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gv_application_wsh
                                            ,gv_msg_id_not_get_prof
                                            ,gv_msg_tkn_nm_prof
                                            ,gv_msg_tkn_val_prof_wei
                                           ) ;
      RAISE global_api_expt ;
    END IF ;
--
    -- ====================================================
    -- �o�חe�ϒP�ʎ擾
    -- ====================================================
    gv_capacity_uom := FND_PROFILE.VALUE(gv_prof_name_capacity) ;
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_capacity_uom IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gv_application_wsh
                                            ,gv_msg_id_not_get_prof
                                            ,gv_msg_tkn_nm_prof
                                            ,gv_msg_tkn_val_prof_cap
                                           ) ;
      RAISE global_api_expt ;
    END IF ;
--
    -- ====================================================
    -- ���i�敪�擾
    -- ====================================================
--
    gv_prod_kbn := FND_PROFILE.VALUE(gv_prof_name_item_div) ;
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_prod_kbn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gv_application_wsh
                                            ,gv_msg_id_not_get_prof
                                            ,gv_msg_tkn_nm_prof
                                            ,gv_msg_tkn_val_prof_prod
                                           ) ;
      RAISE global_api_expt ;
    END IF ;
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
   * Procedure Name   : prc_chk_input_param
   * Description      : ���̓p�����[�^�`�F�b�N����
   ***********************************************************************************/
  PROCEDURE prc_chk_input_param
    (
      iv_gyoumu_kbn         IN         VARCHAR2       -- 01:�Ɩ����
     ,iv_block1             IN         VARCHAR2       -- 02:�u���b�N1
     ,iv_block2             IN         VARCHAR2       -- 03:�u���b�N2 
     ,iv_block3             IN         VARCHAR2       -- 04:�u���b�N3
     ,iv_deliver_from_code  IN         VARCHAR2       -- 05:�o�Ɍ�
     ,iv_tanto_code         IN         VARCHAR2       -- 06:�S���҃R�[�h
     ,iv_input_date         IN         VARCHAR2       -- 07:���͓��t
     ,iv_input_time_from    IN         VARCHAR2       -- 08:���͎���FROM
     ,iv_input_time_to      IN         VARCHAR2       -- 09:���͎���TO
     ,ov_errbuf             OUT NOCOPY VARCHAR2       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT NOCOPY VARCHAR2       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT NOCOPY VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_chk_input_param'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- ���͎���FROM
    lv_input_time_from VARCHAR(10) DEFAULT NULL;
    -- ���͎���TO
    lv_input_time_to VARCHAR(10) DEFAULT NULL;
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
    IF (
         (    iv_input_time_from IS NOT NULL
           OR iv_input_time_to IS NOT NULL
         )
         AND iv_input_date IS NULL) THEN
--
       -- �G���[���b�Z�[�W�o��
      ov_errmsg := xxcmn_common_pkg.get_msg( gv_application_wsh
                                            ,gv_msg_err_param) ;
--
      ov_errbuf  := ov_errmsg ;
      ov_retcode := gv_status_error;
--
    ELSE
--
      -- -----------------------------------------------------
      -- ���̓p�����[�^�i�[����
      -- -----------------------------------------------------
      gr_param.gyoumu_kbn            := iv_gyoumu_kbn;                 -- 01:�Ɩ����
      gr_param.block1                := iv_block1;                     -- 02:�u���b�N1
      gr_param.block2                := iv_block2;                     -- 03:�u���b�N2 
      gr_param.block3                := iv_block3;                     -- 04:�u���b�N3
      gr_param.deliver_from_code     := iv_deliver_from_code;          -- 05:�o�Ɍ�
      gr_param.tanto_code            := iv_tanto_code;                 -- 06:�S���҃R�[�h
--
      IF (iv_input_date IS NOT NULL) THEN
--
        -- ���͎���FROM
        IF (iv_input_time_from IS NULL) THEN
          lv_input_time_from := gv_min_time;
        ELSE
          lv_input_time_from := iv_input_time_from;
        END IF;
--
        -- ���͎���TO
        IF (iv_input_time_to IS NULL) THEN
          lv_input_time_to := gv_max_time;
        ELSE
          lv_input_time_to := iv_input_time_to;
        END IF;
--
        -- 07:���͓���FROM
        gr_param.input_date_time_from
          := iv_input_date || TO_CHAR(FND_DATE.STRING_TO_DATE(  lv_input_time_from
                                                              , gv_date_fmt_hh24mi)
                                                              , gv_date_fmt_hh24mi);
        -- 08:���͓���TO
        gr_param.input_date_time_to
          := iv_input_date || TO_CHAR(FND_DATE.STRING_TO_DATE(  lv_input_time_to
                                                              , gv_date_fmt_hh24mi)
                                                              , gv_date_fmt_hh24mi);
      END IF;
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
  END prc_chk_input_param ;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_gyoumu_kbn        IN      VARCHAR2         -- 01:�Ɩ����
     ,iv_block1            IN      VARCHAR2         -- 02:�u���b�N1
     ,iv_block2            IN      VARCHAR2         -- 03:�u���b�N2 
     ,iv_block3            IN      VARCHAR2         -- 04:�u���b�N3
     ,iv_deliver_from_code IN      VARCHAR2         -- 05:�o�Ɍ�
     ,iv_tanto_code        IN      VARCHAR2         -- 06:�S���҃R�[�h
     ,iv_input_date        IN      VARCHAR2         -- 07:���͓��t
     ,iv_input_time_from   IN      VARCHAR2         -- 08:���͎���FROM
     ,iv_input_time_to     IN      VARCHAR2         -- 09:���͎���TO
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
    -- �o�Ɏw���m�F�\�f�[�^
    lt_report_data           type_report_data_tbl;
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
    -- ���̓p�����[�^�`�F�b�N����
    -- ====================================================
    prc_chk_input_param(
        iv_gyoumu_kbn           => iv_gyoumu_kbn          -- 01:�Ɩ����
       ,iv_block1               => iv_block1              -- 02:�u���b�N1
       ,iv_block2               => iv_block2              -- 03:�u���b�N2 
       ,iv_block3               => iv_block3              -- 04:�u���b�N3
       ,iv_deliver_from_code    => iv_deliver_from_code   -- 05:�o�Ɍ�
       ,iv_tanto_code           => iv_tanto_code          -- 06:�S���҃R�[�h
       ,iv_input_date           => iv_input_date          -- 07:���͓��t
       ,iv_input_time_from      => iv_input_time_from     -- 08:���͎���FROM
       ,iv_input_time_to        => iv_input_time_to       -- 09:���͎���TO
       ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W
       ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h
       ,ov_errmsg               => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
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
        ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- ���[���擾����
    -- ====================================================
    prc_get_report_data(
        ot_report_data     => lt_report_data      -- �擾�f�[�^
       ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (lt_report_data.COUNT <> 0) THEN
      -- ====================================================
      -- �w�l�k�f�[�^�쐬����
      -- ====================================================
      prc_create_xml_data(
          it_report_data       =>     lt_report_data     -- �o�ג����\�f�[�^
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
    IF (lt_report_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
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
     ,iv_gyoumu_kbn         IN     VARCHAR2         -- 01:�Ɩ����
     ,iv_block1             IN     VARCHAR2         -- 02:�u���b�N1
     ,iv_block2             IN     VARCHAR2         -- 03:�u���b�N2 
     ,iv_block3             IN     VARCHAR2         -- 04:�u���b�N3
     ,iv_deliver_from_code  IN     VARCHAR2         -- 05:�o�Ɍ�
     ,iv_tanto_code         IN     VARCHAR2         -- 06:�S���҃R�[�h
     ,iv_input_date         IN     VARCHAR2         -- 07:���͓��t
     ,iv_input_time_from    IN     VARCHAR2         -- 08:���͎���FROM
     ,iv_input_time_to      IN     VARCHAR2         -- 09:���͎���TO
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
        iv_gyoumu_kbn          => iv_gyoumu_kbn         -- 01:�Ɩ����
       ,iv_block1              => iv_block1             -- 02:�u���b�N1
       ,iv_block2              => iv_block2             -- 03:�u���b�N2 
       ,iv_block3              => iv_block3             -- 04:�u���b�N3
       ,iv_deliver_from_code   => iv_deliver_from_code  -- 05:�o�Ɍ�
       ,iv_tanto_code          => iv_tanto_code         -- 06:�S���҃R�[�h
       ,iv_input_date          => iv_input_date         -- 07:���͓��t
       ,iv_input_time_from     => iv_input_time_from    -- 08:���͎���FROM
       ,iv_input_time_to       => iv_input_time_to      -- 09:���͎���TO
       ,ov_errbuf              => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode             => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg              => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
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
END xxwsh620005c ;
/
