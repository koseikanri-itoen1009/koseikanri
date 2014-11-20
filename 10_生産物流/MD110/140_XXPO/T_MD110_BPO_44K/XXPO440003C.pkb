CREATE OR REPLACE PACKAGE BODY xxpo440003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440003(body)
 * Description      : ���ɗ\��\
 * MD.050/070       : �L���x�����[Issue1.0(T_MD050_BPO_444)
 *                    �L���x�����[Issue1.0(T_MD070_BPO_44K)
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_create_xml_data_user    PROCEDURE : �^�O�o�� - ���[�U�[���
 *  prc_create_sql              PROCEDURE : �f�[�^�擾�r�p�k����
 *  prc_create_xml_data         PROCEDURE : �w�l�k�f�[�^�ҏW
 *  convert_into_xml            FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  submain                     PROCEDURE : ���C�������v���V�[�W��
 *  main                        PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/26    1.0   Masayuki Ikeda   �V�K�쐬
 *  2008/06/04    1.1 Yasuhisa Yamamoto  �����e�X�g�s����O#440_53
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
  -- ===============================================================================================
  -- ���[�U�[�錾��
  -- ===============================================================================================
  -- ==================================================
  -- �O���[�o���萔
  -- ==================================================
-- 2008/06/04 UPD START Y.Yamamoto
--  gc_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo440003C' ;      -- �p�b�P�[�W��
--  gc_report_id            CONSTANT VARCHAR2(20) := 'xxpo440003T' ;      -- ���[ID
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'XXPO440003C' ;      -- �p�b�P�[�W��
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXPO440003T' ;      -- ���[ID
-- 2008/06/04 UPD END Y.Yamamoto
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- �A�v���P�[�V����
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;             -- �A�v���P�[�V����
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- �f�[�^�O�����b�Z�[�W
  gc_err_code_no_prof     CONSTANT VARCHAR2(15) := 'APP-XXPO-10005' ;   -- �v���t�@�C���擾�G���[
--
  ------------------------------
  -- �v���t�@�C����
  ------------------------------
  gc_prof_org_id          CONSTANT VARCHAR2(20) := 'ORG_ID' ;   -- �c�ƒP��
  gn_prof_org_id          oe_transaction_types_all.org_id%TYPE ;
--
  ------------------------------
  -- �Q�ƃR�[�h
  ------------------------------
  -- �p�����[�^�F�g�p�ړI
  gc_use_purpose_irai     CONSTANT VARCHAR2(1) := '1' ;     -- �˗�
  gc_use_purpose_shij     CONSTANT VARCHAR2(1) := '2' ;     -- �w��
  -- �p�����[�^�F�L���Z�L�����e�B�敪
  gc_security_div_i       CONSTANT VARCHAR2(1) := '1' ;     -- �ɓ���
  gc_security_div_d       CONSTANT VARCHAR2(1) := '2' ;     -- �����
  gc_security_div_l       CONSTANT VARCHAR2(1) := '3' ;     -- �o�ɑq��
  -- �󒍃J�e�S���F�󒍃J�e�S���R�[�h
  gc_order_cat_o          CONSTANT VARCHAR2(10) := 'ORDER' ;
  gc_order_cat_r          CONSTANT VARCHAR2(10) := 'RETURN' ;
  -- �󒍃J�e�S���F�o�׎x���敪
  gc_sp_class_ship        CONSTANT VARCHAR2(1)  := '1' ;    -- �o�׈˗�
  gc_sp_class_prov        CONSTANT VARCHAR2(1)  := '2' ;    -- �x���˗�
  gc_sp_class_move        CONSTANT VARCHAR2(1)  := '3' ;    -- �ړ�
  -- �󒍃J�e�S���F�o�׎x���󕥃J�e�S��
  gc_sp_rp_cat_miho       CONSTANT VARCHAR2(2)  := '01' ;   -- ���{�o��
  gc_sp_rp_cat_haik       CONSTANT VARCHAR2(2)  := '02' ;   -- �p���o��
  gc_sp_rp_cat_nkur       CONSTANT VARCHAR2(2)  := '03' ;   -- �q�֓���
  gc_sp_rp_cat_nhen       CONSTANT VARCHAR2(2)  := '04' ;   -- �ԕi����
  gc_sp_rp_cat_ysyu       CONSTANT VARCHAR2(2)  := '05' ;   -- �L���o��
  gc_sp_rp_cat_yhen       CONSTANT VARCHAR2(2)  := '06' ;   -- �L���ԕi
  -- �󒍃w�b�_�A�h�I���F�ŐV�t���O�iYesNo�敪�j
  gc_yn_div_y             CONSTANT VARCHAR2(1)  := 'Y' ;    -- YES
  gc_yn_div_n             CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- �󒍃w�b�_�A�h�I���F�X�e�[�^�X
  gc_req_status_s_inp     CONSTANT VARCHAR2(2)  := '05' ;   -- ���͒�
  gc_req_status_s_cmpa    CONSTANT VARCHAR2(2)  := '06' ;   -- ���͊���
  gc_req_status_s_cmpb    CONSTANT VARCHAR2(2)  := '07' ;   -- ��̍�
  gc_req_status_s_cmpc    CONSTANT VARCHAR2(2)  := '08' ;   -- �o�׎��ьv���
  gc_req_status_p_ccl     CONSTANT VARCHAR2(2)  := '99' ;   -- ���
  -- �󒍃w�b�_�A�h�I���F�ʒm�X�e�[�^�X
  gc_notif_status_no      CONSTANT VARCHAR2(2)  := '10' ;   -- ���ʒm
  gc_notif_status_re      CONSTANT VARCHAR2(2)  := '20' ;   -- �Ēʒm�v
  gc_notif_status_ok      CONSTANT VARCHAR2(2)  := '40' ;   -- �m��ʒm��
  -- �ړ����b�g�ڍ׃A�h�I���F�����^�C�v
  gc_doc_type_ship        CONSTANT VARCHAR2(2) := '10' ;    -- �o�׎w��
  gc_doc_type_move        CONSTANT VARCHAR2(2) := '20' ;    -- �ړ�
  gc_doc_type_prov        CONSTANT VARCHAR2(2) := '30' ;    -- �x���w��
  gc_doc_type_prod        CONSTANT VARCHAR2(2) := '40' ;    -- ���Y�w��
  -- �ړ����b�g�ڍ׃A�h�I���F���R�[�h�^�C�v
  gc_rec_type_inst        CONSTANT VARCHAR2(2) := '10' ;    -- �w��
  gc_rec_type_stck        CONSTANT VARCHAR2(2) := '20' ;    -- �o�Ɏ���
  gc_rec_type_dlvr        CONSTANT VARCHAR2(2) := '30' ;    -- ���Ɏ���
  gc_rec_type_tron        CONSTANT VARCHAR2(2) := '40' ;    -- ������
  -- �n�o�l�i�ڃ}�X�^�F���b�g�Ǘ��敪
  gc_lot_ctl_y            CONSTANT VARCHAR2(1) := '1' ;     -- ���b�g�Ǘ�����
  gc_lot_ctl_n            CONSTANT VARCHAR2(1) := '0' ;     -- ���b�g�Ǘ��Ȃ�
  ------------------------------
  -- ���̑�
  ------------------------------
  -- �i�ڋ敪
  gc_item_div_gen         CONSTANT VARCHAR2(1)  := '1' ;  -- ����
  gc_item_div_shi         CONSTANT VARCHAR2(1)  := '2' ;  -- ����
  gc_item_div_han         CONSTANT VARCHAR2(1)  := '4' ;  -- �����i
  gc_item_div_sei         CONSTANT VARCHAR2(1)  := '5' ;  -- ���i
  gc_max_date_char        CONSTANT VARCHAR2(10) := '4712/12/31' ;
  -- ���[�^�C�g��
  gc_report_name_irai     CONSTANT VARCHAR2(20) := '���ɗ\��\�i�˗��j' ;
  gc_report_name_shij     CONSTANT VARCHAR2(20) := '���ɗ\��\�i�w���j' ;
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���^
  -- ==================================================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD
    (
      use_purpose       VARCHAR2(1)   -- 01 : �g�p�ړI
     ,deliver_to_code   VARCHAR2(4)   -- 02 : �z����
     ,date_from         VARCHAR2(10)  -- 03 : �o�ɓ�From
     ,date_to           VARCHAR2(10)  -- 04 : �o�ɓ�To
     ,prod_div          VARCHAR2(1)   -- 05 : ���i�敪
     ,item_div          VARCHAR2(1)   -- 06 : �i�ڋ敪
     ,item_code         VARCHAR2(7)   -- 07 : �i��
     ,locat_code        VARCHAR2(4)   -- 08 : �o�ɑq��
     ,security_div      VARCHAR2(1)   -- 09 : �L���Z�L�����e�B�敪
    ) ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gr_param              rec_param_data ;      -- �p�����[�^
  gn_data_cnt           NUMBER DEFAULT 0 ;    -- �����f�[�^�J�E���^
  gv_sql                VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
--
  gt_xml_data_table     XML_DATA ;            -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx            NUMBER DEFAULT 0 ;    -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
  gn_user_id            fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID ;   -- ���O�C�����[�U�[�h�c
  gv_report_name        VARCHAR2(20)  ;       -- ���[�^�C�g��
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
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_user
   * Description      : ���[�U�[���^�O�o��
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_user' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �f�[�^�^�O
    -- ====================================================
    -- ���[�h�c
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
    -- ���s��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' ) ;
    -- ���O�C�����[�U�[�F��������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ) ;
    -- ���O�C�����[�U�[�F���[�U�[��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ) ;
--
    -- ====================================================
    -- �I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_sql
   * Description      : �f�[�^�擾�r�p�k����
   ************************************************************************************************/
  PROCEDURE prc_create_sql
    (
      ov_errbuf             OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_sql' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �r�d�k�d�b�s�吶��
    -- ====================================================
    lv_select := ' SELECT'
      || ' xvs.vendor_site_code         AS deliver_to_code'   -- �z����R�[�h
      || ',xvs.vendor_site_short_name   AS deliver_to_name'   -- �z���於��
      || ',TO_CHAR( xoha.schedule_arrival_date,''YYYY/MM/DD'' ) AS ship_in_date'  -- ���ɓ�
      || ',xic.prod_class_code          AS prod_div'          -- ���i�敪
      || ',xic.prod_class_name          AS prod_div_name'     -- ���i�敪����
      || ',xic.item_class_code          AS item_div'          -- �i�ڋ敪
      || ',xic.item_class_name          AS item_div_name'     -- �i�ڋ敪����
      || ',xim.item_id                  AS item_id'           -- �i�ڂh�c
      || ',xim.item_no                  AS item_code'         -- �i�ڃR�[�h
      || ',xim.item_short_name          AS item_name'         -- �i�ږ���
      || ',xim.lot_ctl                  AS lot_ctl'           -- ���b�g�g�p
      || ',xola.uom_code                AS uom_code'          -- �P��
      || ',xola.order_line_id           AS order_line_id'     -- �󒍖��ׂh�c
      || ',xola.futai_code              AS futai_code'        -- �t��
      || ',xil.segment1                 AS locat_code'        -- �o�ɑq�ɃR�[�h
      || ',xil.description              AS locat_name'        -- �o�ɑq�ɖ���
      || ',TO_CHAR( xoha.schedule_ship_date ,''MM/DD'' ) AS ship_to_date'  -- �o�ɓ�
      || ',xoha.request_no              AS request_no'        -- �˗��m��
      || ',xoha.po_no                   AS order_no'          -- �����m��
      || ',xola.line_description        AS description'       -- ���דE�v
      || ',xim.frequent_qty             AS frequent_qty'      -- ����
      ;
--
    -- �˗��̏ꍇ
    IF ( gr_param.use_purpose = gc_use_purpose_irai ) THEN
      lv_select := lv_select
        || ',xola.based_request_quantity  AS quantity' ;    -- ���_�˗�����
    ELSE
      lv_select := lv_select
        || ',xola.quantity                AS quantity' ;    -- ����
    END IF ;
--
    -- ====================================================
    -- �e�q�n�l�吶��
    -- ====================================================
    lv_from := ' FROM'
      || ' oe_transaction_types_all   otta'   -- �󒍃^�C�v
      || ',xxwsh_order_headers_all    xoha'   -- �󒍃w�b�_�A�h�I��
      || ',xxwsh_order_lines_all      xola'   -- �󒍖��׃A�h�I��
      || ',xxcmn_item_locations2_v    xil'    -- OPM�ۊǏꏊ�}�X�^
      || ',xxcmn_vendor_sites2_v      xvs'    -- �d����T�C�gView
      || ',xxcmn_item_mst2_v          xim'    -- OPM�i�ڏ��View
      || ',xxcmn_item_categories4_v   xic'    -- OPM�i�ڃJ�e�S������View
      || ',xxpo_security_supply_v     xss'    -- �L���Z�L�����e�BView
      ;
--
    -- ====================================================
    -- �v�g�d�q�d�吶��
    -- ====================================================
    lv_where := ' WHERE'
      || '     xss.user_id           = ' || gn_user_id
      || ' AND xss.security_class    = ' || gr_param.security_div
      || ' AND xil.segment1          = NVL( xss.segment1        , xil.segment1)'
      || ' AND xoha.vendor_code      = NVL( xss.vendor_code     , xoha.vendor_code )'
      || ' AND xoha.vendor_site_code = NVL( xss.vendor_site_code, xoha.vendor_site_code )'
      || ' AND xim.item_id                = xic.item_id'                  -- OPM�i�ڃJ�e�S����������
      || ' AND xoha.schedule_ship_date BETWEEN xim.start_date_active'
      ||                             ' AND     NVL( xim.end_date_active, xoha.schedule_ship_date )'
      || ' AND xola.shipping_item_code    = xim.item_no'                  -- OPM�i�ڃ}�X�^����
      || ' AND NVL( xola.delete_flag, ''' || gc_yn_div_n || ''')'
      ||                                ' = ''' || gc_yn_div_n || ''''
      || ' AND xoha.order_header_id       = xola.order_header_id'         -- �󒍖��׃A�h�I������
      || ' AND otta.org_id                = '   || gn_prof_org_id
      || ' AND otta.attribute1            = ''' || gc_sp_class_prov  || ''''
      || ' AND otta.attribute11           = ''' || gc_sp_rp_cat_ysyu || ''''
      || ' AND otta.order_category_code  <> ''' || gc_order_cat_r    || ''''
      || ' AND xoha.order_type_id         = otta.transaction_type_id'     -- �󒍃^�C�v����
      || ' AND xoha.schedule_ship_date BETWEEN xvs.start_date_active'
      ||                             ' AND     NVL( xvs.end_date_active, xoha.schedule_ship_date )'
      || ' AND xoha.vendor_site_id        = xvs.vendor_site_id'           -- �d����}�X�^����
      || ' AND xoha.deliver_from_id       = xil.inventory_location_id'    -- OPM�ۊǏꏊ�}�X�^����
      || ' AND xoha.req_status           IN(''' || gc_req_status_s_cmpb || ''''
      ||                                  ',''' || gc_req_status_s_cmpc || ''')'
      || ' AND xoha.latest_external_flag  = ''' || gc_yn_div_y || ''''
      || ' AND xoha.schedule_arrival_date'
      ||          ' BETWEEN FND_DATE.CANONICAL_TO_DATE(''' || gr_param.date_from || ''')'
      ||          ' AND     FND_DATE.CANONICAL_TO_DATE(''' || gr_param.date_to   || ''')'
      ;
--
    -- ----------------------------------------------------
    -- �L���Z�L�����e�B�敪�ɂ�����
    -- ----------------------------------------------------
    -- �p�����[�^�D�g�p�ړI���u�w���v�̏ꍇ
    IF ( gr_param.use_purpose = gc_use_purpose_shij ) THEN
      -- �Z�L�����e�B�敪���u1�i�ɓ����j�v�̏ꍇ
      IF ( gr_param.security_div = gc_security_div_i ) THEN
        lv_where := lv_where
          || ' AND xola.quantity = xola.reserved_quantity'
          ;
      -- �Z�L�����e�B�敪���u2�i�����j�v�̏ꍇ
      ELSIF ( gr_param.security_div = gc_security_div_d ) THEN
        lv_where := lv_where
          || ' AND xoha.notif_status = ''' || gc_notif_status_ok || ''''
          ;
      -- �Z�L�����e�B�敪���u3�i�o�ɑq�Ɂj�v�̏ꍇ
      ELSE
        lv_where := lv_where
          || ' AND xoha.notif_status = ''' || gc_notif_status_ok || ''''
          ;
      END IF ;
    END IF ;
    -- ----------------------------------------------------
    -- �p�����[�^�w��ɂ�����
    -- ----------------------------------------------------
    -- �z����
    IF ( gr_param.deliver_to_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xvs.vendor_site_code = ''' || gr_param.deliver_to_code || ''''
        ;
    END IF ;
    -- ���i�敪
    IF ( gr_param.prod_div IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xic.prod_class_code = ''' || gr_param.prod_div || ''''
        ;
    END IF ;
    -- �i�ڋ敪
    IF ( gr_param.item_div IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xic.item_class_code = ''' || gr_param.item_div || ''''
        ;
    END IF ;
    -- �i��
    IF ( gr_param.item_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xim.item_no = ''' || gr_param.item_code || ''''
        ;
    END IF ;
    -- �o�ɑq��
    IF ( gr_param.locat_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xil.segment1 = ''' || gr_param.locat_code || ''''
        ;
    END IF ;
--
    -- ====================================================
    -- �n�q�c�d�q  �a�x�吶��
    -- ====================================================
    lv_order_by := ' ORDER BY'
      || ' xvs.vendor_site_code'
      || ',xoha.schedule_arrival_date'
      || ',xic.prod_class_code'
      || ',xic.item_class_code'
      || ',TO_NUMBER( xim.item_no )'
      || ',xola.futai_code'
      || ',xil.segment1'
      || ',xoha.schedule_ship_date'
      || ',xoha.request_no'
      ;
--
    -- ====================================================
    -- �r�p�k����
    -- ====================================================
    gv_sql := lv_select || lv_from || lv_where || lv_order_by ;
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_sql ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�ҏW
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- ��  ��  ��  ��
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- �萔�錾
    -- ==================================================
    lc_init                 CONSTANT  VARCHAR2(1) := '*' ;
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    -- �u���C�N���f�p�ϐ�
    lv_deliver_to_code      VARCHAR2(4)  DEFAULT lc_init ;
    lv_ship_in_date         VARCHAR2(10) DEFAULT lc_init ;
    lv_prod_div             VARCHAR2(1)  DEFAULT lc_init ;
    lv_item_div             VARCHAR2(1)  DEFAULT lc_init ;
    lv_item_code            VARCHAR2(7)  DEFAULT lc_init ;
    lv_futai_code           VARCHAR2(1)  DEFAULT lc_init ;
    lv_locat_code           VARCHAR2(4)  DEFAULT lc_init ;
    lv_ship_to_date         VARCHAR2(10) DEFAULT lc_init ;
    lv_request_no           VARCHAR2(12) DEFAULT lc_init ;
--
    --���i�敪�A��
    ln_position             NUMBER DEFAULT 0 ;
--
    -- ==================================================
    -- �q�����J�[�\���錾
    -- ==================================================
    TYPE ref_cursor IS REF CURSOR ;
    TYPE ret_value  IS RECORD
      (
        deliver_to_code     xxcmn_vendor_sites2_v.vendor_site_code%TYPE         -- �z����R�[�h
       ,deliver_to_name     xxcmn_vendor_sites2_v.vendor_site_name%TYPE         -- �z���於��
       ,ship_in_date        VARCHAR2(10)                                        -- ���ɓ�
       ,prod_div            xxcmn_item_categories4_v.prod_class_code%TYPE       -- ���i�敪
       ,prod_div_name       xxcmn_item_categories4_v.prod_class_name%TYPE       -- ���i�敪����
       ,item_div            xxcmn_item_categories4_v.item_class_code%TYPE       -- �i�ڋ敪
       ,item_div_name       xxcmn_item_categories4_v.item_class_name%TYPE       -- �i�ڋ敪����
       ,item_id             xxcmn_item_mst2_v.item_id%TYPE                      -- �i�ڂh�c
       ,item_code           xxcmn_item_mst2_v.item_no%TYPE                      -- �i�ڃR�[�h
       ,item_name           xxcmn_item_mst2_v.item_short_name%TYPE              -- �i�ږ���
       ,lot_ctl             xxcmn_item_mst2_v.lot_ctl%TYPE                      -- ���b�g�g�p
       ,uom_code            xxwsh_order_lines_all.uom_code%TYPE                 -- �P��
       ,order_line_id       xxwsh_order_lines_all.order_line_id%TYPE            -- �󒍖��ׂh�c
       ,futai_code          xxwsh_order_lines_all.futai_code%TYPE               -- �t��
       ,locat_code          mtl_item_locations.segment1%TYPE                    -- �o�ɑq�ɃR�[�h
       ,locat_name          mtl_item_locations.description%TYPE                 -- �o�ɑq�ɖ���
       ,ship_to_date        VARCHAR2(10)                                        -- �o�ɓ�
       ,request_no          xxwsh_order_headers_all.request_no%TYPE             -- �˗��m��
       ,order_no            xxwsh_order_headers_all.po_no%TYPE                  -- �����m��
       ,description         xxwsh_order_lines_all.line_description%TYPE         -- ���דE�v
       ,frequent_qty        xxcmn_item_mst2_v.frequent_qty%TYPE                 -- ����
       ,quantity            xxwsh_order_lines_all.based_request_quantity%TYPE   -- ����
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
    lc_sql_lot  VARCHAR2(32000)
      := ' SELECT ilm.lot_no             AS lot_no'
      || '       ,ilm.attribute1         AS product_date'
      || '       ,ilm.attribute3         AS use_by_date'
      || '       ,ilm.attribute2         AS original_char'
      || '       ,ilm.attribute6         AS frequent_qty'
      || '       ,xmld.actual_quantity   AS quantity'
      || ' FROM ic_lots_mst            ilm'
      || '     ,xxinv_mov_lot_details  xmld'
      || ' WHERE xmld.lot_id             = ilm.lot_id'
      || ' AND   xmld.item_id            = ilm.item_id'
      || ' AND   xmld.record_type_code   = ''' || gc_rec_type_inst || ''''    -- 10�i�w���j
      || ' AND   xmld.document_type_code = ''' || gc_doc_type_prov || ''''    -- 30�i�x���w���j
      || ' AND   xmld.mov_line_id        = :v1'
      || ' AND   xmld.item_id            = :v2'
      ;
    -- ORDER BY�i���i�j
    lc_sql_order_by_1     VARCHAR2(32000)
      := ' ORDER BY FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )'
      ||         ' ,ilm.attribute2'
      ;
    -- ORDER BY�i���i�ȊO�j
    lc_sql_order_by_2     VARCHAR2(32000)
      := ' ORDER BY TO_NUMBER( ilm.lot_no )'
      ;
    -- ���b�g���擾
    TYPE ret_value_lot  IS RECORD
      (
        lot_no            VARCHAR2(10)    -- ���b�g�m��
       ,product_date      VARCHAR2(10)    -- �����N����
       ,use_by_date       VARCHAR2(10)    -- �ܖ�����
       ,original_char     VARCHAR2(6)     -- �ŗL�L��
       ,frequent_qty      VARCHAR2(10)    -- ����
       ,quantity          VARCHAR2(15)    -- ����
      ) ;
    lc_ref_lot    ref_cursor ;
    lr_ref_lot    ret_value_lot ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- ====================================================
    -- �J�[�\���I�[�v��
    -- ====================================================
    OPEN lc_ref FOR gv_sql ;
--
    -- ----------------------------------------------------
    -- �o�ɑq�ɃO���[�v
    -- ----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_deliver' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
      gn_data_cnt := gn_data_cnt + 1 ;
--
      -- ====================================================
      -- �u���C�N����F�z����O���[�v
      -- ====================================================
      IF ( lr_ref.deliver_to_code <> lv_deliver_to_code ) THEN
        -- ----------------------------------------------------
        -- ���w�O���[�v�I���^�O�o��
        -- ----------------------------------------------------
        IF ( lv_deliver_to_code <> lc_init ) THEN
--
          -- �󒍃w�b�_�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍃w�b�_���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍖��׃O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍖��׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃO���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃ��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڋ敪�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڋ敪���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���i�敪�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���i�敪���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���ɓ��O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ship' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���ɓ����X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �z����O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_deliver' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- �z����R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.deliver_to_code ;
        -- �z���於��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.deliver_to_name ;
--
        -- ----------------------------------------------------
        -- ���X�g�O���[�v�J�n�^�O�i�o�ɓ��j
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ship' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �u���C�N���f�p���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_deliver_to_code := lr_ref.deliver_to_code ;
        lv_ship_in_date    := lc_init ;
        lv_prod_div        := lc_init ;
        ln_position        := 0 ;
        lv_item_div        := lc_init ;
        lv_item_code       := lc_init ;
        lv_futai_code      := lc_init ;
        lv_locat_code      := lc_init ;
        lv_ship_to_date    := lc_init ;
        lv_request_no      := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- �u���C�N����F���ɓ��O���[�v
      -- ====================================================
      IF ( lr_ref.ship_in_date <> lv_ship_in_date ) THEN
        -- ----------------------------------------------------
        -- ���w�O���[�v�I���^�O�o��
        -- ----------------------------------------------------
        IF ( lv_ship_in_date <> lc_init ) THEN
--
          -- �󒍃w�b�_�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍃w�b�_���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍖��׃O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍖��׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃO���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃ��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڋ敪�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڋ敪���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���i�敪�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���i�敪���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���ɓ��O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ship' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ship' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- ���ɓ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_in_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.ship_in_date ;
--
        -- ----------------------------------------------------
        -- ���X�g�O���[�v�J�n�^�O�i���i�敪�j
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �u���C�N���f�p���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_ship_in_date := lr_ref.ship_in_date ;
        lv_prod_div     := lc_init ;
        ln_position     := 0 ;
        lv_item_div     := lc_init ;
        lv_item_code    := lc_init ;
        lv_futai_code   := lc_init ;
        lv_locat_code   := lc_init ;
        lv_ship_to_date := lc_init ;
        lv_request_no   := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- �u���C�N����F���i�敪�O���[�v
      -- ====================================================
      IF ( lr_ref.prod_div <> lv_prod_div ) THEN
        -- ----------------------------------------------------
        -- ���w�O���[�v�I���^�O�o��
        -- ----------------------------------------------------
        IF ( lv_prod_div <> lc_init ) THEN
--
          -- �󒍃w�b�_�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍃w�b�_���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍖��׃O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍖��׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃO���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃ��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڋ敪�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڋ敪���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ���i�敪�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        ln_position := ln_position + 1 ;
        -- �|�W�V����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'position' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := ln_position ;
        -- ���i�敪�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.prod_div ;
        -- ���i�敪����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.prod_div_name ;
--
        -- ----------------------------------------------------
        -- ���X�g�O���[�v�J�n�^�O�i�i�ڋ敪�j
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �u���C�N���f�p���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_prod_div     := lr_ref.prod_div ;
        lv_item_div     := lc_init ;
        lv_item_code    := lc_init ;
        lv_futai_code   := lc_init ;
        lv_locat_code   := lc_init ;
        lv_ship_to_date := lc_init ;
        lv_request_no   := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- �u���C�N����F�i�ڋ敪�O���[�v
      -- ====================================================
      IF ( lr_ref.item_div <> lv_item_div ) THEN
        -- ----------------------------------------------------
        -- ���w�O���[�v�I���^�O�o��
        -- ----------------------------------------------------
        IF ( lv_item_div <> lc_init ) THEN
--
          -- �󒍃w�b�_�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍃w�b�_���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍖��׃O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍖��׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃO���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃ��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڋ敪�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- �i�ڋ敪�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_div ;
        -- �i�ڋ敪����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_div_name ;
--
        -- ----------------------------------------------------
        -- ���X�g�O���[�v�J�n�^�O�i�i�ځj
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �u���C�N���f�p���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_item_div     := lr_ref.item_div ;
        lv_item_code    := lc_init ;
        lv_futai_code   := lc_init ;
        lv_locat_code   := lc_init ;
        lv_ship_to_date := lc_init ;
        lv_request_no   := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- �u���C�N����F�i�ڃO���[�v
      -- ====================================================
      IF ( lr_ref.item_code <> lv_item_code ) THEN
        -- ----------------------------------------------------
        -- ���w�O���[�v�I���^�O�o��
        -- ----------------------------------------------------
        IF ( lv_item_code <> lc_init ) THEN
--
          -- �󒍃w�b�_�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍃w�b�_���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍖��׃O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍖��׃��X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �i�ڃO���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- �i�ڃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_code ;
        -- �i�ږ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_name ;
        -- �P��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'uom_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.uom_code ;
--
        -- ----------------------------------------------------
        -- ���X�g�O���[�v�J�n�^�O�i�󒍖��ׁj
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �u���C�N���f�p���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_item_code    := lr_ref.item_code ;
        lv_futai_code   := lc_init ;
        lv_locat_code   := lc_init ;
        lv_ship_to_date := lc_init ;
        lv_request_no   := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- �u���C�N����F�󒍖��׃O���[�v
      -- ====================================================
      IF ( lr_ref.futai_code <> lv_futai_code ) THEN
        -- ----------------------------------------------------
        -- �O���[�v�I���^�O�o��
        -- ----------------------------------------------------
        IF ( lv_futai_code <> lc_init ) THEN
--
          -- �󒍃w�b�_�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍃w�b�_���X�g�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- �󒍖��׃O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- �t��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.futai_code ;
--
        -- ----------------------------------------------------
        -- ���X�g�O���[�v�J�n�^�O�i�󒍃w�b�_�j
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �u���C�N���f�p���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_futai_code   := lr_ref.futai_code ;
        lv_locat_code   := lc_init ;
        lv_ship_to_date := lc_init ;
        lv_request_no   := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- �u���C�N����F�󒍃w�b�_�O���[�v
      -- ====================================================
      IF (   ( lr_ref.locat_code   <> lv_locat_code   )
          OR ( lr_ref.ship_to_date <> lv_ship_to_date )
          OR ( lr_ref.request_no   <> lv_request_no   ) ) THEN
        -- ----------------------------------------------------
        -- �O���[�v�I���^�O�o��
        -- ----------------------------------------------------
        IF ( lv_locat_code <> lc_init ) THEN
--
          -- �󒍃w�b�_�O���[�v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- �o�ɑq�ɃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'locat_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.locat_code ;
        -- �o�ɑq�ɖ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'locat_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.locat_name ;
        -- �o�ɓ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_to_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.ship_to_date ;
        -- �˗��m��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.request_no ;
        -- �����m��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'order_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.order_no ;
        -- ���דE�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'description' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.description ;
--
        -- ----------------------------------------------------
        -- �u���C�N���f�p���ڂ̑ޔ�
        -- ----------------------------------------------------
        lv_locat_code   := lr_ref.locat_code ;
        lv_ship_to_date := lr_ref.ship_to_date ;
        lv_request_no   := lr_ref.request_no ;
--
      END IF ;
--
      -- ====================================================
      -- ���b�g�O���[�v
      -- ====================================================
      -- ----------------------------------------------------
      -- ���X�g�O���[�v�J�n�^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- �˗����[or���b�g�Ǘ��ΏۊO�̏ꍇ
      -- ----------------------------------------------------
      IF (  ( gr_param.use_purpose = gc_use_purpose_irai )
         OR ( lr_ref.lot_ctl       = gc_lot_ctl_n        ) ) THEN
--
        -- ----------------------------------------------------
        -- �O���[�v�J�n�^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_lot' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- �f�[�^�^�O�o��
        -- ----------------------------------------------------
        -- ���b�g�ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
        -- �����N����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
        -- �ܖ�����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
        -- �ŗL�L��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
        -- ����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'frequent_qty' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.frequent_qty ;
        -- ����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quantity' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.quantity ;
--
        -- ----------------------------------------------------
        -- �O���[�v�I���^�O�o��
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lot' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- �w�����[or���b�g�Ǘ��Ώۂ̏ꍇ
      -- ----------------------------------------------------
      ELSE
--
        -- ====================================================
        -- �J�[�\���I�[�v��
        -- ====================================================
        -- �Ώەi�ڂ��u���i�v�̏ꍇ
        IF ( lr_ref.item_div = gc_item_div_sei ) THEN
          -- ���i�p�ɕ��ѕς��Ē��o
          OPEN lc_ref_lot FOR lc_sql_lot || lc_sql_order_by_1
          USING lr_ref.order_line_id
               ,lr_ref.item_id
          ;
        -- �Ώەi�ڂ��u���i�v�ȊO�̏ꍇ
        ELSE
          -- ���i�ȊO�p�ɕ��ѕς��Ē��o
          OPEN lc_ref_lot FOR lc_sql_lot || lc_sql_order_by_2
          USING lr_ref.order_line_id
               ,lr_ref.item_id
          ;
        END IF ;
--
        <<lot_data_loop>>
        LOOP
--
          FETCH lc_ref_lot INTO lr_ref_lot ;
          EXIT WHEN lc_ref_lot%NOTFOUND ;
--
          -- ----------------------------------------------------
          -- �O���[�v�J�n�^�O�o��
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- �f�[�^�^�O�o��
          -- ----------------------------------------------------
          -- ���b�g�ԍ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref_lot.lot_no ;
          -- �����N����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref_lot.product_date ;
          -- �ܖ�����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref_lot.use_by_date ;
          -- �ŗL�L��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref_lot.original_char ;
          -- ����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'frequent_qty' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref_lot.frequent_qty ;
          -- ����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quantity' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref_lot.quantity ;
--
          -- ----------------------------------------------------
          -- �O���[�v�I���^�O�o��
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END LOOP lot_data_loop ;
--
      END IF ;
--
      -- ----------------------------------------------------
      -- ���X�g�O���[�v�J�n�^�O
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- ----------------------------------------------------
    -- �O���[�v�I���^�O
    -- ----------------------------------------------------
    -- �󒍃w�b�_�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �󒍃w�b�_���X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �󒍖��׃O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �󒍖��׃��X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �i�ڃO���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �i�ڃ��X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �i�ڋ敪�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �i�ڋ敪���X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ���i�敪�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ���i�敪���X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ���ɓ��O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ship' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ���ɓ����X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �z����O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- �z���惊�X�g�O���[�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �J�[�\���N���[�Y
    -- ====================================================
    CLOSE lc_ref ;
--
    -- ====================================================
    -- �A�E�g�p�����[�^�Z�b�g
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode := lv_retcode ;    --    ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg  := lv_errmsg ;     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  EXCEPTION
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- �v���O������
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
    IF ( ic_type = 'D' ) THEN
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_use_purpose        IN     VARCHAR2         -- 01 : �g�p�ړI
     ,iv_locat_code         IN     VARCHAR2         -- 02 : �o�ɑq��
     ,iv_date_from          IN     VARCHAR2         -- 03 : �o�ɓ�From
     ,iv_date_to            IN     VARCHAR2         -- 04 : �o�ɓ�To
     ,iv_prod_div           IN     VARCHAR2         -- 05 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         -- 06 : �i�ڋ敪
     ,iv_item_code          IN     VARCHAR2         -- 07 : �i��
     ,iv_deliver_to_code    IN     VARCHAR2         -- 08 : �z����
     ,iv_security_div       IN     VARCHAR2         -- 09 : �L���Z�L�����e�B�敪
     ,ov_errbuf            OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT     VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_xml_string           VARCHAR2(32000) ;
    lv_err_code             VARCHAR2(10) ;
    ln_retcode              NUMBER ;
--
    get_value_expt        EXCEPTION ;     -- �l�擾�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- -----------------------------------------------------
    -- �p�����[�^�i�[
    -- -----------------------------------------------------
    gr_param.use_purpose      := iv_use_purpose ;                     -- 01 : �g�p�ړI
    gr_param.deliver_to_code  := iv_deliver_to_code ;                 -- 02 : �z����
    gr_param.date_from        := SUBSTR( iv_date_from, 1, 10 ) ;      -- 03 : �o�ɓ�From
    gr_param.date_to          := SUBSTR( iv_date_to  , 1, 10 ) ;      -- 04 : �o�ɓ�To
    gr_param.prod_div         := iv_prod_div ;                        -- 05 : ���i�敪
    gr_param.item_div         := iv_item_div ;                        -- 06 : �i�ڋ敪
    gr_param.item_code        := iv_item_code ;                       -- 07 : �i��
    gr_param.locat_code       := iv_locat_code ;                      -- 08 : �o�ɑq��
    gr_param.security_div     := iv_security_div ;                    -- 09 : �L���Z�L�����e�B�敪
--
    IF gr_param.date_to IS NULL THEN
      gr_param.date_to := gc_max_date_char ;
    END IF ;
--
    -- -----------------------------------------------------
    -- ���[�^�C�g���ݒ�
    -- -----------------------------------------------------
    -- �˗��̏ꍇ
    IF ( gr_param.use_purpose = gc_use_purpose_irai ) THEN
      gv_report_name := gc_report_name_irai ;
    ELSE
      gv_report_name := gc_report_name_shij ;
    END IF ;
    -- -----------------------------------------------------
    -- �c�ƒP�ʎ擾
    -- -----------------------------------------------------
    gn_prof_org_id := FND_PROFILE.VALUE( gc_prof_org_id ) ;
    IF ( gn_prof_org_id IS NULL ) THEN
      lv_err_code := gc_err_code_no_prof ;
      RAISE get_value_expt ;
    END IF ;
--
    -- =====================================================
    -- �f�[�^�擾�r�p�k����
    -- =====================================================
    prc_create_sql
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���O�C�����[�U�[���o��
    -- =====================================================
    prc_create_xml_data_user
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �w�l�k�t�@�C���f�[�^�ҏW
    -- =====================================================
    -- --------------------------------------------------
    -- ���X�g�O���[�v�J�n�^�O
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ���[�^�C�g��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_name ;
--
    -- --------------------------------------------------
    -- �w�l�k�f�[�^�ҏW�������Ăяo���B
    -- --------------------------------------------------
    prc_create_xml_data
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- --------------------------------------------------
    -- ���X�g�O���[�v�I���^�O
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ==================================================
    -- ���[�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF ( gn_data_cnt = 0 ) THEN
--
      -- --------------------------------------------------
      -- �O�����b�Z�[�W�̎擾
      -- --------------------------------------------------
      ov_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,gc_err_code_no_data ) ;
--
      -- --------------------------------------------------
      -- ���b�Z�[�W�̐ݒ�
      -- --------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <report_name>' || gv_report_name || '</report_name>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <lg_deliver>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <g_deliver>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <lg_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <g_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <lg_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <g_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <position>1</position>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <lg_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  <g_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                    <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  </g_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                </lg_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </g_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </lg_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </g_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </lg_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </g_deliver>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </lg_deliver>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </data_info>' ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- --------------------------------------------------
      -- �w�l�k�o��
      -- --------------------------------------------------
      -- �w�l�k�f�[�^���o��
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name  -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value  -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type  -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_data_table ;
--
    END IF ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_application_po
                     ,iv_name           => lv_err_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_use_purpose        IN     VARCHAR2         -- 01 : �g�p�ړI
     ,iv_deliver_to_code    IN     VARCHAR2         -- 02 : �z����
     ,iv_date_from          IN     VARCHAR2         -- 03 : �o�ɓ�From
     ,iv_date_to            IN     VARCHAR2         -- 04 : �o�ɓ�To
     ,iv_prod_div           IN     VARCHAR2         -- 05 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         -- 06 : �i�ڋ敪
     ,iv_item_code          IN     VARCHAR2         -- 07 : �i��
     ,iv_locat_code         IN     VARCHAR2         -- 08 : �o�ɑq��
     ,iv_security_div       IN     VARCHAR2         -- 09 : �L���Z�L�����e�B�敪
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'xxcmn820004c.main' ;  -- �v���O������
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
    submain
      (
        iv_use_purpose        => iv_use_purpose       -- 01 : �g�p�ړI
       ,iv_deliver_to_code    => iv_deliver_to_code   -- 02 : �z����
       ,iv_date_from          => iv_date_from         -- 03 : �o�ɓ�From
       ,iv_date_to            => iv_date_to           -- 04 : �o�ɓ�To
       ,iv_prod_div           => iv_prod_div          -- 05 : ���i�敪
       ,iv_item_div           => iv_item_div          -- 06 : �i�ڋ敪
       ,iv_item_code          => iv_item_code         -- 07 : �i��
       ,iv_locat_code         => iv_locat_code        -- 08 : �o�ɑq��
       ,iv_security_div       => iv_security_div      -- 09 : �L���Z�L�����e�B�敪
       ,ov_errbuf         => lv_errbuf                            -- �G���[�E���b�Z�[�W
       ,ov_retcode        => lv_retcode                           -- ���^�[���E�R�[�h
       ,ov_errmsg         => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W
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
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
--
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxpo440003c ;
/
