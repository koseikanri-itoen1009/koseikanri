CREATE OR REPLACE PACKAGE BODY xxpo380002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO380002C(body)
 * Description      : �����˗���
 * MD.050/070       : �����˗��쐬Issue1.0  (T_MD050_BPO_380)
 *                    �����˗��쐬Issue1.0  (T_MD070_BPO_38B)
 * Version          : 1.5
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  prc_initialize            PROCEDURE : �O����(B-1)
 *  prc_get_report_data       PROCEDURE : �f�[�^�擾(B-2)
 *  prc_create_xml_data       PROCEDURE : �f�[�^�o��(B-3)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/06    1.0   Syogo Chinen     �V�K�쐬
 *  2008/06/17    1.1   T.Ikehara        TEMP�̈�G���[����̂��߁Axxpo_categories_v��
 *                                       �g�p���Ȃ��悤�ɂ���
 *  2008/06/24    1.2   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/06/27    1.3   T.Ikehara        ���ׂ��ő�s�o�́i30�s�o�́j�̎��ɁA
 *                                       ���v�����y�[�W�ɕ\������錻�ۂ��C��
 *  2008/07/04    1.4   I.Higa           TEMP�̈�G���[����̂��߁Axxcmn_item_categories4_v��
 *                                       �g�p���Ȃ��悤�ɂ���
 *  2010/03/31    1.5   M.Hokkanji       [E_�{�ғ�_02089]�Ή�
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
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo380002c' ;   -- �p�b�P�[�W��
  gv_sql                  VARCHAR2(32000) ;                          -- �f�[�^�擾�p�r�p�k
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_language_code              CONSTANT VARCHAR2(2)   := USERENV('LANG') ;
  gc_lookup_type_ship_type      CONSTANT VARCHAR2(100) := 'XXPO_DROP_SHIP_TYPE' ;
--
  ------------------------------
  -- �����˗����׃A�h�I��
  ------------------------------
  gc_cancelled_flg              CONSTANT VARCHAR2(1)   := 'N' ;
--
  ------------------------------
  -- �����˗��w�b�_�A�h�I��
  ------------------------------
  gc_status                     CONSTANT VARCHAR2(30)   := '10' ;
  gc_status2                    CONSTANT VARCHAR2(30)   := '15' ;
--
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '�i�ڋ敪' ;
  ------------------------------
  -- ���i�J�e�S���֘A
  ------------------------------
  gc_cat_set_prod_class         CONSTANT VARCHAR2(100) := '���i�敪' ;
-- Ver1.5 M.Hokkanji Start
  ------------------------------
  -- �p�[�e�B�T�C�g
  ------------------------------
  gc_status_a                   CONSTANT VARCHAR2(1) := 'A' ;
-- Ver1.5 M.Hokkanji End
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN' ;         -- �A�v���P�[�V�����iXXCMN�j
  gc_application_po   CONSTANT VARCHAR2(5)   := 'XXPO' ;          -- �A�v���P�[�V�����iXXPO�j
  gv_msg_xxpo00009    CONSTANT VARCHAR2(100) := 'APP-XXPO-00009'; -- ����0���p���b�Z�[�W
  gv_msg_xxpo10026    CONSTANT VARCHAR2(100) := 'APP-XXPO-10026'; -- �f�[�^���擾���b�Z�[�W
  gv_msg_xxpo10081    CONSTANT VARCHAR2(100) := 'APP-XXPO-10081'; -- �S���Җ����擾���b�Z�[�W
  gv_msg_xxpo10082    CONSTANT VARCHAR2(100) := 'APP-XXPO-10082'; -- �S�����������擾���b�Z�[�W
  gv_msg_xxpo30022    CONSTANT VARCHAR2(100) := 'APP-XXPO-30022'; -- �p�����[�^���
--
  -- �g�[�N��
  gv_tkn_table        CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_param        CONSTANT VARCHAR2(100) := 'PARAM';
  gv_tkn_ng_data      CONSTANT VARCHAR2(100) := 'DATA';
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_d_format    CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format   CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD (
      iv_po_number            xxpo_requisition_headers.po_header_number%TYPE    --   01 :�����ԍ�
     ,iv_division_code        xxcmn_locations_v.location_code%TYPE              --   02 :�˗�����
     ,iv_employee_number      per_all_people_f.employee_number%TYPE             --   03 :�S����
     ,iv_location_code        xxcmn_locations_v.location_code%TYPE              --   04 :��������
     ,iv_creation_date_f      VARCHAR2(21)                                      --   05 :�쐬��FROM
     ,iv_creation_date_t      VARCHAR2(21)                                      --   06 :�쐬��TO
     ,iv_vendor_code          xxcmn_vendors_v.segment1%TYPE                     --   07 :�����
     ,iv_promised_date_f      VARCHAR2(20)                                      --   08 :�[����FROM
     ,iv_promised_date_t      VARCHAR2(20)                                      --   09 :�[����TO
     ,iv_whse_code            xxcmn_item_locations_v.segment1%TYPE              --   10 :�[����
     ,iv_prod_class_code      xxpo_categories_v.category_set_id%TYPE            --   11 :���i�敪
     ,iv_item_class_code      xxpo_categories_v.category_set_id%TYPE            --   12 :�i�ڋ敪
    ) ;
--
  -- �����˗����f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD (
      header_number            xxpo_requisition_headers.po_header_number%TYPE   -- �����ԍ�
     ,v_segment1               xxcmn_vendors_v.segment1%TYPE                    -- �d����ԍ�
     ,vendor_full_name         xxcmn_vendors_v.vendor_full_name%TYPE            -- �����F������
     ,promised_date            xxpo_requisition_headers.promised_date%TYPE      -- �[����
     ,i_segment1               xxcmn_item_locations_v.segment1%TYPE             -- �ۊǑq�ɃR�[�h
     ,i_description            xxcmn_item_locations_v.description%TYPE          -- �ۊǑq�ɖ�
     ,f_meaning                fnd_lookup_values.meaning%TYPE                   -- ���e(�����敪)
     ,r_request_code xxpo_requisition_headers.requested_to_department_code%TYPE -- �˗��敔���R�[�h
     ,location_short_name      xxcmn_locations_v.location_short_name%TYPE       -- ����
     ,r_description            xxpo_requisition_headers.description%TYPE        -- �E�v
     ,item_no                  xxcmn_item_mst_v.item_no%TYPE                    -- �i��
     ,item_name                xxcmn_item_mst_v.item_name%TYPE                  -- ������
     ,pack_quantity            xxpo_requisition_lines.pack_quantity%TYPE        -- ����
     ,requested_quantity       xxpo_requisition_lines.requested_quantity%TYPE   -- �˗�����
     ,requested_uom   xxpo_requisition_lines.requested_quantity_uom%TYPE      -- �˗����ʒP�ʃR�[�h
     ,requested_date           xxpo_requisition_lines.requested_date%TYPE      -- ���t�w��
     ,l_description            xxpo_requisition_lines.description%TYPE         -- �E�v
     ,prov_ship_code           VARCHAR2(100)                                   -- �x��/�o�׃R�[�h
     ,prov_ship_name           VARCHAR2(100)                                   -- �x��/�o�א�����
     ,prov_ship_zip            VARCHAR2(100)                                   -- �x��/�o�חX�֔ԍ�
     ,prov_ship_address1       VARCHAR2(100)                                   -- �x��/�o�׏Z���P
     ,prov_ship_address2       VARCHAR2(100)                                   -- �x��/�o�׏Z���Q
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gn_user_id          fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID ; --���O�C�����[�U�[�h�c
  gr_param            rec_param_data ;                                   --�p�����[�^
  gv_user_dept        xxcmn_locations_all.location_short_name%TYPE DEFAULT NULL; -- �S������
  gv_user_name        per_all_people_f.per_information18%TYPE DEFAULT NULL;      -- �S����
--
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id              VARCHAR2(12) ;            -- ���[ID
  gd_exec_date              DATE         ;            -- ���{��
--
  gt_main_data              tab_data_type_dtl ;       -- �擾���R�[�h�\
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
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml (
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
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(B-1)
   ***********************************************************************************/
  PROCEDURE prc_initialize (
      ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- �v���O������
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
    ln_err_flg            NUMBER DEFAULT 0 ;
--
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION ;     -- �l�擾�G���[
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �S���������擾
    -- ====================================================
    gv_user_dept := substrb(xxcmn_common_pkg.get_user_dept( gn_user_id ),0,10) ;
--
    -- ====================================================
    -- �S���Җ��擾
    -- ====================================================
    gv_user_name := substrb(xxcmn_common_pkg.get_user_name( gn_user_id ),0,14) ;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn ;
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
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : �f�[�^�擾(B-2)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data (
      ot_data_rec          OUT  NOCOPY tab_data_type_dtl -- �擾���R�[�h�Q
     ,ov_errbuf            OUT  VARCHAR2                 -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT  VARCHAR2                 -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            OUT  VARCHAR2                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- �v���O������
    cv_table_name CONSTANT VARCHAR2(15) := '�����˗�';             -- �e�[�u����
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
    -- *** ���[�J���E�萔 ***
    lc_drop_ship_type1      VARCHAR2(30) := '�ʏ�' ;     -- �����敪
    lc_drop_ship_type2      VARCHAR2(30) := '�o��' ;     -- �����敪
    lc_drop_ship_type3      VARCHAR2(30) := '�x��' ;     -- �����敪
--
    cv_ja          CONSTANT VARCHAR2(10) := 'JA' ;       -- ���{��
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;           -- �擾���R�[�h�Ȃ�
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
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
      || ' xrh.po_header_number                 AS header_number'            -- �����ԍ�
      || ',xv.segment1                          AS v_segment1'               -- �d����ԍ�
      || ',substrb(xv.vendor_full_name,0,60)    AS vendor_full_name'         -- �����F������
      || ',xrh.promised_date                    AS promised_date'            -- �[����
      || ',xilv.segment1                        AS i_segment1'               -- �ۊǑq�ɃR�[�h
      || ',substrb(xilv.description,0,60)       AS i_description'            -- �ۊǑq�ɖ�
      || ',flv.meaning                          AS f_meaning'                -- ���e(�����敪)
      || ',xrh.requested_to_department_code     AS r_request_code'           -- �˗��敔���R�[�h
      || ',substrb(xl.location_short_name,0,60) AS location_short_name'      -- ����
      || ',substrb(xrh.description,0,60)        AS r_description'            -- �E�v
      || ',ximv.item_no                         AS item_no'                  -- �i��
      || ',substrb(ximv.item_name,0,40)         AS item_name'                -- ������
      || ',xrl.pack_quantity                    AS pack_quantity'            -- ����
      || ',xrl.requested_quantity               AS requested_quantity'       -- �˗�����
      || ',xrl.requested_quantity_uom           AS requested_uom'            -- �˗����ʒP�ʃR�[�h
      || ',xrl.requested_date                   AS requested_date'           -- ���t�w��
      || ',substrb(xrl.description,0,40)        AS l_description'            -- �E�v
      || ',DECODE(flv.meaning, ''' || lc_drop_ship_type2 || ''',xpsv.party_site_number,'
      || '                     ''' || lc_drop_ship_type3 || ''',xvsv.vendor_site_code,'
      || '                     ''' || lc_drop_ship_type1 || ''',NULL,NULL)  AS prov_ship_code'
      || ',DECODE(flv.meaning, ''' || lc_drop_ship_type2
      || ''',substrb(xpsv.party_site_full_name,0,60),'
      || '                     ''' || lc_drop_ship_type3
      || ''',substrb(xvsv.vendor_site_name,0,60),'
      || '                     ''' || lc_drop_ship_type1 || ''',NULL,NULL)  AS prov_ship_name'
      || ',DECODE(flv.meaning, ''' || lc_drop_ship_type2 || ''',xpsv.zip,'
      || '                     ''' || lc_drop_ship_type3 || ''',xvsv.zip,'
      || '                     ''' || lc_drop_ship_type1 || ''',NULL,NULL)  AS prov_ship_zip'
      || ',DECODE(flv.meaning, ''' || lc_drop_ship_type2
      || ''',substrb(xpsv.address_line1,0,30),'
      || '                     ''' || lc_drop_ship_type3
      || ''',substrb(xvsv.address_line1,0,30),'
      || '                     ''' || lc_drop_ship_type1 || ''',NULL,NULL)  AS prov_ship_address1'
      || ',DECODE(flv.meaning, ''' || lc_drop_ship_type2
      || ''',substrb(xpsv.address_line2,0,30),'
      || '                     ''' || lc_drop_ship_type3
      || ''',substrb(xvsv.address_line2,0,30),'
      || '                     ''' || lc_drop_ship_type1 || ''',NULL,NULL)  AS prov_ship_address2'
      ;
--
    -- ====================================================
    -- �e�q�n�l�吶��
    -- ====================================================
    lv_from := ' FROM'
      || ' xxpo_requisition_headers             xrh'                -- �����˗��w�b�_�A�h�I��
      || ',xxpo_requisition_lines               xrl'                -- �����˗����׃A�h�I��
      || ',xxcmn_vendors2_v                     xv'                 -- �d������VIEW
      || ',xxcmn_item_mst2_v                    ximv'               -- OPM�i�ڏ��VIEW
      || ',xxcmn_locations2_v                   xl'                 -- ���Ə����VIEW
      || ',xxcmn_item_locations2_v              xilv'               -- OPM�ۊǏꏊ���VIEW
      || ',(SELECT mcb.segment1  AS category_code '    -- XXPO�J�e�S�����VIEW�i���i
      || ',        mcst.category_set_name '
      || ',        gic.item_id '
      || '  FROM   mtl_category_sets_tl  mcst, '
      || '   mtl_category_sets_b   mcsb, '
      || '   mtl_categories_b      mcb, '
      || '   gmi_item_categories    gic '
      || '  WHERE mcsb.category_set_id  = mcst.category_set_id '
      || '  AND   mcst.language         = ''' || cv_ja || ''''
      || '  AND   mcsb.structure_id     = mcb.structure_id '
      || '  AND   gic.category_set_id   = mcsb.category_set_id '
      || '  AND   gic.category_id       = mcb.category_id '
      || '  AND   mcst.category_set_name = ''' || gc_cat_set_prod_class || '''' || ') ctgg'
      || ',(SELECT mcb.segment1  AS category_code '    -- XXPO�J�e�S�����VIEW�i�i��
      || ',        mcst.category_set_name '
      || ',        gic.item_id '
      || '  FROM   mtl_category_sets_tl  mcst, '
      || '   mtl_category_sets_b   mcsb, '
      || '   mtl_categories_b      mcb, '
      || '   gmi_item_categories    gic '
      || '  WHERE mcsb.category_set_id  = mcst.category_set_id '
      || '  AND   mcst.language         = ''' || cv_ja || ''''
      || '  AND   mcsb.structure_id     = mcb.structure_id '
      || '  AND   gic.category_set_id   = mcsb.category_set_id '
      || '  AND   gic.category_id       = mcb.category_id '
      || '  AND   mcst.category_set_name = ''' || gc_cat_set_item_class || '''' || ') ctgi'
      || ',fnd_lookup_values                    flv '               -- �N�C�b�N�R�[�h
      || ',xxcmn_party_sites2_v                 xpsv'               -- �p�[�e�B�T�C�g���VIEW
      || ',xxcmn_vendor_sites2_v                xvsv'               -- �d����T�C�g���VIEW
      ;
--
    -- ====================================================
    -- �v�g�d�q�d�吶��
    -- ====================================================
    lv_where := ' WHERE'
      || '     xrh.requisition_header_id          = xrl.requisition_header_id'
      || ' AND xrh.vendor_id                      = xv.vendor_id(+)'
      || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f || ''','''
                                           || gc_char_dt_format || ''')'
      || '     BETWEEN xv.start_date_active(+) AND xv.end_date_active(+)'
      || ' AND xrh.location_code                  = xilv.segment1'
      || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f || ''','''
                                           || gc_char_dt_format  || ''') >= xilv.date_from'
      || ' AND (   ( xilv.date_to IS NULL)'
      || '      OR (    (xilv.date_to IS NOT NULL)'
      || '          AND (xilv.date_to >= FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f
                                                  || ''',''' || gc_char_dt_format  || '''))))'
      || ' AND xrl.item_id                        = ximv.item_id'
      || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f || ''','''
                                           || gc_char_dt_format || ''')'
      || '     BETWEEN ximv.start_date_active AND ximv.end_date_active'
      || ' AND   (  xrh.status =  ''' || gc_status || ''''
      ||       ' OR xrh.status = ''' || gc_status2 || ''')'
      || ' AND xrl.cancelled_flg = ''' || gc_cancelled_flg || ''''
      || ' AND xrh.requested_to_department_code   = xl.location_code'
      || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f || ''','''
                                           || gc_char_dt_format || ''')'
      || '     BETWEEN xl.start_date_active AND xl.end_date_active'
      || ' AND flv.language                    = ''' || gc_language_code || ''''
      || ' AND flv.lookup_type                 = ''' || gc_lookup_type_ship_type || ''''
      || ' AND flv.lookup_code                 = xrh.drop_ship_type'
      || ' AND xrh.promised_date >= FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f
      || ''' , ''' || gc_char_dt_format || ''')'
      || ' AND xrh.delivery_code                  = xpsv.party_site_number(+)'
      || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f || ''','''
                                           || gc_char_dt_format || ''')'
      || '     BETWEEN xpsv.start_date_active(+) AND xpsv.end_date_active(+)'
-- Ver1.5 M.Hokkanji Start
      || ' AND xpsv.party_site_status(+) = ''' || gc_status_a || ''''
      || ' AND xpsv.cust_acct_site_status(+) = ''' || gc_status_a || ''''
      || ' AND xpsv.cust_site_uses_status(+) = ''' || gc_status_a || ''''
-- Ver1.5 M.Hokkanji End
      || ' AND xrh.delivery_code                  = xvsv.vendor_site_code(+)'
      || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f || ''','''
                                           || gc_char_dt_format || ''')'
      || '     BETWEEN xvsv.start_date_active(+) AND xvsv.end_date_active(+)'
      ;
    -- ----------------------------------------------------
    -- �p�����[�^�w��ɂ�����
    -- ----------------------------------------------------
    -- �����ԍ�
    IF ( gr_param.iv_po_number IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.po_header_number = ''' || gr_param.iv_po_number || ''''
        ;
    END IF ;
    -- �˗�����
    IF ( gr_param.iv_division_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.requested_dept_code = ''' || gr_param.iv_division_code || ''''
        ;
    END IF ;
    -- �S����
    IF ( gr_param.iv_employee_number IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.requested_by_code = ''' || gr_param.iv_employee_number || ''''
        ;
    END IF ;
    -- ��������
    IF ( gr_param.iv_location_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.requested_to_department_code = ''' || gr_param.iv_location_code || ''''
        ;
    END IF ;
    -- �쐬��from
    IF ( gr_param.iv_creation_date_f IS NOT NULL ) THEN
      lv_where := lv_where
        || 'AND xrh.creation_date >= FND_DATE.STRING_TO_DATE(''' || gr_param.iv_creation_date_f
        || ''',''' || gc_char_dt_format || ''')'
        ;
    END IF ;
    -- �쐬��to
    IF ( gr_param.iv_creation_date_t IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.creation_date <= FND_DATE.STRING_TO_DATE(''' || gr_param.iv_creation_date_t
        || ''',''' || gc_char_dt_format || ''')'
        ;
    END IF ;
    -- �����
    IF ( gr_param.iv_vendor_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.vendor_code = ''' || gr_param.iv_vendor_code || ''''
        ;
    END IF ;
    -- �[����
    IF ( gr_param.iv_whse_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.location_code = ''' || gr_param.iv_whse_code || ''''
        ;
    END IF ;
    -- �[����to
    IF ( gr_param.iv_promised_date_t IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.promised_date <= FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t
        || ''',''' || gc_char_dt_format || ''')'
        || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t || ''','''
                                             || gc_char_dt_format || ''')'
        || '     BETWEEN xl.start_date_active AND xl.end_date_active'
        || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t || ''','''
                                             || gc_char_dt_format || ''')'
        || '     BETWEEN xv.start_date_active(+) AND xv.end_date_active(+)'
        || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t || ''','''
                                             || gc_char_dt_format || ''')'
        || '     BETWEEN ximv.start_date_active AND ximv.end_date_active'
        || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t || ''','''
                                             || gc_char_dt_format  || ''') >= xilv.date_from'
        || ' AND (   ( xilv.date_to IS NULL)'
        || '      OR (    (xilv.date_to IS NOT NULL)'
        || '        AND (xilv.date_to >= FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t
                                                  || ''',''' || gc_char_dt_format  || '''))))'
        || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t || ''','''
                                             || gc_char_dt_format || ''')'
        || '     BETWEEN xpsv.start_date_active(+) AND xpsv.end_date_active(+) '
        || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t || ''','''
                                             || gc_char_dt_format || ''')'
        || '     BETWEEN xvsv.start_date_active(+) AND xvsv.end_date_active(+) '
        ;
    END IF ;
    ---------------------------------------------------------------------------------------------
    -- �i�ڃJ�e�S���i���i�敪�j�̍i���ݏ���
    lv_where := lv_where
      || ' AND ximv.item_id                          = ctgg.item_id'
      ;
    -- ���i�敪�����͂���Ă���ꍇ
    IF (gr_param.iv_prod_class_code IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND ctgg.category_code   = ''' || gr_param.iv_prod_class_code || ''''
      ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �i�ڃJ�e�S���i�i�ڋ敪�j�̍i���ݏ���
    lv_where := lv_where
      || ' AND ximv.item_id                          = ctgi.item_id'
      ;
    -- �i�ڋ敪�����͂���Ă���ꍇ
    IF (gr_param.iv_item_class_code IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND ctgi.category_code   = ''' || gr_param.iv_item_class_code || ''''
      ;
    END IF;
--
    -- ====================================================
    -- �n�q�c�d�q  �a�x�吶��
    -- ====================================================
    lv_order_by := ' ORDER BY'
      || ' xrh.po_header_number'
      || ',xv.segment1'
      || ',xrh.promised_date'
      || ',xrh.location_code'
      || ',xrl.requisition_line_number'
      ;
--
    -- ====================================================
    -- �r�p�k����
    -- ====================================================
    gv_sql := lv_select || lv_from || lv_where || lv_order_by ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �I�[�v��
    OPEN lc_ref FOR gv_sql ;
    -- �o���N�t�F�b�`
    FETCH lc_ref BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data (
      ov_errbuf             OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
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
    -- *** ���[�J���萔 ***
    -- �L�[�u���C�N���f�p
    lc_break_init          VARCHAR2(100) := '*' ;       -- ����於
    lc_break_null          VARCHAR2(100) := '**' ;      -- �i�ڋ敪
    lc_max_cnt             NUMBER        := 30 ;        -- ����MAX�s��
    lc_drop_ship_type1     VARCHAR2(30) := '�ʏ�' ;     -- �����敪
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_po_header_no        VARCHAR2(100) DEFAULT '*' ;  -- �����ԍ�
    lv_key_break           VARCHAR2(100) DEFAULT '*' ;  -- �L�[�u���C�N
    ln_cnt                 NUMBER DEFAULT 0;            -- ���׌���
    ln_total               NUMBER DEFAULT 0;            -- ���v��
--
    -- *** ���[�J���E��O���� ***
    no_data_expt                 EXCEPTION ;            -- �擾���R�[�h�Ȃ�
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    -- =====================================================
    prc_get_report_data (
        ot_data_rec   => gt_main_data   --    �擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      --    �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --    ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
--
    END IF ;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- ���[�U�[�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ���[�U�[�f�f�[�^�^�O�o��
    -- -----------------------------------------------------
--
    -- ���[�h�c
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
    -- ���{��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'output_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format ) ;
    -- �S������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'charge_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_user_dept ;
    -- �S���Җ�
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'agent' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_user_name ;
    -- -----------------------------------------------------
    -- ���[�U�[�f�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- �����˗��k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_order_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
--
      -- =====================================================
      -- �����ԍ��u���C�N
      -- =====================================================
      -- �����ԍ����؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).header_number, lc_break_null ) <> lv_po_header_no ) THEN
--
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_key_break <> lc_break_init ) THEN
--
          IF ((ln_cnt <= lc_max_cnt ) OR ( (ln_cnt > lc_max_cnt)
            AND (ln_cnt MOD lc_max_cnt <= lc_max_cnt))) THEN
--
            IF ((ln_cnt MOD lc_max_cnt) <> 0) THEN
              -- ��s�̍쐬
              <<blank_loop>>
              FOR i IN 1 .. lc_max_cnt - (ln_cnt MOD lc_max_cnt) LOOP
--
                -- -----------------------------------------------------
                -- ����L�f�J�n�^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
                -- -----------------------------------------------------
                -- ���ׂf�J�n�^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
                -- -----------------------------------------------------
                -- ���ׂf�f�[�^�^�O�o��
                -- -----------------------------------------------------
                -- �i�ڃR�[�h
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
                gt_xml_data_table(gl_xml_idx).tag_value := NULL;
                -- -----------------------------------------------------
                -- ���ׂf�I���^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
                -- -----------------------------------------------------
                -- ����L�f�I���^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
              END LOOP blank_loop;
--
            END IF;
          END IF;
--
          -- -----------------------------------------------------
          -- ���vL�f�J�n�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- ���v�f�J�n�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- ���ׂf�f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ���v
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_total;
          -- -----------------------------------------------------
          -- ���v�f�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- ���vL�f�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- �����A���v�N���A
          ln_cnt   := 0;
          ln_total := 0;
--
          -- -----------------------------------------------------
          -- �����˗��f�I���^�O
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_order_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- -----------------------------------------------------
        -- �����˗��f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_order_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ����No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'order_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).header_number ;
        -- �����F�����R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'business_partner_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_segment1 ;
        -- �����F����於
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'business_partner_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).vendor_full_name ;
        -- �[����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value :=
          TO_CHAR(gt_main_data(i).promised_date, gc_char_d_format ) ;
        -- �[����F�[����R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_to_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_segment1 ;
        -- �[����F�[���於
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_to_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_description ;
--
        -- ====================================================
        -- �x��/�o��
        -- ====================================================
        IF (lc_drop_ship_type1 <> gt_main_data(i).f_meaning ) THEN
          -- ���o
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_title' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).f_meaning ;
        ELSE
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_title' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := '' ;
        END IF ;
--
        IF (gt_main_data(i).prov_ship_code IS NOT NULL )
          OR (gt_main_data(i).prov_ship_name IS NOT NULL) THEN
          -- �R����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision1' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ':' ;
        END IF ;
--
        -- �x��/�o�׃R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prov_ship_code ;
        -- �x��/�o�א�����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prov_ship_name ;
--
        IF (gt_main_data(i).prov_ship_zip IS NOT NULL )
          OR (gt_main_data(i).prov_ship_address1 IS NOT NULL)
          OR (gt_main_data(i).prov_ship_address2 IS NOT NULL) THEN
          -- �R����
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision2' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ':' ;
        END IF ;
--
        -- �x��/�o�חX�֔ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_zip' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prov_ship_zip ;
        -- �x��/�o�׏Z���P
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_address1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prov_ship_address1 ;
        -- �x��/�o�׏Z���Q
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_address2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prov_ship_address2 ;
--
        -- ���������R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'po_dept_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).r_request_code ;
        -- ����������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'po_dept_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).location_short_name ;
        -- �E�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'description' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).r_description ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_po_header_no  := NVL( gt_main_data(i).header_number, lc_break_null )  ;
        lv_key_break   := lc_break_null ;
--
      END IF ;
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
--
      -- -----------------------------------------------------
      -- ����L�f�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���ׂf�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���ׂf�f�[�^�^�O�o��
      -- -----------------------------------------------------
      -- �i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_no ;
      -- �i�ږ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_name ;
      -- ����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'purchase_quantity' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).pack_quantity ;
      -- �˗���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'request_quantity' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).requested_quantity ;
      -- �P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_of_measure' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).requested_uom ;
      -- ���t�w��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'specify_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value
            := TO_CHAR( gt_main_data(i).requested_date, gc_char_d_format ) ;
      -- ���דE�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'line_description' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_description ;
      -- -----------------------------------------------------
      -- ���ׂf�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ����L�f�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- �˗������v
      ln_total := ln_total + gt_main_data(i).requested_quantity ;
--
      IF ln_cnt = lc_max_cnt THEN
         ln_cnt := 0;
      END IF;
--
      -- ���׌����J�E���g
      ln_cnt := ln_cnt + 1;
    END LOOP main_data_loop ;
--
    IF ((ln_cnt <= lc_max_cnt ) OR ( (ln_cnt > lc_max_cnt)
      AND (ln_cnt MOD lc_max_cnt <= lc_max_cnt))) THEN
--
      IF ((ln_cnt MOD lc_max_cnt) <> 0) THEN
        -- ��s�̍쐬
        <<blank_loop>>
        FOR i IN 1 .. lc_max_cnt - ln_cnt LOOP
--
          -- -----------------------------------------------------
          -- ����L�f�J�n�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- ���ׂf�J�n�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- ���ׂf�f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- �i�ڃR�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- -----------------------------------------------------
          -- ���ׂf�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- ����L�f�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END LOOP blank_loop;
--
      END IF;
    END IF;
--
    -- -----------------------------------------------------
    -- ���vL�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ���v�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ���ׂf�f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- ���v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_total;
    -- -----------------------------------------------------
    -- ���v�f�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ���vL�f�I���^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    ------------------------------
    -- �����˗��f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_order_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �����˗��k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_order_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �f�[�^�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg := xxcmn_common_pkg.get_msg(gc_application_po,gv_msg_xxpo00009);
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain (
      ov_errbuf            OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT     VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_po_number         IN      VARCHAR2         --   01 : �����ԍ�
     ,iv_division_code     IN      VARCHAR2         --   02 : �˗�����
     ,iv_employee_number   IN      VARCHAR2         --   03 : �S����
     ,iv_location_code     IN      VARCHAR2         --   04 : ��������
     ,iv_creation_date_f   IN      VARCHAR2         --   05 : �쐬��FROM
     ,iv_creation_date_t   IN      VARCHAR2         --   06 : �쐬��TO
     ,iv_vendor_code       IN      VARCHAR2         --   07 : �����
     ,iv_promised_date_f   IN      VARCHAR2         --   08 : �[����FROM
     ,iv_promised_date_t   IN      VARCHAR2         --   09 : �[����TO
     ,iv_whse_code         IN      VARCHAR2         --   10 : �[����
     ,iv_prod_class_code   IN      VARCHAR2         --   11 : ���i�敪
     ,iv_item_class_code   IN      VARCHAR2         --   12 : �i�ڋ敪
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    cv_table_name  CONSTANT VARCHAR2(15) := '�����˗�';  -- �e�[�u����
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
    -- *** ���[�J���ϐ� ***
--
    lv_xml_string           VARCHAR2(32000) ;
    lv_worn_msg             VARCHAR2(5000) DEFAULT NULL;  --   ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- ���[�o�͒l�i�[
    gv_report_id              := 'XXPO380002T' ;      -- ���[ID
    gd_exec_date              := SYSDATE ;            -- ���{��
    -- �p�����[�^�i�[
    gr_param.iv_po_number        := iv_po_number ;       --   01 : �����ԍ�
    gr_param.iv_division_code    := iv_division_code ;   --   02 : �˗�����
    gr_param.iv_employee_number  := iv_employee_number ; --   03 : �S����
    gr_param.iv_location_code    := iv_location_code ;   --   04 : ��������
    gr_param.iv_creation_date_f  := iv_creation_date_f ; --   05 : �쐬��FR
    gr_param.iv_creation_date_t  := iv_creation_date_t ; --   06 : �쐬��TO
    gr_param.iv_vendor_code      := iv_vendor_code ;     --   07 : �����
    gr_param.iv_promised_date_f  := iv_promised_date_f ; --   08 : �[����FR
    gr_param.iv_promised_date_t  := iv_promised_date_t ; --   09 : �[����TO
    gr_param.iv_whse_code        := iv_whse_code ;       --   10 : �[����
    gr_param.iv_prod_class_code  := iv_prod_class_code ; --   11 : ���i�敪
    gr_param.iv_item_class_code  := iv_item_class_code ; --   12 : �i�ڋ敪
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �f�[�^�擾
    -- =====================================================
    prc_create_xml_data (
        ov_errbuf         =>     lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        =>     lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         =>     lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
      AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_order_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_order_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_order_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_order_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
      -- �O�����b�Z�[�W���O�o��
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,gv_msg_xxpo10026
                                             ,gv_tkn_table
                                             ,cv_table_name ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- �w�l�k�w�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
      -- �w�l�k�f�[�^���o��
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
      -- �w�l�k�t�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    END IF ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
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
  PROCEDURE main (
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_po_number          IN     VARCHAR2         --   01 : �����ԍ�
     ,iv_division_code      IN     VARCHAR2         --   02 : �˗�����
     ,iv_employee_number    IN     VARCHAR2         --   03 : �S����
     ,iv_location_code      IN     VARCHAR2         --   04 : ��������
     ,iv_creation_date_f    IN     VARCHAR2         --   05 : �쐬��FROM
     ,iv_creation_date_t    IN     VARCHAR2         --   06 : �쐬��TO
     ,iv_vendor_code        IN     VARCHAR2         --   07 : �����
     ,iv_promised_date_f    IN     VARCHAR2         --   08 : �[����FROM
     ,iv_promised_date_t    IN     VARCHAR2         --   09 : �[����TO
     ,iv_whse_code          IN     VARCHAR2         --   10 : �[����
     ,iv_prod_class_code    IN     VARCHAR2         --   11 : ���i�敪
     ,iv_item_class_code    IN     VARCHAR2         --   12 : �i�ڋ敪
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
    submain (
        ov_errbuf             =>     lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            =>     lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             =>     lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       ,iv_po_number          =>     iv_po_number        -- 01 : �����ԍ�
       ,iv_division_code      =>     iv_division_code    -- 02 : �˗�����
       ,iv_employee_number    =>     iv_employee_number  -- 03 : �S����
       ,iv_location_code      =>     iv_location_code    -- 04 : ��������
       ,iv_creation_date_f    =>     iv_creation_date_f  -- 05 : �쐬��FROM
       ,iv_creation_date_t    =>     iv_creation_date_t  -- 06 : �쐬��TO
       ,iv_vendor_code        =>     iv_vendor_code      -- 07 : �����
       ,iv_promised_date_f    =>     iv_promised_date_f  -- 08 : �[����FROM
       ,iv_promised_date_t    =>     iv_promised_date_t  -- 09 : �[����TO
       ,iv_whse_code          =>     iv_whse_code        -- 10 : �[����
       ,iv_prod_class_code    =>     iv_prod_class_code  -- 11 : ���i�敪
       ,iv_item_class_code    =>     iv_item_class_code  -- 12 : �i�ڋ敪
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
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
END xxpo380002c ;
/
