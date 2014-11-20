CREATE OR REPLACE PACKAGE BODY xxpo360002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo360002c(body)
 * Description      : �o�ɗ\��\
 * MD.050/MD.070    : �L���x�����[Issue1.0 (T_MD050_BPO_360)
 *                    �L���x�����[Issue1.0 (T_MD070_BPO_36C)
 * Version          : 1.4
 *
 * Program List
 * -------------------------- ------------------------------------------------------------
 *  Name                       Description
 * -------------------------- ------------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_initialize            PROCEDURE : �O����(C-1)
 *  prc_get_report_data       PROCEDURE : �f�[�^�擾(C-2)
 *  prc_create_xml_data       PROCEDURE : �f�[�^�o��(C-3)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ ------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ ------------------------------------------------
 *  2008/03/12    1.0   hirofumi yamazato  �V�K�쐬
 *  2008/05/14    1.1   hirofumi yamazato  �s�ID3�Ή�
 *  2008/05/19    1.2   Y.Ishikawa         �O�����[�U�[���Ɍx���I���ɂȂ�
 *  2008/05/20    1.3   T.Endou            �Z�L�����e�B�O���q�ɂ̕s��Ή�
 *  2008/05/22    1.4   Y.Majikina         ���דK�p�̍ő咷���C��
 *
 ****************************************************************************************/
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXPO360002C' ;  -- �p�b�P�[�W��
  gv_print_name               CONSTANT VARCHAR2(20) := '�o�ɗ\��\' ;   -- ���[��
--
  ------------------------------
  -- �Z�L�����e�B�敪
  ------------------------------
  gc_seqrt_class_itoen        CONSTANT VARCHAR2(1) := '1';              -- �ɓ���
  gc_seqrt_class_vender       CONSTANT VARCHAR2(1) := '2';              -- �����i�����ҁj
  gc_seqrt_class_outside      CONSTANT VARCHAR2(1) := '4';              -- �O���q��
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_language_code            CONSTANT VARCHAR2(2)   := 'JA' ;
--
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gc_cat_set_goods_class      CONSTANT VARCHAR2(100) := '���i�敪' ;
  gc_cat_set_item_class       CONSTANT VARCHAR2(100) := '�i�ڋ敪' ;
  gv_item_class               CONSTANT VARCHAR2(1)   := '5' ;           -- �i�ڋ敪�i���i�j
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application              CONSTANT VARCHAR2(5)  := 'XXCMN' ;        -- �A�v���P�[�V����(����)
  gc_application_po           CONSTANT VARCHAR2(5)  := 'XXPO' ;         -- �A�v���P�[�V����(����)
  gv_seqrt_view               CONSTANT VARCHAR2(30) := '�L���x���Z�L�����e�Bview' ;
  gv_seqrt_view_key           CONSTANT VARCHAR2(20) := '�]�ƈ�ID' ;
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_d_format            CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format           CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data     IS RECORD (
      vend_code             po_vendors.segment1%TYPE                -- �o�Ɍ�
     ,dlv_f                 VARCHAR2(10)                            -- �[�i��FROM
     ,dlv_t                 VARCHAR2(10)                            -- �[�i��TO
     ,goods_class           mtl_categories_b.segment1%TYPE          -- ���i�敪
     ,item_class            mtl_categories_b.segment1%TYPE          -- �i�ڋ敪
     ,item_code             ic_item_mst_b.item_no%TYPE              -- �i��
     ,dept_code             po_headers_all.segment5%TYPE            -- ���ɑq��
     ,seqrt_class           VARCHAR2(1)                             -- �Z�L�����e�B�敪
    ) ;
--
  -- ���ɗ\��\�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD (
      h_vend_code           po_vendors.segment1%TYPE                -- �w�b�_�F�o�Ɍ��R�[�h
     ,h_vend_name           xxcmn_vendors.vendor_short_name%TYPE    -- �w�b�_�F�o�Ɍ���
     ,h_deliver_date        po_headers_all.attribute4%TYPE          -- �w�b�_�F�[����
     ,h_goods_code          mtl_categories_b.segment1%TYPE          -- �w�b�_�F���i�敪�R�[�h
     ,h_goods_name          mtl_categories_tl.description%TYPE      -- �w�b�_�F���i�敪��
     ,h_item_code           mtl_categories_b.segment1%TYPE          -- �w�b�_�F�i�ڋ敪�R�[�h
     ,h_item_name           mtl_categories_tl.description%TYPE      -- �w�b�_�F�i�ڋ敪��
     ,item_code             ic_item_mst_b.item_no%TYPE              -- �i�ڃR�[�h
     ,item_name             xxcmn_item_mst_b.item_short_name%TYPE   -- �i�ږ�
     ,add_code              po_lines_all.attribute3%TYPE            -- �t��
     ,lot_no                ic_lots_mst.lot_no%TYPE                 -- ���b�gNo
     ,make_date             ic_lots_mst.attribute1%TYPE             -- ������
     ,period_date           ic_lots_mst.attribute3%TYPE             -- �ܖ�����
     ,prop_mark             ic_lots_mst.attribute2%TYPE             -- �ŗL�L��
     ,inv_qty               po_lines_all.attribute4%TYPE            -- ����
     ,po_qty                po_lines_all.attribute11%TYPE           -- ����
     ,po_uom                po_lines_all.attribute10%TYPE           -- �P��
     ,po_no                 po_headers_all.segment1%TYPE            -- ����No
     ,dept_code             mtl_item_locations.segment1%TYPE        -- ���ɑq�ɃR�[�h
     ,dept_name             mtl_item_locations.description%TYPE     -- ���ɑq�ɖ�
     ,po_desc               po_lines_all.attribute15%TYPE           -- ���דE�v
     ,disp_odr1             VARCHAR2(40)                            -- �\�������P
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
  TYPE subinv_code_type IS TABLE OF
    xxpo_security_supply_v.segment1%TYPE INDEX BY BINARY_INTEGER; -- �ۊǑq�ɃR�[�h
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%type ;     -- �c�ƒP��
  gn_employee_id            xxpo_per_all_people_f_v.person_id%TYPE ;   -- �]�ƈ�ID
  gn_user_vender_id         po_vendors.vendor_id%TYPE;                 -- �d����ID
  gv_user_vender            xxpo_per_all_people_f_v.attribute4%TYPE ;  -- �d����R�[�h
  gv_user_vender_site       xxpo_per_all_people_f_v.attribute6%TYPE ;  -- �d����T�C�g�R�[�h
  gv_subinv_code            subinv_code_type;                          -- �ۊǑq�ɃR�[�h
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID ; -- ���[�U�[�h�c
  gv_report_id              VARCHAR2(12) ;                                     -- ���[ID
  gd_exec_date              DATE ;                                             -- ���{��
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE ;     -- �S������
  gv_user_name              per_all_people_f.per_information18%TYPE ;          -- �S����
--
  gt_main_data              tab_data_type_dtl ;  -- �擾���R�[�h�\
  gt_xml_data_table         XML_DATA ;           -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER ;             -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
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
   * Function Name    : fnc_get_in_statement
   * Description      : IN��̓��e��Ԃ��܂��B(subinv_code_type)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      itbl_subinv_code IN subinv_code_type
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<subinv_code_loop>>
    FOR ln_cnt IN 1..itbl_subinv_code.COUNT LOOP
      lv_in := lv_in || '''' || itbl_subinv_code(ln_cnt) || ''',';
    END LOOP subinv_code_loop;
--
    RETURN(
      SUBSTR(lv_in,1,LENGTH(lv_in) - 1));
--
  END fnc_get_in_statement;
--
--
  /***********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml (
      iv_name    IN  VARCHAR2   -- �^�O�l�[��
     ,iv_value   IN  VARCHAR2   -- �^�O�f�[�^
     ,ic_type    IN  CHAR       -- �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data           VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<' || iv_name || '>' || iv_value || '</' || iv_name || '>' ;
    ELSE
      lv_convert_data := '<' || iv_name || '>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
  /***********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(C-1)
   ***********************************************************************************/
  PROCEDURE prc_initialize (
      ir_param      IN     rec_param_data  -- 01.���̓p�����[�^�Q
     ,ov_errbuf     OUT    VARCHAR2        --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2        --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2        --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_err_code           VARCHAR2(100) ;   -- �G���[�R�[�h�i�[�p
--
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION ;       -- �l�擾�G���[
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
    -- �c�ƒP�ʎ擾
    -- ====================================================
    gn_sales_class := FND_PROFILE.VALUE( 'ORG_ID' ) ;
    IF ( gn_sales_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,'APP-XXPO-00005' ) ;
      lv_retcode  := gv_status_error ;
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- �S���������擾
    -- ====================================================
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
--
    -- ====================================================
    -- �S���Җ��擾
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    IF ( ir_param.seqrt_class = gc_seqrt_class_outside ) THEN
      -- ====================================================
      -- �ۊǑq�ɃR�[�h�擾(�����̏ꍇ�L)
      -- ====================================================
      BEGIN
        SELECT xssv.segment1
          BULK COLLECT INTO gv_subinv_code
        FROM  xxpo_security_supply_v xssv
        WHERE xssv.user_id        = gn_user_id
          AND xssv.security_class = ir_param.seqrt_class;
--
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg( gc_application
                                                ,'APP-XXCMN-10001'
                                                ,'TABLE'
                                                ,gv_seqrt_view
                                                ,'KEY'
                                                ,gv_seqrt_view_key  ) ;
          lv_retcode  := gv_status_error ;
          RAISE get_value_expt ;
      END;
    ELSE
      -- ====================================================
      -- �d����R�[�h�E�d����T�C�g�R�[�h�擾
      -- ====================================================
      BEGIN
        SELECT xssv.vendor_code
              ,xssv.vendor_site_code
              ,vnd.vendor_id
          INTO gv_user_vender
              ,gv_user_vender_site
              ,gn_user_vender_id
        FROM  xxpo_security_supply_v xssv
             ,xxcmn_vendors2_v       vnd
        WHERE xssv.vendor_code    = vnd.segment1 (+)
          AND xssv.user_id        = gn_user_id
          AND xssv.security_class = ir_param.seqrt_class
          AND FND_DATE.STRING_TO_DATE( ir_param.dlv_f, gc_char_d_format )
            BETWEEN vnd.start_date_active (+) AND vnd.end_date_active (+) ;
--
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          -- ���b�Z�[�W�Z�b�g
          lv_errmsg := xxcmn_common_pkg.get_msg( gc_application
                                                ,'APP-XXCMN-10001'
                                                ,'TABLE'
                                                ,gv_seqrt_view
                                                ,'KEY'
                                                ,gv_seqrt_view_key ) ;
          lv_retcode  := gv_status_error ;
          RAISE get_value_expt ;
      END;
    END IF;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
      -- ���b�Z�[�W�Z�b�g
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := lv_retcode ;
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
   * Description      : ���׃f�[�^�擾(C-2)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data (
      ir_param      IN  rec_param_data            -- 01.���̓p�����[�^�Q
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.�擾���R�[�h�Q
     ,ov_errbuf     OUT VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data' ; -- �v���O������
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
    cv_pln_cancel_flag  CONSTANT VARCHAR2(1)  := 'Y' ;         -- ����t���O�i����j
    cv_poh_status       CONSTANT VARCHAR2(10) := 'APPROVED' ;  -- �����X�e�[�^�X�i���F�ς݁j
    cv_poh_make         CONSTANT VARCHAR2(2)  := '20' ;        -- �����X�e�[�^�X(�����쐬��)
    cv_poh_cancel       CONSTANT VARCHAR2(2)  := '99' ;        -- �����X�e�[�^�X(���)
--
    -- *** ���[�J���E�ϐ� ***
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
    lv_sql        VARCHAR2(32000) ;  -- �f�[�^�擾�p�r�p�k
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ----------------------------------------------------
    -- �r�d�k�d�b�s�吶��
    -- ----------------------------------------------------
    lv_select := '  SELECT'
              || ' vnd.segment1              AS h_vend_code'     -- �w�b�_�F�o�ɑq�ɃR�[�h
              || ',vnd.vendor_short_name     AS h_vend_name'     -- �w�b�_�F�o�ɑq�ɖ�
              || ',poh.attribute4            AS h_deliver_date'  -- �w�b�_�F�[���\���
              || ',ctgg.category_code        AS h_goods_code'    -- �w�b�_�F�J�e�S���R�[�h�i���i�j
              || ',ctgg.category_description AS h_goods_name'    -- �w�b�_�F�J�e�S���E�v�i���i�j
              || ',ctgi.category_code        AS h_item_code'     -- �w�b�_�F�J�e�S���R�[�h�i�i�ځj
              || ',ctgi.category_description AS h_item_name'     -- �w�b�_�F�J�e�S���E�v�i�i�ځj
              || ',itm.item_no               AS item_code'       -- �i�ڃR�[�h
              || ',itm.item_short_name       AS item_name'       -- �i�ږ�
              || ',pln.attribute3            AS add_code'        -- �t�уR�[�h
              || ',lot.lot_no                AS lot_no'          -- ���b�g�m��
              || ',lot.attribute1            AS make_date'       -- �����N����
              || ',lot.attribute3            AS period_date'     -- �ܖ�����
              || ',lot.attribute2            AS prop_mark'       -- �ŗL�L��
              || ',pln.attribute4            AS inv_qty'         -- �݌ɓ���
              || ',pln.attribute11           AS po_qty'          -- ��������
              || ',pln.attribute10           AS po_uom'          -- �P��
              || ',poh.segment1              AS po_no'           -- �����ԍ�
              || ',itmv.segment1             AS dept_code'       -- ���ɑq�ɃR�[�h
              || ',itmv.description          AS dept_name'       -- ���ɑq�ɖ�
              || ',pln.attribute15           AS po_desc'         -- �����E�v
              || ',CASE'
              || '   WHEN ( ctgi.category_code = ''' || gv_item_class || ''') THEN '
              || '                             lot.attribute1 || lot.attribute2'
              || '   ELSE                      lot.lot_no'
              || ' END disp_odr1'                                      -- �\�������P
              ;
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    lv_from := ' FROM'
            || ' po_headers_all           poh'     -- �����w�b�_
            || ',po_lines_all             pln'     -- ��������
            || ',po_distributions_all     plc'     -- �����[������
            || ',xxcmn_vendors2_v         vnd'     -- �d������VIEW
            || ',xxcmn_item_mst2_v        itm'     -- OPM�i�ڏ��VIEW
            || ',xxcmn_item_locations2_v  itmv'    -- OPM�ۊǏꏊ���VIEW
            || ',xxpo_categories_v        ctgg'    -- XXPO�J�e�S�����VIEW�i���i�j
            || ',xxpo_categories_v        ctgi'    -- XXPO�J�e�S�����VIEW�i�i�ځj
            || ',xxcmn_item_categories4_v gic'     -- OPM�i�ڃJ�e�S������
            || ',ic_lots_mst              lot'     -- OPM���b�g�}�X�^
            ;
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    lv_where := ' WHERE'
             || '     poh.org_id                = ' || gn_sales_class
             || ' AND poh.po_header_id          = pln.po_header_id'
             || ' AND pln.po_line_id            = plc.po_line_id'
             || ' AND poh.authorization_status  = ''' || cv_poh_status || ''''
             || ' AND poh.attribute1           >= ''' || cv_poh_make   || ''''
             || ' AND poh.attribute1            < ''' || cv_poh_cancel || ''''
             || ' AND pln.cancel_flag          <> ''' || cv_pln_cancel_flag || ''''
             || ' AND poh.attribute4           >= ''' || ir_param.dlv_f || ''''
             ;
--
    -- ���ɑq�ɂ����͂���Ă���ꍇ
    IF (ir_param.dept_code IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute5          = ''' || ir_param.dept_code || ''''
               ;
    END IF;
--
    -- �[�����s�n�����͂���Ă���ꍇ
    IF (ir_param.dlv_t IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute4         <= ''' || ir_param.dlv_t || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- ���b�g���i�ڂ̍i���ݏ���
    lv_where := lv_where
             || ' AND pln.attribute1         = lot.lot_no  (+)'
             || ' AND pln.item_id            = itm.inventory_item_id'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.dlv_f || ''','''
                                                  || gc_char_d_format || ''')'
             || '     BETWEEN itm.start_date_active AND itm.end_date_active'
             ;
    -- �i�ڂ����͂���Ă���ꍇ
    IF (ir_param.item_code IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND itm.item_no          = ''' || ir_param.item_code || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �i�ڃJ�e�S���i���i�敪�j�̍i���ݏ���
    lv_where := lv_where
             || ' AND itm.item_id                          = gic.item_id'
             || ' AND gic.prod_class_code                  = ctgg.category_code '
             || ' AND ''' || gc_cat_set_goods_class || ''' = ctgg.category_set_name '
             ;
    -- ���i�敪�����͂���Ă���ꍇ
    IF (ir_param.goods_class IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND ctgg.category_code   = ''' || ir_param.goods_class || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �i�ڃJ�e�S���i�i�ڋ敪�j�̍i���ݏ���
    lv_where := lv_where
             || ' AND gic.item_class_code    = ctgi.category_code'
             || ' AND ctgi.category_set_name = ''' || gc_cat_set_item_class || ''''
             ;
    -- �i�ڋ敪�����͂���Ă���ꍇ
    IF (ir_param.item_class IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND ctgi.category_code   = ''' || ir_param.item_class || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �o�Ɍ��̍i���ݏ���
    lv_where := lv_where
             || ' AND poh.vendor_id          = vnd.vendor_id'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.dlv_f || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN vnd.start_date_active AND vnd.end_date_active'
             ;
    -- �o�Ɍ������͂���Ă���ꍇ
    IF (ir_param.vend_code IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND vnd.segment1         = ''' || ir_param.vend_code || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- ���ɑq�ɂ̍i���ݏ���
    lv_where := lv_where
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.dlv_f || ''','''
                                                  || gc_char_d_format  || ''') >= itmv.date_from'
             || ' AND (( itmv.date_to IS NULL )'
             || '   OR (( itmv.date_to IS NOT NULL )'
             || '     AND ( itmv.date_to >= FND_DATE.STRING_TO_DATE(''' || ir_param.dlv_f
                                         || ''',''' || gc_char_d_format  || '''))))'
             || ' AND itmv.disable_date IS NULL'
             || ' AND poh.attribute5    = itmv.segment1'
             ;
    ---------------------------------------------------------------------------------------------
    -- �Z�L�����e�B�敪�̍i���ݏ���
    -- �u�����v�̏ꍇ
    IF (ir_param.seqrt_class = gc_seqrt_class_vender) THEN
      lv_where := lv_where
               || ' AND (   ( poh.attribute3 = ''' || gn_user_vender_id || ''')'
               ;
      IF (gn_user_vender_id IS NULL) THEN
        -- �d����ID�Ȃ�
        lv_where := lv_where
                 || '      OR ((poh.vendor_id IS NULL)'
                 ;
      ELSE
        -- �d����ID����
        lv_where := lv_where
                 || '      OR ((poh.vendor_id  = ' || gn_user_vender_id || ')'
                 ;
      END IF;
      -- ���O�C�����[�U�[�̎d����T�C�g�R�[�h���ݒ肳��Ă���ꍇ
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_where := lv_where
                 || '        AND NOT EXISTS(SELECT po_line_id '
                 || '                       FROM   po_lines_all pl_sub '
                 || '                       WHERE  pl_sub.po_header_id = poh.po_header_id '
                 || '                       AND    NVL(pl_sub.attribute2,''*'') '
                 ||                          ' <> ''' || gv_user_vender_site || ''')'
                 ;
      END IF;
      lv_where := lv_where
               || '))'
               ;
    END IF;
    -- �u�O���q�Ɂv�̏ꍇ
    IF (ir_param.seqrt_class = gc_seqrt_class_outside) THEN
      IF ( gv_subinv_code.COUNT = 1 ) THEN
        lv_where := lv_where
          || ' AND itmv.segment1 = ''' || gv_subinv_code(1) || '''';
      ELSIF ( gv_subinv_code.COUNT > 1 ) THEN
        lv_where := lv_where
          || ' AND itmv.segment1 IN(' || fnc_get_in_statement(gv_subinv_code) || ')';
      END IF;
      lv_where := lv_where
               || ' AND poh.attribute5 = itmv.segment1'
               ;
    END IF;
--
    -- ----------------------------------------------------
    -- �n�q�c�d�q  �a�x�吶��
    -- ----------------------------------------------------
    lv_order_by := ' ORDER BY'
                || ' vnd.segment1'           -- �w�b�_�F�o�Ɍ��R�[�h
                || ',poh.attribute4'         -- �w�b�_�F�[����
                || ',ctgg.category_code'     -- �w�b�_�F�J�e�S���R�[�h�i���i�j
                || ',ctgi.category_code'     -- �w�b�_�F�J�e�S���R�[�h�i�i�ځj
                || ',itm.item_no'            -- �i��
                || ',pln.attribute3'         -- �t��
                || ',disp_odr1'              -- �\�������P
                || ',itmv.segment1'          -- ���ɑq�ɃR�[�h
                || ',poh.segment1'           -- �����ԍ�
                ;
--
    -- ====================================================
    -- �r�p�k����
    -- ====================================================
    lv_sql := lv_select || lv_from || lv_where || lv_order_by ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN lc_ref FOR lv_sql ;
    -- �o���N�t�F�b�`
    FETCH lc_ref BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
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
   * Description      : �f�[�^�o��(C-3)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data (
      ir_param          IN  rec_param_data    -- 01.���R�[�h  �F�p�����[�^
     ,ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���萔 ***
    -- �L�[�u���C�N���f�p
    lc_break_init           VARCHAR2(100) :=      '*' ;            -- �����l
    lc_break_null           VARCHAR2(100) :=      '**' ;           -- �m�t�k�k����
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_vend_name            VARCHAR2(100) DEFAULT lc_break_init ;  -- �o�Ɍ�
    lv_h_dlv_f              VARCHAR2(100) DEFAULT lc_break_init ;  -- �[����
    lv_goods_class          VARCHAR2(100) DEFAULT lc_break_init ;  -- ���i�敪
    lv_item_class           VARCHAR2(100) DEFAULT lc_break_init ;  -- �i�ڋ敪
    lv_item_code            VARCHAR2(100) DEFAULT lc_break_init ;  -- �i�ڃR�[�h
    lv_futai                VARCHAR2(100) DEFAULT lc_break_init ;  -- �t��
    lv_dept_code            VARCHAR2(100) DEFAULT lc_break_init ;  -- ���ɑq��
    lv_po_no                VARCHAR2(100) DEFAULT lc_break_init ;  -- �����m��
--
    -- �v�Z�p
    ln_position             NUMBER        DEFAULT 0 ;              -- �v�Z�p�F�|�W�V����
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;             -- �擾���R�[�h�Ȃ�
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
    -- ���ڃf�[�^���o����
    -- =====================================================
    prc_get_report_data (
        ir_param      => ir_param       -- 01.���̓p�����[�^�Q
       ,ot_data_rec   => gt_main_data   -- 02.�擾���R�[�h�Q
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
    -- ���[�h�c
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
    -- ���{��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format ) ;
    -- �S������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gv_user_dept, 1, 10 ) ;
    -- �S���Җ�
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gv_user_name, 1, 14 ) ;
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
    -- �o�Ɍ��k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- �o�Ɍ����̃u���C�N
      -- =====================================================
      -- �o�Ɍ����̂��؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).h_vend_name, lc_break_null ) <> lv_vend_name ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_vend_name <> lc_break_init ) THEN
          ------------------------------
          -- ���b�g�k�f�I���^�O�o��
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ɑq�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ɑq�Ƀw�b�_�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ׂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���i�敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���i�敪�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[�����f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[�����k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �o�Ɍ��f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_locat' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
        -- -----------------------------------------------------
        -- �o�Ɍ��f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_locat' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �o�Ɍ��f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �o�Ɍ��F�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'locat_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).h_vend_code ;
        -- �o�Ɍ��F����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'locat_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).h_vend_name, 1, 20) ;
        -- -----------------------------------------------------
        -- �[�����k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_deliver' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_vend_name  := NVL( gt_main_data(i).h_vend_name, lc_break_null )  ;
        lv_h_dlv_f := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- �[�����u���C�N
      -- =====================================================
      -- �[�������؂�ւ�����ꍇ
      IF ( gt_main_data(i).h_deliver_date <> lv_h_dlv_f ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_h_dlv_f <> lc_break_init ) THEN
          ------------------------------
          -- ���b�g�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ɑq�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ɑq�Ƀw�b�_�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ׂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���i�敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���i�敪�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �[�����f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
        -- -----------------------------------------------------
        -- �[�����f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_deliver' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �[�����f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �[����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).h_deliver_date ;
        ------------------------------
        -- ���i�敪�k�f�J�n�^�O
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_h_dlv_f := gt_main_data(i).h_deliver_date ;
        lv_goods_class  := lc_break_init ;
        -- �W�v�ϐ��O�N���A
        ln_position     := 0 ;  -- �v�Z�p�F�|�W�V����
--
      END IF ;
--
      -- =====================================================
      -- ���i�敪�u���C�N
      -- =====================================================
      -- ���i�敪���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).h_goods_code, lc_break_null ) <> lv_goods_class ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_goods_class <> lc_break_init ) THEN
          ------------------------------
          -- ���b�g�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ɑq�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ɑq�Ƀw�b�_�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ׂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���i�敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
        ------------------------------
        -- ���i�敪�f�J�n�^�O
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- ���i�敪�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �|�W�V����
        ln_position := ln_position + 1;
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'position' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ln_position ) ;
        -- ���i�敪�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).h_goods_code ;
        -- ���i�敪����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).h_goods_name, 1, 30 ) ;
        -- -----------------------------------------------------
        -- �i�ڋ敪�k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_goods_class  := NVL( gt_main_data(i).h_goods_code, lc_break_null )  ;
        lv_item_class   := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- �i�ڋ敪�u���C�N
      -- =====================================================
      -- �i�ڋ敪���؂�ւ�����ꍇ
      IF ( NVL ( gt_main_data(i).h_item_code, lc_break_null ) <> lv_item_class ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_item_class <> lc_break_init ) THEN
          ------------------------------
          -- ���b�g�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ɑq�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ɑq�Ƀw�b�_�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ׂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڋ敪�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
        -- -----------------------------------------------------
        -- �i�ڋ敪�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �i�ڋ敪�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �i�ڋ敪�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).h_item_code ;
        -- �i�ڋ敪����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).h_item_name, 1, 30 ) ;
        -- -----------------------------------------------------
        -- �i�ڂk�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_item_class   := NVL( gt_main_data(i).h_item_code, lc_break_null )  ;
        lv_item_code    := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- �i�ڃu���C�N
      -- =====================================================
      -- �i�ڂ��؂�ւ�����ꍇ
      IF ( gt_main_data(i).item_code <> lv_item_code ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_item_code <> lc_break_init ) THEN
          ------------------------------
          -- ���b�g�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ɑq�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ɑq�Ƀw�b�_�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ׂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ׂk�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
        -- -----------------------------------------------------
        -- �i�ڂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �i�ڃf�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �i�ڃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_code ;
        -- �i�ږ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).item_name, 1 ,20 ) ;
        -- �P��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'uom_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).po_uom ;
        -- -----------------------------------------------------
        -- �o�ɖ��ׂk�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_item_code    := NVL( gt_main_data(i).item_code, lc_break_null )  ;
        lv_futai        := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- �t�уu���C�N
      -- =====================================================
      -- �t�т��؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).add_code, lc_break_null ) <> lv_futai ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_futai <> lc_break_init ) THEN
          ------------------------------
          -- ���b�g�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ɑq�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ɑq�Ƀw�b�_�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ׂf�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
        -- -----------------------------------------------------
        -- ���ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- ���׃f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �t�уR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).add_code ;
        -- -----------------------------------------------------
        -- ���ɑq�Ƀw�b�_�k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_futai     := NVL( gt_main_data(i).add_code, lc_break_null )  ;
        lv_dept_code := lc_break_init ;
        lv_po_no     := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- ���ɑq�Ƀw�b�_�u���C�N
      -- =====================================================
      -- ���ɑq�ɂ܂��͔����m�n���؂�ւ�����ꍇ
      IF (( NVL ( gt_main_data(i).dept_code, lc_break_null ) <> lv_dept_code )
        OR ( NVL ( gt_main_data(i).po_no, lc_break_null ) <> lv_po_no )) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF (( lv_dept_code <> lc_break_init )
          AND ( lv_po_no <> lc_break_init )) THEN
          ------------------------------
          -- ���b�g�k�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- ���ɑq�Ƀw�b�_�f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- ���ɑq�Ƀw�b�_�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- ���׃f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �����m��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'order_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).po_no ;
        -- ���ɑq�ɃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_from_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).dept_code ;
        -- ���ɑq�ɖ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_from_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).dept_name, 1, 20) ;
        -- -----------------------------------------------------
        -- ���b�g�k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_lot' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_dept_code := NVL( gt_main_data(i).dept_code, lc_break_null ) ;
        lv_po_no     := NVL( gt_main_data(i).po_no    , lc_break_null ) ;
--
      END IF ;
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
      -- -----------------------------------------------------
      -- ���b�g�f�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���ׂf�f�[�^�^�O�o��
      -- -----------------------------------------------------
      -- ���b�g�m��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).lot_no ;
      -- ������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).make_date ;
      -- �ܖ�����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).period_date ;
      -- �ŗL�L��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prop_mark ;
      -- ����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'frequent_qty' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).inv_qty ;
      -- ����
      -- Null�ł���ꍇ�A�^�O���o�͂��Ȃ�
      IF ( gt_main_data(i).po_qty IS NOT NULL ) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quantity' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).po_qty ;
      END IF ;
      -- �E�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'description' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).po_desc, 1, 30 ) ;
      -- -----------------------------------------------------
      -- ���b�g�f�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    ------------------------------
    -- ���b�g�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- ���ɑq�Ƀw�b�_�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- ���ɑq�Ƀw�b�_�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- ���ׂf�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- ���ׂk�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i�ڂf�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i�ڂk�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i�ڋ敪�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �i�ڋ敪�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- ���i�敪�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- ���i�敪�k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �[�����f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �[�����k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �o�Ɍ��f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �o�Ɍ��k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_locat' ;
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
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-00009' ) ;
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
      iv_vend_code    IN    VARCHAR2  -- 01 : �o�Ɍ�
     ,iv_dlv_f        IN    VARCHAR2  -- 02 : �[����FROM
     ,iv_dlv_t        IN    VARCHAR2  -- 03 : �[����TO
     ,iv_goods_class  IN    VARCHAR2  -- 04 : ���i�敪
     ,iv_item_class   IN    VARCHAR2  -- 05 : �i�ڋ敪
     ,iv_item_code    IN    VARCHAR2  -- 06 : �i��
     ,iv_dept_code    IN    VARCHAR2  -- 07 : ���ɑq��
     ,iv_seqrt_class  IN    VARCHAR2  -- 08 : �Z�L�����e�B�敪
     ,ov_errbuf       OUT   VARCHAR2  --      �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      OUT   VARCHAR2  --      ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       OUT   VARCHAR2  --      ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf  VARCHAR2(5000) ;                          --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                             --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                          --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lr_param_rec            rec_param_data ;             -- �p�����[�^��n���p
--
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
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
    gv_report_id              := 'XXPO360002T' ;      -- ���[ID
    gd_exec_date              := SYSDATE ;            -- ���{��
    -- �p�����[�^�i�[
    lr_param_rec.vend_code    := iv_vend_code ;       -- �o�Ɍ�
    lr_param_rec.dlv_f        := TO_CHAR(FND_DATE.STRING_TO_DATE(iv_dlv_f,gc_char_dt_format),
                                   gc_char_d_format); -- �[�i��FROM
    lr_param_rec.dlv_t        := TO_CHAR(FND_DATE.STRING_TO_DATE(iv_dlv_t,gc_char_dt_format),
                                   gc_char_d_format); -- �[�i��TO
    lr_param_rec.goods_class  := iv_goods_class ;     -- ���i�敪
    lr_param_rec.item_class   := iv_item_class ;      -- �i�ڋ敪
    lr_param_rec.item_code    := iv_item_code ;       -- �i�ڃR�[�h
    lr_param_rec.dept_code    := iv_dept_code ;       -- ���ɑq��
    lr_param_rec.seqrt_class  := iv_seqrt_class ;     -- �Z�L�����e�B�敪
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize (
        ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data (
        ir_param          => lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  (( lv_errmsg IS NOT NULL )
      AND ( lv_retcode = gv_status_warn )) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_deliver>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_deliver>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <position>1</position>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_deliver>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_deliver>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,'APP-XXPO-10026'
                                            ,'TABLE'
                                            ,gv_print_name );
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
        lv_xml_string := fnc_conv_xml (
                            iv_name   => gt_xml_data_table(i).tag_name    -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- �^�O�^�C�v
                          ) ;
--  ���o�f�[�^�m�F�p
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
--#################################  �Œ��O������ START   ##############################
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
--####################################  �Œ蕔 END   #####################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main (
      errbuf          OUT   VARCHAR2  --      �G���[���b�Z�[�W
     ,retcode         OUT   VARCHAR2  --      �G���[�R�[�h
     ,iv_vend_code    IN    VARCHAR2  -- 01 : �o�Ɍ�
     ,iv_dlv_f        IN    VARCHAR2  -- 02 : �[����FROM
     ,iv_dlv_t        IN    VARCHAR2  -- 03 : �[����TO
     ,iv_goods_class  IN    VARCHAR2  -- 04 : ���i�敪
     ,iv_item_class   IN    VARCHAR2  -- 05 : �i�ڋ敪
     ,iv_item_code    IN    VARCHAR2  -- 06 : �i��
     ,iv_dept_code    IN    VARCHAR2  -- 07 : ���ɑq��
     ,iv_seqrt_class  IN    VARCHAR2  -- 08 : �Z�L�����e�B�敪
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
        iv_vend_code    =>  iv_vend_code    -- 01 : �o�Ɍ�
       ,iv_dlv_f        =>  iv_dlv_f        -- 02 : �[����FROM
       ,iv_dlv_t        =>  iv_dlv_t        -- 03 : �[����TO
       ,iv_goods_class  =>  iv_goods_class  -- 04 : ���i�敪
       ,iv_item_class   =>  iv_item_class   -- 05 : �i�ڋ敪
       ,iv_item_code    =>  iv_item_code    -- 06 : �i��
       ,iv_dept_code    =>  iv_dept_code    -- 07 : ���ɑq��
       ,iv_seqrt_class  =>  iv_seqrt_class  -- 08 : �Z�L�����e�B�敪
       ,ov_errbuf       =>  lv_errbuf       --      �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode      =>  lv_retcode      --      ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg       =>  lv_errmsg       --      ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   ############################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF (( lv_retcode = gv_status_error )
      OR ( lv_retcode = gv_status_warn )) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
    END IF ;
--
    -- �X�e�[�^�X�Z�b�g
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
--###########################  �Œ蕔 END   ##############################################
--
END xxpo360002c ;
/
