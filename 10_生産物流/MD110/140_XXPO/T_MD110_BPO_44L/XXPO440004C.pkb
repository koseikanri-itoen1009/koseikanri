CREATE OR REPLACE PACKAGE BODY xxpo440004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440004(body)
 * Description      : ���o�ɍ��ٖ��ו\
 * MD.050/070       : �L���x�����[Issue1.0(T_MD050_BPO_444)
 *                    �L���x�����[Issue1.0(T_MD070_BPO_44L)
 * Version          : 1.3
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_create_xml_data_user    PROCEDURE : �^�O�o�� - ���[�U�[��� (L-1)
 *  prc_create_sql              PROCEDURE : �f�[�^�擾�r�p�k���� (L-2)
 *  prc_create_xml_data         PROCEDURE : �w�l�k�f�[�^�ҏW (L-3)
 *  convert_into_xml            FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  submain                     PROCEDURE : ���C�������v���V�[�W��
 *  main                        PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/18    1.0   Yusuke Tabata   �V�K�쐬
 *  2008/05/20    1.1   Yusuke Tabata   �����ύX�v��Seq95(���t�^�p�����[�^�^�ϊ�)�Ή�
 *  2008/05/28    1.2   Yusuke Tabata   �����s��Ή�(�o�׎��ьv��ς̃R�[�h���)
 *  2008/07/01    1.3   �Ŗ�            �����ύX�v��142
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
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo440004C' ;      -- �p�b�P�[�W��
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXPO440004T' ;      -- ���[ID
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
  -- �󒍃J�e�S���F�󒍃J�e�S���R�[�h
  gc_order_cat_r          CONSTANT VARCHAR2(10) := 'RETURN' ; -- �ԕi
  -- �󒍃J�e�S���F�o�׎x���敪
  gc_sp_class_prov        CONSTANT VARCHAR2(1)  := '2' ;      -- �x���˗�
  -- �󒍃J�e�S���F�o�׎x���󕥃J�e�S��
  gc_sp_category_s        CONSTANT VARCHAR2(2)  := '05' ;     -- �L���o��
  -- �󒍃w�b�_�A�h�I���F�ŐV�t���O�iYesNo�敪�j
  gc_yn_div_y             CONSTANT VARCHAR2(1)  := 'Y' ;    -- YES
  gc_yn_div_n             CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- �󒍃w�b�_�A�h�I���F�X�e�[�^�X
  gc_req_status_p_ccl     CONSTANT VARCHAR2(2)  := '99' ;   -- ���
-- UPDATE START 2008/5/28 YTabata --
/**
  gc_req_status_s_cmpc    CONSTANT VARCHAR2(2)  := '04' ;   -- �o�׎��ьv���
**/
  gc_req_status_s_cmpc    CONSTANT VARCHAR2(2)  := '08' ;   -- �o�׎��ьv���
-- UPDATE END   2008/5/28 YTabata --
  -- �󒍃w�b�_�A�h�I���F�ʒm�X�e�[�^�X
  gc_notif_status_ok      CONSTANT VARCHAR2(2)  := '40' ;   -- �m��ʒm��
  -- �ړ����b�g�ڍ׃A�h�I���F�����^�C�v
  gc_doc_type_prov        CONSTANT VARCHAR2(2) := '30' ;    -- �x���w��
  -- �ړ����b�g�ڍ׃A�h�I���F���R�[�h�^�C�v
  gc_rec_type_inst        CONSTANT VARCHAR2(2) := '10' ;    -- �w��
  gc_rec_type_stck        CONSTANT VARCHAR2(2) := '20' ;    -- �o�Ɏ���
  gc_rec_type_dlvr        CONSTANT VARCHAR2(2) := '30' ;    -- ���Ɏ���
  -- �N�C�b�N�R�[�h�F���َ��R�R�[�h
  gc_diff_reason_nio      CONSTANT VARCHAR2(2) := '1' ;    -- 1.�o����
  gc_diff_reason_no       CONSTANT VARCHAR2(2) := '2' ;    -- 2.�o��
  gc_diff_reason_ni       CONSTANT VARCHAR2(2) := '3' ;    -- 3.����
  gc_diff_reason_diff     CONSTANT VARCHAR2(2) := '4' ;    -- 4.���ٗL
  gc_diff_reason_all      CONSTANT VARCHAR2(2) := '5' ;    -- 5.�S��
  gc_lookup_type_diff_reason CONSTANT VARCHAR2(16) := 'XXPO_DIFF_REASON' ;  -- ���َ��R
  -- �N�C�b�N�R�[�h�F���̑�
  gc_language                CONSTANT VARCHAR2(2)  := 'JA' ;
  -- �i�ڋ敪
  gc_item_div_prod       CONSTANT VARCHAR2(1) := '5' ;     -- ���i
  -- ���t�}�X�N
  gc_date_mask              CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- �N���������b�}�X�N
  gc_date_mask_s            CONSTANT VARCHAR2(21) := 'MM/DD' ;                 -- �����}�X�N
  gc_date_mask_ja           CONSTANT VARCHAR2(19) := 'YYYY"�N"MM"��"DD"��' ;   -- �N����(JA)�}�X�N
  -- �o��
  gc_tag_type_t           CONSTANT VARCHAR2(1)  := 'T' ;
  gc_tag_type_d           CONSTANT VARCHAR2(1)  := 'D' ;
  ------------------------------
  -- ���̑�
  ------------------------------
  gc_max_date_char        CONSTANT VARCHAR2(10) := '4712/12/31' ;
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���^
  -- ==================================================
--
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
      diff_reason_code   VARCHAR2(1)   -- 01 : ���َ��R
      ,deliver_from_code VARCHAR2(4)   -- 02 : �o�ɑq��
      ,prod_div          VARCHAR2(1)   -- 03 : ���i�敪
      ,item_div          VARCHAR2(1)   -- 04 : �i�ڋ敪
      ,date_from         DATE          -- 05 : �o�ɓ�From
      ,date_to           DATE          -- 06 : �o�ɓ�To
      ,dlv_vend_code     VARCHAR2(4)   -- 07 : �z����
      ,request_no        VARCHAR2(12)  -- 08 : �˗�No
      ,item_code         VARCHAR2(7)   -- 09 : �i��
      ,dept_code         VARCHAR2(4)   -- 10 : �S������
      ,security_div      VARCHAR2(1)   -- 11 : �L���Z�L�����e�B�敪
    ) ;
--
  -- ���o�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl IS RECORD
    (
      deliver_from_code xxcmn_item_locations2_v.segment1%TYPE               -- �o�ɑq�Ɂi�o�ɑq�ɃR�[�h�j
      ,deliver_from_name xxcmn_item_locations2_v.description%TYPE           -- �o�ɑq�Ɂi�o�ɑq�ɖ��j
      ,prod_div_type     xxcmn_item_categories4_v.prod_class_code%TYPE      -- ���i�敪�i���i�敪�R�[�h�j
      ,prod_div_value    xxcmn_item_categories4_v.prod_class_name%TYPE      -- ���i�敪�i���i�敪���j
      ,item_div_type     xxcmn_item_categories4_v.item_class_code%TYPE      -- �i�ڋ敪(�i�ڋ敪�R�[�h)
      ,item_div_value    xxcmn_item_categories4_v.item_class_name%TYPE      -- �i�ڋ敪�i�i�ڋ敪��
      ,shipped_date      VARCHAR2(5)                                        -- �o�ɓ�(MM/DD)
      ,arrival_date      VARCHAR2(5)                                        -- ���ɓ�(MM/DD)
      ,dlv_vend_code     xxcmn_vendor_sites2_v.vendor_site_code%TYPE        -- �z����i�z����R�[�h�j
      ,dlv_vend_name     xxcmn_vendor_sites2_v.vendor_site_name%TYPE        -- �z����i�z���於�j
      ,request_no        xxwsh_order_headers_all.request_no%TYPE            -- �˗�No
      ,item_no           xxcmn_item_mst2_v.item_no%TYPE                     -- �i�ځi�i�ڃR�[�h�j
      ,item_name         xxcmn_item_mst2_v.item_desc1%TYPE                  -- �i�ځi�i�ږ��j
      ,futai_code        xxwsh_order_lines_all.futai_code%TYPE              -- �t��
      ,lot_no            ic_lots_mst.lot_no%TYPE                            -- ���b�gNo
      ,maked_date        ic_lots_mst.attribute1%TYPE                        -- ������
      ,limit_date        ic_lots_mst.attribute3%TYPE                        -- �ܖ�����
      ,orgn_sign         ic_lots_mst.attribute2%TYPE                        -- �ŗL�L��
      ,inst_quant        xxinv_mov_lot_details.actual_quantity%TYPE         -- �w����
      ,sipped_quant      xxinv_mov_lot_details.actual_quantity%TYPE         -- �o�ɐ�
      ,arrv_quant        xxinv_mov_lot_details.actual_quantity%TYPE         -- ���ɐ�
      ,diff_raeson_code  VARCHAR(1)                                         -- ���َ��R�i���َ��R�R�[�h�j
      ,diff_reason_name  fnd_lookup_values.meaning%TYPE                     -- ���َ��R�i���ٖ��j
    ) ;
--
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gr_param              rec_param_data ;      -- �p�����[�^
  gn_data_cnt           NUMBER := 0 ;         -- �����f�[�^�J�E���^
  gv_sql                VARCHAR2(32000);     -- �f�[�^�擾�p�r�p�k
--
  gt_xml_data_table     XML_DATA ;            -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx            NUMBER  := 0 ;        -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
  -- ���O�C�����[�U�[�h�c
  gn_user_id            fnd_user.user_id%TYPE := FND_GLOBAL.USER_ID ;
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
   * Description      : ���[�U�[���^�O�o��(L-1)
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
    -- ���[�U�[�f�J�n�^�O
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
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, gc_date_mask ) ;
    -- ���O�C�����[�U�[�F��������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
    -- ���O�C�����[�U�[�F���[�U�[��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- ====================================================
    -- ���[�U�[�f�I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �p�����[�^�f�J�n�^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- �f�[�^�^�O
    -- ====================================================
    -- �o�ɓ�FORM
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'date_from' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(gr_param.date_from,gc_date_mask_ja) ;
    -- �o�ɓ�TO
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'date_to' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(gr_param.date_to,gc_date_mask_ja) ;
--
    -- ====================================================
    -- �p�����[�^�f�I���^�O
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/param_info' ;
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
   * Procedure Name   : prc_create_sql(L-2)
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
    lv_date_from  VARCHAR2(150)   ;
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    
    -- ====================================================
    -- ��������
    -- ====================================================
    -- �p�����[�^DATE_FROM�����`
    lv_date_from :=  'FND_DATE.STRING_TO_DATE(' ;
    lv_date_from :=  lv_date_from || '''' || TO_CHAR(gr_param.date_from,gc_date_mask) ||'''' || ',' ;
    lv_date_from :=  lv_date_from || '''' || gc_date_mask ||'''' || ')';
    -- ====================================================
    -- �r�d�k�d�b�s�吶��
    -- ====================================================
    lv_select := ' SELECT'
    || ' xil.segment1                 AS deliver_from_code'       -- �o�ɑq�ɃR�[�h
    || ',xil.description              AS deliver_from_name'       -- �o�ɑq�ɖ���
    || ',xic.prod_class_code          AS prod_div_type'           -- ���i�敪
    || ',xic.prod_class_name          AS prod_div_value'          -- ���i�敪����
    || ',xic.item_class_code          AS item_div_type'           -- �i�ڋ敪
    || ',xic.item_class_name          AS item_div_value'          -- �i�ڋ敪����
    -- ���їL�F���ѓ��^���F�\���
    || ',TO_CHAR(NVL(xoha.shipped_date'
    || '            ,xoha.schedule_ship_date) '
    || '         ,''' || gc_date_mask_s || ''' ) AS shipped_date' -- �o�ɓ�
    || ',TO_CHAR(NVL(xoha.arrival_date'	
    || '            ,xoha.schedule_arrival_date) '
    || '         ,''' || gc_date_mask_s || ''' ) AS arrival_date' -- ���ɓ�
    || ',xvs.vendor_site_code         AS dlv_vend_code'           -- �z����R�[�h
    || ',xvs.vendor_site_short_name   AS dlv_vend_name'           -- �z���於��
    || ',xoha.request_no              AS request_no'              -- �˗��m��
    || ',xim.item_no                  AS item_code'               -- �i�ڃR�[�h
    || ',xim.item_short_name          AS item_name'               -- �i�ږ���
    || ',xola.futai_code              AS futai_code'              -- �t��
    -- ���b�g���o��:���b�g�Ǘ��i����
    || ',CASE xim.lot_ctl'
    || '   WHEN 0 THEN NULL'
    || '   ELSE ilm.lot_no'
    || ' END                          AS lot_no'                  -- ���b�gNo
    || ',CASE xim.lot_ctl'
    || '   WHEN 0 THEN NULL'
    || '   ELSE ilm.attribute1'
    || ' END                          AS maked_date'              -- ������
    || ',CASE xim.lot_ctl'
    || '   WHEN 0 THEN NULL'
    || '   ELSE ilm.attribute3'
    || ' END                          AS limit_date'              -- �ܖ�����
    || ',CASE xim.lot_ctl'
    || '   WHEN 0 THEN NULL'
    || '   ELSE ilm.attribute2'
    || ' END                          AS orgn_sign'               -- �ŗL�L��
    || ',NVL(xmldiv.inst_quant,0)     AS inst_quant'              -- �x����
    -- �X�e�[�^�X�F�o�׎��ьv��ψȊO��NULL
    || ',CASE xoha.req_status'
    || '   WHEN ''' || gc_req_status_s_cmpc || ''' THEN '
    || '     xmldiv.sipped_quant'
    || '   ELSE NULL'
    || ' END                          AS sipped_quant'            -- �o�ɐ�
    || ',xmldiv.arrv_quant            AS arrv_quant'              -- ���ɐ�
    || ',xmldiv.diff_reason_code      AS diff_raeson_code'        -- ���َ��R�R�[�h
    || ',flv.meaning                  AS diff_reason_name'        -- ���ٖ�
    ;
--
    -- ====================================================
    -- �e�q�n�l�吶��
    -- ====================================================
    lv_from := ' FROM'
    || ' oe_transaction_types_all   otta'   -- �󒍃^�C�v
    || ',xxwsh_order_headers_all    xoha'   -- �󒍃w�b�_�A�h�I��
    || ',xxwsh_order_lines_all      xola'   -- �󒍖��׃A�h�I��
    || ',xxcmn_item_locations2_v    xil'    -- OPM�ۊǏꏊ���VIEW
    || ',xxcmn_vendor_sites2_v      xvs'    -- �d����T�C�gView
    || ',xxcmn_item_mst2_v          xim'    -- OPM�i�ڏ��View
    || ',xxcmn_item_categories4_v   xic'    -- OPM�i�ڃJ�e�S������View
    || ',ic_lots_mst                ilm'    -- OPM���b�g�}�X�^
    || ',fnd_lookup_values          flv'    -- �N�C�b�N�R�[�h(���َ��R)
    -- ----------------------------------------------------
    -- �ړ����b�g�ڍ׏��擾�C�����C��VIEW
    -- ----------------------------------------------------
    || ',('	
    || '  SELECT'
    || '   xmld1.mov_line_id'
    || '  ,xmld1.item_id'
    || '  ,xmld1.lot_id'
    || '  ,xmld2.actual_quantity               AS inst_quant'       -- �w������
    || '  ,DECODE( xmld1.req_status,''' || gc_req_status_s_cmpc || ''''
    || '          ,xmld3.actual_quantity,NULL) AS sipped_quant'     -- �o�ɐ���
    || '  ,xmld4.actual_quantity               AS arrv_quant'       -- ���ɐ���
    -- ���َ��R�R�[�h
    -- �o�׎��ьv��ς̏ꍇ�̂ݏo�ɗL
    || '  ,CASE '
    || '    WHEN xmld1.req_status = ''' || gc_req_status_s_cmpc || ''' THEN '
    || '      CASE '
                -- �o�ɐ���/���ɐ���
    || '        WHEN ((xmld3.actual_quantity IS NULL) AND (xmld4.actual_quantity IS NULL)) THEN'
    || '          ''' || gc_diff_reason_nio  || ''''
                -- �o�ɐ���/���ɐ��L
    || '        WHEN ((xmld3.actual_quantity IS NULL) AND (xmld4.actual_quantity >= 0)) THEN'
    || '          ''' || gc_diff_reason_no  || ''''
                -- �o�ɐ��L/���ɐ���
    || '        WHEN ((xmld4.actual_quantity IS NULL) AND (xmld3.actual_quantity >= 0)) THEN'
    || '          ''' || gc_diff_reason_ni  || ''''
                -- �x�����F���o�ɐ��Ƃ̍��ٗL
    || '        WHEN ((xmld3.actual_quantity >= 0) AND (xmld4.actual_quantity >= 0)'
    || '        AND  ((xmld2.actual_quantity - xmld3.actual_quantity <> 0)'
    || '          OR (xmld2.actual_quantity - xmld4.actual_quantity <> 0)))'
    || '        THEN'
    || '          ''' || gc_diff_reason_diff  || ''''
                -- ���ٖ�
    || '        ELSE' 
    || '          NULL' 
    || '      END'
    || '  ELSE'
    || '      CASE '
                -- �o�ɐ���/���ɐ���
    || '        WHEN (xmld4.actual_quantity IS NULL) THEN'
    || '          ''' || gc_diff_reason_nio  || ''''
                -- �o�ɐ���/���ɐ��L
    || '        WHEN (xmld4.actual_quantity >= 0) THEN'
    || '          ''' || gc_diff_reason_no  || ''''
    || '      END '
    || '  END AS diff_reason_code'
    || '  FROM'
    || '  ('
    || '    SELECT'
    || '     xohas.req_status'
    || '    ,xmlds.mov_line_id'
    || '    ,xmlds.item_id'
    || '    ,xmlds.lot_id'
    || '    FROM'
    || '     xxinv_mov_lot_details   xmlds'
    || '    ,xxwsh_order_headers_all xohas'   -- �󒍃w�b�_�A�h�I��
    || '    ,xxwsh_order_lines_all   xolas'   -- �󒍖��׃A�h�I��
    || '    WHERE'
    || '    xmlds.document_type_code   = '''  || gc_doc_type_prov || ''''
    || '    AND xohas.order_header_id  = xolas.order_header_id'
    || '    AND xolas.order_line_id    = xmlds.mov_line_id' 
    || '    GROUP BY'
    || '     xohas.req_status'
    || '    ,xmlds.mov_line_id'
    || '    ,xmlds.item_id'
    || '    ,xmlds.lot_id'
    || '  )                     xmld1,' -- �ړ����b�g�ڍ�( ���C�� )�����p
    || '  xxinv_mov_lot_details xmld2,' -- �ړ����b�g�ڍ�(�w������)�O������
    || '  xxinv_mov_lot_details xmld3,' -- �ړ����b�g�ڍ�(�o�ɐ���)�O������
    || '  xxinv_mov_lot_details xmld4'  -- �ړ����b�g�ڍ�(���ɐ���)�O������
    || '  WHERE'
    || '  xmld2.document_type_code(+)     = ''' || gc_doc_type_prov || ''''
    || '  AND xmld2.record_type_code(+)   = ''' || gc_rec_type_inst || ''''
    || '  AND xmld1.mov_line_id           = xmld2.mov_line_id(+) '
    || '  AND xmld1.item_id               = xmld2.item_id(+)'
    || '  AND xmld1.lot_id                = xmld2.lot_id(+) '   
    || '  AND xmld3.document_type_code(+) = ''' || gc_doc_type_prov || ''''
    || '  AND xmld3.record_type_code(+)   = ''' || gc_rec_type_stck || ''''
    || '  AND xmld1.mov_line_id           = xmld3.mov_line_id(+) '
    || '  AND xmld1.item_id               = xmld3.item_id(+) '
    || '  AND xmld1.lot_id                = xmld3.lot_id(+) '
    || '  AND xmld4.document_type_code(+) = ''' || gc_doc_type_prov || ''''
    || '  AND xmld4.record_type_code(+)   = ''' || gc_rec_type_dlvr || ''''
    || '  AND xmld1.mov_line_id           = xmld4.mov_line_id(+) '
    || '  AND xmld1.item_id               = xmld4.item_id(+) '
    || '  AND xmld1.lot_id                = xmld4.lot_id(+) '
    || ')                          xmldiv'  -- �ړ����b�g�ڍ׏��擾�C�����C��VIEW
    || ',xxpo_security_supply_v    xssv'    -- �L���x���Z�L�����e�BVIEW
    ;
--
    -- ====================================================
    -- �v�g�d�q�d�吶��
    -- ====================================================
    lv_where := ' WHERE'
    || ' xim.item_id                         = xic.item_id'             -- OPM�i�ڃJ�e�S����������
    || ' AND xola.shipping_inventory_item_id = xim.inventory_item_id'   -- OPM�i�ڏ��VIEW����
    || ' AND ' || lv_date_from || ' BETWEEN xim.start_date_active'
    || '                            AND     NVL( xim.end_date_active'
    || '                                    ,FND_DATE.STRING_TO_DATE(''' || gc_max_date_char || ''''
    || '                                                            ,''' || gc_date_mask     || '''))'
    || ' AND NVL( xola.delete_flag, ''' || gc_yn_div_n || ''')'
    ||                                '    = ''' || gc_yn_div_n || ''''
    || ' AND xoha.order_header_id          = xola.order_header_id'      -- �󒍖��׃A�h�I������
    || ' AND otta.org_id                   = '   || gn_prof_org_id
    || ' AND otta.attribute1               = ''' || gc_sp_class_prov || ''''
    || ' AND otta.order_category_code     <> ''' || gc_order_cat_r   || ''''
    || ' AND otta.attribute11              = ''' || gc_sp_category_s || ''''
    || ' AND xoha.order_type_id            = otta.transaction_type_id'  -- �󒍃^�C�v����
    || ' AND xoha.vendor_site_id           = xvs.vendor_site_id'        -- �d����}�X�^����
    || ' AND ' || lv_date_from || ' BETWEEN xvs.start_date_active'
    || '                            AND     NVL( xvs.end_date_active'
    || '                                    ,FND_DATE.STRING_TO_DATE(''' || gc_max_date_char || ''''
    || '                                                            ,''' || gc_date_mask     || '''))'
    || ' AND xoha.deliver_from_id          = xil.inventory_location_id' -- OPM�ۊǏꏊ���VIEW����
    || ' AND ' || lv_date_from || ' BETWEEN xil.date_from'
    || '                            AND     NVL( xil.date_to'
    || '                                    ,FND_DATE.STRING_TO_DATE(''' || gc_max_date_char || ''''
    || '                                                            ,''' || gc_date_mask     || '''))'
    || ' AND xoha.latest_external_flag     = ''' || gc_yn_div_y         || ''''
    || ' AND xoha.notif_status             = ''' || gc_notif_status_ok  || ''''
    || ' AND xoha.req_status              <> ''' || gc_req_status_p_ccl || ''''
    || ' AND NVL(xoha.shipped_date,xoha.schedule_ship_date) >=  ' || lv_date_from
    || ' AND xola.order_line_id            = xmldiv.mov_line_id'  -- �ړ����b�g�ڍ׃A�h�I������
    || ' AND xmldiv.item_id                = ilm.item_id'
    || ' AND xmldiv.lot_id                 = ilm.lot_id'          -- OPM���b�g�}�X�^����
    -- �L���x���Z�L�����e�BVIEW����
    || ' AND xssv.user_id                  = ''' || gn_user_id || ''''
    || ' AND xssv.security_class           ='''  || gr_param.security_div || ''''
    || ' AND xoha.vendor_code              = NVL(xssv.vendor_code,xoha.vendor_code)'
    || ' AND xoha.vendor_site_code         = NVL(xssv.vendor_site_code,xoha.vendor_site_code)'
    || ' AND xoha.deliver_from             = NVL(xssv.segment1,xoha.deliver_from)'
    || ' AND flv.lookup_type(+)            = ''' || gc_lookup_type_diff_reason || '''' 
    || ' AND flv.language(+)               = ''' || gc_language || '''' 
    || ' AND xmldiv.diff_reason_code       = flv.lookup_code(+)' -- �N�C�b�N�R�[�h(���َ��R)�O������
    ;
--
      -- ----------------------------------------------------
      -- �C�Ӄp�����[�^�ɂ�����
      -- ----------------------------------------------------
--
      -- ���َ��R
      IF (gr_param.diff_reason_code IS NOT NULL) THEN
        -- �p�����[�^���َ��R�F�u5�F�S�āv�̏ꍇ�@���َ��R�i1�`4�j�̃��R�[�h�𒊏o
        IF (gr_param.diff_reason_code = gc_diff_reason_all) THEN
          lv_where := lv_where 
          || ' AND xmldiv.diff_reason_code IN ('''  || gc_diff_reason_nio  || '''' 
          || '                                 ,''' || gc_diff_reason_ni   || ''''
          || '                                 ,''' || gc_diff_reason_no   || ''''
          || '                                 ,''' || gc_diff_reason_diff || ''')'
          ;
        -- 1�`4�̏ꍇ�́A�Y�����R�[�h�𒊏o
        ELSE
          lv_where := lv_where 
          || ' AND xmldiv.diff_reason_code =  ''' || gr_param.diff_reason_code || '''' 
          ;
        END IF;
      END IF ;
--
      -- �o�ɑq��
      IF (gr_param.deliver_from_code IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xoha.deliver_from = ''' || gr_param.deliver_from_code || '''' 
        ;
      END IF ;
--
      -- ���i�敪
      IF (gr_param.prod_div IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xic.prod_class_code = ''' || gr_param.prod_div || '''' 
        ;
      END IF ;
--
      -- �i�ڋ敪
      IF (gr_param.item_div IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xic.item_class_code = ''' || gr_param.item_div || '''' 
        ;
      END IF ;
--
      -- �z����
      IF (gr_param.dlv_vend_code IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xoha.vendor_site_code = ''' || gr_param.dlv_vend_code || '''' 
        ;
      END IF ;
--
      -- �˗�No
      IF (gr_param.request_no IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xoha.request_no = ''' || gr_param.request_no || '''' ;
      END IF ;
--
      -- �i��
      IF (gr_param.item_code IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xola.shipping_item_code = ''' || gr_param.item_code || ''''
        ;
      END IF ;
--
      -- �S������
      IF (gr_param.dept_code IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xoha.instruction_dept = ''' || gr_param.dept_code || '''' 
        ;
      END IF ;
--
      -- �o�ɓ�TO
      IF (gr_param.date_to IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND NVL(xoha.shipped_date,xoha.schedule_ship_date)'
        || '       <= FND_DATE.STRING_TO_DATE(NVL(''' || TO_CHAR(gr_param.date_to 
                                                                 ,gc_date_mask) || ''''
        || '                                  ,''' || gc_max_date_char || ''')'
        || '          ,''' || gc_date_mask     || ''')'
        ;
      END IF ;
--
    -- ====================================================
    -- �n�q�c�d�q  �a�x�吶��
    -- ====================================================
    lv_order_by := ' ORDER BY'
    || ' xoha.deliver_from'
    || ',xic.prod_class_code'
    || ',xic.item_class_code'
    -- ���їL�F���ѓ��^���F�\���
    || ',NVL(xoha.shipped_date,xoha.schedule_ship_date)'
    || ',xoha.vendor_site_code'
    || ',xoha.request_no'
    || ',TO_NUMBER(xola.shipping_item_code)'
    || ',xola.futai_code'
    -- �i�ڋ敪�����i�̏ꍇ�́u�����N����+�ŗL�L���v����ȊO�u���b�gNo�v
    || ',DECODE(xic.item_class_code,''' || gc_item_div_prod || ''''
    || '       ,CONCAT(ilm.attribute1,ilm.attribute2),ilm.lot_no)'
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
   /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬(L-3)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W
     ,ov_retcode        OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h
     ,ov_errmsg         OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- *** ���[�J���E��O���� ***
    dtldata_notfound_expt      EXCEPTION ;     -- �Ώۃf�[�^0����O
    -- *** ���[�J���ϐ� ***
    lt_data_rec        tab_data_type_dtl ;
    ln_sum_sipped_quant    NUMBER :=0 ;
    ln_sum_inst_quant      NUMBER :=0 ;
    ln_sum_arrv_quant      NUMBER :=0;
--
  BEGIN
--

    EXECUTE IMMEDIATE gv_sql BULK COLLECT INTO lt_data_rec ;
    gn_data_cnt := lt_data_rec.count ;
--
    IF ( gn_data_cnt > 0 ) THEN
      <<main_data_loop>>
      FOR i IN 1..lt_data_rec.count LOOP
        -- ��������
        IF ( i = 1 ) THEN
          ------------------------------
          -- �o�ɑq��L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_deliver_from_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �o�ɑq�ɂf�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_deliver_from' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɑq�ɃR�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_from_code;
          -- �o�ɑq�ɖ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_from_name;
          ------------------------------
          -- ���i�敪L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_prod_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���i�敪�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- ���i�敪�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_type ;
          -- ���i�敪��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_value ;
          ------------------------------
          -- �i�ڋ敪L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �i�ڋ敪�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_type;
          -- �i�ڋ敪����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_value;
          ------------------------------
          -- �o�ɓ�L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �o�ɓ��f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɓ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).shipped_date;
          ------------------------------
          -- ����L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
        -- �J�����g���R�[�h�ƑO���R�[�h�̏o�ɓ����s��v
        ELSIF ((lt_data_rec(i-1).shipped_date       <> lt_data_rec(i).shipped_date)
        AND   (lt_data_rec(i-1).item_div_type      = lt_data_rec(i).item_div_type)
        AND   (lt_data_rec(i-1).prod_div_type      = lt_data_rec(i).prod_div_type)
        AND   (lt_data_rec(i-1).deliver_from_code  = lt_data_rec(i).deliver_from_code))
        THEN
          ------------------------------
          -- ����L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɐ��ʌv
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_sipped_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_sipped_quant ;
          -- �o�ɐ��ʌv
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_inst_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_inst_quant ;
          -- �o�ɐ��ʌv
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_arrv_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_arrv_quant ;
          ------------------------------
          -- �o�ɓ��f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �o�ɓ��f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɓ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).shipped_date ;
          ------------------------------
          -- ����L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɓ��v������
          ln_sum_sipped_quant := 0 ;
          ln_sum_inst_quant   := 0 ;
          ln_sum_arrv_quant   := 0 ;
        -- �J�����g���R�[�h�ƑO���R�[�h�̕i�ڋ敪���s��v
        ELSIF ((lt_data_rec(i-1).item_div_type     <> lt_data_rec(i).item_div_type)
        AND   (lt_data_rec(i-1).prod_div_type      = lt_data_rec(i).prod_div_type)
        AND   (lt_data_rec(i-1).deliver_from_code  = lt_data_rec(i).deliver_from_code)) 
        THEN
          ------------------------------
          -- ����L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɐ��ʌv
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_sipped_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_sipped_quant ;
          -- �o�ɐ��ʌv
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_inst_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_inst_quant ;
          -- �o�ɐ��ʌv
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_arrv_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_arrv_quant ;
          ------------------------------
          -- �o�ɓ��f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �o�ɓ�L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �i�ڋ敪�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_type;
          -- �i�ڋ敪����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_value;
          ------------------------------
          -- �o�ɓ�L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �o�ɓ��f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɓ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).shipped_date ;
          ------------------------------
          -- ����L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɓ��v������
          ln_sum_sipped_quant := 0 ;
          ln_sum_inst_quant   := 0 ;
          ln_sum_arrv_quant   := 0 ;
--
        -- �J�����g���R�[�h�ƑO���R�[�h�̏��i�敪���s��v
        ELSIF ((lt_data_rec(i-1).prod_div_type     <> lt_data_rec(i).prod_div_type)
        AND   (lt_data_rec(i-1).deliver_from_code  = lt_data_rec(i).deliver_from_code))
        THEN
          ------------------------------
          -- ����L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɐ��ʌv
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_sipped_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_sipped_quant ;
          -- �o�ɐ��ʌv
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_inst_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_inst_quant ;
          -- �o�ɐ��ʌv
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_arrv_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_arrv_quant ;
          ------------------------------
          -- �o�ɓ��f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �o�ɓ�L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���i�敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���i�敪�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- ���i�敪�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_type;
          -- ���i�敪����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_value;
          ------------------------------
          -- �i�ڋ敪L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �i�ڋ敪�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_type;
          -- �i�ڋ敪����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_value;
          ------------------------------
          -- �o�ɓ�L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �o�ɓ��f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɓ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).shipped_date ;
          ------------------------------
          -- ����L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɓ��v������
          ln_sum_sipped_quant := 0 ;
          ln_sum_inst_quant   := 0 ;
          ln_sum_arrv_quant   := 0 ;
--
        -- �J�����g���R�[�h�ƑO���R�[�h�̏o�ɑq�ɂ��s��v
        ELSIF (lt_data_rec(i-1).deliver_from_code  <> lt_data_rec(i).deliver_from_code)  THEN
          ------------------------------
          -- ����L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɐ��ʌv
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_sipped_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_sipped_quant ;
          -- �o�ɐ��ʌv
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_inst_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_inst_quant ;
          -- �o�ɐ��ʌv
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_arrv_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_arrv_quant ;
          ------------------------------
          -- �o�ɓ��f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �o�ɓ�L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���i�敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���i�敪L�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �o�ɑq�ɂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver_from' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �o�ɑq�ɂf�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_deliver_from' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɑq�ɃR�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_from_code;
          -- �o�ɑq�ɖ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_from_name;
          ------------------------------
          -- ���i�敪L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_prod_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- ���i�敪�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- ���i�敪�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_type;
          -- ���i�敪����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_value;
          ------------------------------
          -- �i�ڋ敪L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �i�ڋ敪�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �i�ڋ敪�R�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_type;
          -- �i�ڋ敪����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_value;
          ------------------------------
          -- �o�ɓ�L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- �o�ɓ��f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɓ�
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).shipped_date ;
          ------------------------------
          -- ����L�f�J�n�^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- �o�ɓ��v������
          ln_sum_sipped_quant := 0 ;
          ln_sum_inst_quant   := 0 ;
          ln_sum_arrv_quant   := 0 ;
        END IF ;
--
        ------------------------------
        -- ���ׂf�J�n�^�O
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- ���ɓ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).arrival_date ;
        -- �z����R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dlv_vend_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).dlv_vend_code;
        -- �z���於��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dlv_vend_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).dlv_vend_name;
        -- �˗�No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).request_no;
        -- �i�ڃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_no;
        -- �i�ږ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_name;
        -- �t�уR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).futai_code;
        -- ���b�gNo
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).lot_no;
        -- �쐬��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'maked_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).maked_date;
        -- �ܖ�����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'limit_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).limit_date;
        -- �ŗL�L��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'orgn_sign' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).orgn_sign;
        -- �w������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'inst_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).inst_quant;
        -- �o�ɐ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sipped_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).sipped_quant;
        -- ���ɐ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrv_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).arrv_quant;
        -- ���ِ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'diff_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value 
              := NVL(lt_data_rec(i).sipped_quant,0) - NVL(lt_data_rec(i).arrv_quant,0);
        -- ���َ��R�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'diff_raeson_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).diff_raeson_code;
        -- ���َ��R��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'diff_reason_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).diff_reason_name;
        ------------------------------
        -- ���ׂf�I���^�O
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
        -- �o�ɓ��v���ڑ���
        ln_sum_sipped_quant := ln_sum_sipped_quant + NVL(lt_data_rec(i).sipped_quant,0) ;
        ln_sum_inst_quant   := ln_sum_inst_quant   + NVL(lt_data_rec(i).inst_quant,0)   ;
        ln_sum_arrv_quant   := ln_sum_arrv_quant   + NVL(lt_data_rec(i).arrv_quant,0)   ;
--
      END LOOP main_data_loop ;
--
      -- ======================================
      -- �I������
      -- ======================================
      ------------------------------
      -- ����L�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      -- �o�ɐ��ʌv
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_sipped_quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_sipped_quant ;
      -- �o�ɐ��ʌv
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_inst_quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_inst_quant ;
      -- �o�ɐ��ʌv
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_arrv_quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_arrv_quant ;
      ------------------------------
      -- �o�ɓ��f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_shiped_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �o�ɓ�L�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship_date_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �i�ڋ敪�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �i�ڋ敪L�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- ���i�敪�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- ���i�敪L�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �o�ɑq�ɂf�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver_from' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- �o�ɑq��L�f�I���^�O
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver_from_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    END IF ;
--
  EXCEPTION
--
    -- *** �Ώۃf�[�^0����O�n���h�� ***
    WHEN dtldata_notfound_expt THEN
      ov_retcode := gv_status_warn ;
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
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
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
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
      iv_diff_reason_code    IN   VARCHAR2  -- 01 : ���َ��R
     ,iv_deliver_from_code   IN   VARCHAR2  -- 02 : �o�ɑq��
     ,iv_prod_div            IN   VARCHAR2  -- 03 : ���i�敪
     ,iv_item_div            IN   VARCHAR2  -- 04 : �i�ڋ敪
     ,iv_date_from           IN   VARCHAR2  -- 05 : �o�ɓ�From
     ,iv_date_to             IN   VARCHAR2  -- 06 : �o�ɓ�To
     ,iv_dlv_vend_code       IN   VARCHAR2  -- 07 : �z����
     ,iv_request_no          IN   VARCHAR2  -- 08 : �˗�No
     ,iv_item_code           IN   VARCHAR2  -- 09 : �i��
     ,iv_dept_code           IN   VARCHAR2  -- 10 : �S������
     ,iv_security_div        IN   VARCHAR2  -- 11 : �L���Z�L�����e�B�敪
     ,ov_errbuf              OUT  VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode             OUT  VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg              OUT  VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_retcode              VARCHAR2(1) ;
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
    gr_param.diff_reason_code  := iv_diff_reason_code ;    -- 01 : ���َ��R
    gr_param.deliver_from_code := iv_deliver_from_code ;   -- 02 : �o�ɑq��
    gr_param.prod_div          := iv_prod_div ;            -- 03 : ���i�敪
    gr_param.item_div          := iv_item_div ;            -- 04 : �i�ڋ敪
-- UPDATE START 2008/5/20 YTabata --
    gr_param.date_from                                     -- 05 : �o�ɓ�From
        := FND_DATE.CANONICAL_TO_DATE(iv_date_from) ;
    gr_param.date_to                                       -- 06 : �o�ɓ�To
        := FND_DATE.CANONICAL_TO_DATE(iv_date_to) ;
/**
    gr_param.date_from
        := FND_DATE.STRING_TO_DATE(iv_date_from,gc_date_mask) ; -- 05 : �o�ɓ�From
    gr_param.date_to
        := FND_DATE.STRING_TO_DATE(iv_date_to,gc_date_mask) ;   -- 06 : �o�ɓ�To
**/
-- UPDATE END 2008/5/20 YTabata --

    gr_param.dlv_vend_code     := iv_dlv_vend_code ;       -- 07 : �z����
    gr_param.request_no        := iv_request_no ;          -- 08 : �˗�No
    gr_param.item_code         := iv_item_code ;           -- 09 : �i��
    gr_param.dept_code         := iv_dept_code ;           -- 10 : �S������
    gr_param.security_div      := iv_security_div ;        -- 11 : �L���Z�L�����e�B�敪
--
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
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <lg_deliver_from_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <g_deliver_from>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <lg_prod_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <g_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <lg_item_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <g_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </g_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </lg_item_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </g_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </lg_prod_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </g_deliver_from>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </lg_deliver_from_info>' ) ;
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
     ,iv_diff_reason_code   IN     VARCHAR2         -- 01 : ���َ��R
     ,iv_deliver_from_code  IN     VARCHAR2         -- 02 : �o�ɑq��
     ,iv_prod_div           IN     VARCHAR2         -- 03 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         -- 04 : �i�ڋ敪
     ,iv_date_from          IN     VARCHAR2         -- 05 : �o�ɓ�From
     ,iv_date_to            IN     VARCHAR2         -- 06 : �o�ɓ�To
     ,iv_dlv_vend_code      IN     VARCHAR2         -- 07 : �z����
     ,iv_request_no         IN     VARCHAR2         -- 08 : �˗�No
     ,iv_item_code          IN     VARCHAR2         -- 09 : �i��
     ,iv_dept_code          IN     VARCHAR2         -- 10 : �S������
     ,iv_security_div       IN     VARCHAR2         -- 11 : �L���Z�L�����e�B�敪
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
        iv_diff_reason_code   -- 01 : ���َ��R
       ,iv_deliver_from_code  -- 02 : �o�ɑq��
       ,iv_prod_div           -- 03 : ���i�敪
       ,iv_item_div           -- 04 : �i�ڋ敪
       ,iv_date_from          -- 05 : �o�ɓ�From
       ,iv_date_to            -- 06 : �o�ɓ�To
       ,iv_dlv_vend_code      -- 07 : �z����
       ,iv_request_no         -- 08 : �˗�No
       ,iv_item_code          -- 09 : �i��
       ,iv_dept_code          -- 10 : �S������
       ,iv_security_div       -- 11 : �L���Z�L�����e�B�敪
       ,lv_errbuf              -- �G���[�E���b�Z�[�W
       ,lv_retcode             -- ���^�[���E�R�[�h
       ,lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
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
END xxpo440004c ;
/
