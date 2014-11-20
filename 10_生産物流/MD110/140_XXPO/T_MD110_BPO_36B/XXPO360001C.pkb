CREATE OR REPLACE PACKAGE BODY xxpo360001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo360001c(body)
 * Description      : ������
 * MD.050/070       : �d���i���[�jIssue1.0(T_MD050_BPO_360)
 *                    �d���i���[�jIssue1.0(T_MD070_BPO_36B)
 * Version          : 1.11
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  fnc_show_ctl              FUNCTION  : �\������B
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_initialize            PROCEDURE : �O����(A-1)
 *  prc_get_report_data       PROCEDURE : �f�[�^�擾(A-2)
 *  prc_create_xml_data       PROCEDURE : XML�f�[�^�o��(A-3)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/14    1.0   C.Kinjo          �V�K�쐬
 *  2008/05/14    1.1   R.Tomoyose       �������ׂƎd����T�C�gID�̕R�t�����C��
 *                                       ���l���ڂ̒l��0�̏ꍇ�͒l���o�͂��Ȃ�(�u�����N�ɂ���)
 *  2008/05/19    1.2   Y.Ishikawa       ������ID�����݂��Ȃ��ꍇ�ł��o�͂���悤�ɕύX
 *  2008/05/20    1.3   T.Endou          �Z�L�����e�B�O���q�ɂ̕s��Ή�
 *  2008/05/20    1.4   T.Endou          ���o�Ɋ��Z�P�ʂ�����ꍇ�́A�d�����z�v�Z���@�~�X�C��
 *  2008/06/10    1.5   Y.Ishikawa       ���b�g�}�X�^�ɓ������b�gNo�����݂���ꍇ�A2���׏o�͂����
 *  2008/06/17    1.6   T.Ikehara        TEMP�̈�G���[����̂��߁Axxpo_categories_v��
 *                                       �g�p���Ȃ��悤�ɂ���
 *  2008/06/25    1.7   I.Higa           ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/06/27    1.8   R.Tomoyose       ���ׂ��ő�s�o�́i�U�s�o�́j�̎��ɁA
 *                                       ���v�����y�[�W�ɕ\������錻�ۂ��C��
 *  2008/10/21    1.9   T.Ohashi         �w�E382�Ή�
 *  2008/11/20    1.10  T.Ohashi         �w�E664�Ή�
 *  2009/03/30    1.11  A.Shiina         �{��#1346�Ή�
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
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo360001c' ;   -- �p�b�P�[�W��
  gv_print_name           CONSTANT VARCHAR2(20) := '������' ;   -- ���[��
--
  ------------------------------
  -- �Z�L�����e�B�敪
  ------------------------------
  gc_seqrt_class_itoen      CONSTANT VARCHAR2(1) := '1';     -- �ɓ���
  gc_seqrt_class_vender     CONSTANT VARCHAR2(1) := '2';     -- �����i�����ҁj
  gc_seqrt_class_outside    CONSTANT VARCHAR2(1) := '4';     -- �O���q��
--
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gc_cat_set_goods_class        CONSTANT VARCHAR2(100) := '���i�敪' ;
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '�i�ڋ敪' ;
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;          -- �A�v���P�[�V����
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;           -- �A�v���P�[�V�����iXXPO�j
--
  gv_seqrt_view           CONSTANT VARCHAR2(30) := '�L���x���Z�L�����e�BVIEW' ;
  gv_seqrt_view_key       CONSTANT VARCHAR2(20) := '�]�ƈ�ID' ;
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  ------------------------------
  -- �����敪
  ------------------------------
  gv_direct_type_u    CONSTANT VARCHAR2( 1) := '1';  -- �����敪(�ʏ�)
  gv_direct_type_p    CONSTANT VARCHAR2( 1) := '2';  -- �����敪(�o��)
  gv_direct_type_s    CONSTANT VARCHAR2( 1) := '3';  -- �����敪(�x��)
  ------------------------------
  -- �g�p�ړI
  ------------------------------
  gv_use_site_po      CONSTANT VARCHAR2( 1) := '1';  -- �g�p�ړI(������)
  gv_use_site_po_inst CONSTANT VARCHAR2( 1) := '2';  -- �g�p�ړI(�����w����)
--
  -- ���i�敪
  gv_goods_classe_drink  CONSTANT VARCHAR2(1) := '2'; -- ���i�敪�F2(�h�����N)
  -- ���i�敪
  gv_item_class_products CONSTANT VARCHAR2(1) := '5'; -- �i�ڋ敪�F5(���i)
--
  -- ���b�g�Ǘ��敪
  gv_lot_n_div           CONSTANT VARCHAR2(1) := '0'; -- ���b�g�Ǘ��Ȃ�
--
  -- ���b�g�f�t�H���g��
  gv_lot_default CONSTANT ic_lots_mst.lot_no%TYPE  := 'DEFAULTLOT'; --�f�t�H���g���b�g��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD (
      site_use            fnd_lookup_values.lookup_code%TYPE             -- 01 : �g�p�ړI
     ,po_number           po_headers_all.segment1%TYPE                   -- 02 : �����ԍ�
     ,role_department     xxcmn_locations_v.location_code%TYPE           -- 03 : �S������
     ,role_people         xxpo_per_all_people_f_v.employee_number%TYPE   -- 04 : �S����
     ,create_date_from    VARCHAR2(21)                                   -- 05 : �쐬��FROM
     ,create_date_to      VARCHAR2(21)                                   -- 06 : �쐬��TO
     ,vendor_code         xxcmn_vendors_v.segment1%TYPE                  -- 07 : �����
     ,mediation           xxcmn_vendors_v.segment1%TYPE                  -- 08 : ������
     ,delivery_date_from  VARCHAR2(10)                                   -- 09 : �[����FROM
     ,delivery_date_to    VARCHAR2(10)                                   -- 10 : �[����TO
     ,delivery_to         xxcmn_item_locations_v.segment1%TYPE           -- 11 : �[����
     ,product_type        xxpo_categories_v.category_code%TYPE           -- 12 : ���i�敪
     ,item_type           xxpo_categories_v.category_code%TYPE           -- 13 : �i�ڋ敪
     ,security_type       VARCHAR2(1)                                    -- 14 : �Z�L�����e�B�敪
    ) ;
--
  -- �������f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD (
      po_number                   po_headers_all.segment1%TYPE            -- �����ԍ�
     ,business_partner_num        xxcmn_vendors2_v.segment1%TYPE          -- �����R�[�h
     ,business_partner_name       xxcmn_vendors2_v.vendor_full_name%TYPE  -- ����於
     ,mediator_num                xxcmn_vendors2_v.segment1%TYPE          -- �����҃R�[�h
     ,mediator_name               xxcmn_vendors2_v.vendor_full_name%TYPE  -- �����Җ�
     ,delivery_date               po_headers_all.attribute4%TYPE          -- �[����
     ,delivery_to_num             xxcmn_item_locations_v.segment1%TYPE    -- �[����R�[�h
     ,delivery_to_name            xxcmn_item_locations_v.description%TYPE -- �[���於
     ,direct_type                 po_headers_all.attribute6%TYPE          -- �����敪
     ,description                 po_headers_all.attribute15%TYPE         -- �����w�b�_/�E�v
     ,incident                    po_lines_all.attribute3%TYPE            -- �t�уR�[�h
     ,inventory_quantity          po_lines_all.attribute4%TYPE            -- �݌ɓ���
     ,quantity                    po_lines_all.attribute11%TYPE           -- ��������
     ,unit_of_measure             po_lines_all.attribute10%TYPE           -- �����P��
     ,unit_price                  po_lines_all.attribute8%TYPE            -- �d���艿
     ,factory_code                po_lines_all.attribute2%TYPE            -- �H��R�[�h
     ,division                    po_line_locations_all.attribute1%TYPE   -- ������
     ,unit_price_rate             po_line_locations_all.attribute2%TYPE   -- ������P��
     ,amount                      po_line_locations_all.attribute9%TYPE   -- ��������z
     ,commission_unit_price_rate  po_line_locations_all.attribute4%TYPE   -- ���K
     ,commission_amount           po_line_locations_all.attribute5%TYPE   -- �a����K���z
     ,description2                po_lines_all.attribute15%TYPE           -- ��������/�E�v
     ,levy_unit_price_rate        po_line_locations_all.attribute7%TYPE   -- ���ۋ�
     ,levy_amount                 po_line_locations_all.attribute8%TYPE   -- ���ۋ��z
     ,item_code                   xxcmn_item_mst2_v.item_no%TYPE          -- �i�ڃR�[�h
     ,item_name                   xxcmn_item_mst2_v.item_name%TYPE        -- �i�ږ���
     ,lot_number                  ic_lots_mst.lot_no%TYPE                 -- ���b�g�m��
     ,wip_date                    ic_lots_mst.attribute1%TYPE             -- �����N����
     ,best_before_date            ic_lots_mst.attribute3%TYPE             -- �ܖ�����
     ,peculiar_mark               ic_lots_mst.attribute2%TYPE             -- �ŗL�L��
     ,year                        ic_lots_mst.attribute11%TYPE            -- �N�x
     ,lank1                       ic_lots_mst.attribute14%TYPE            -- �����N1
     ,lank2                       ic_lots_mst.attribute15%TYPE            -- �����N2
     ,lank3                       ic_lots_mst.attribute19%TYPE            -- �����N3
     ,direct_name                 fnd_lookup_values.meaning%TYPE          -- ��������(���o)
     ,vender_form                 fnd_lookup_values.meaning%TYPE          -- ��������(�d���`��)
     ,tea_time_division           fnd_lookup_values.meaning%TYPE          -- ��������(�����敪)
     ,Place_of_production         fnd_lookup_values.meaning%TYPE          -- ��������(�Y�n)
     ,l_type                      fnd_lookup_values.meaning%TYPE          -- ��������(�^�C�v)
     ,commission_division         fnd_lookup_values.meaning%TYPE          -- ��������(���K�敪)
     ,levy_amount_division        fnd_lookup_values.meaning%TYPE          -- ��������(���ۋ��敪)
     ,drop_code                   VARCHAR2(9)                             -- �x��/�o�׃R�[�h
     ,drop_name                   VARCHAR2(60)                            -- �x��/�o�א�����
     ,drop_zip                    VARCHAR2(8)                             -- �x��/�o�חX�֔ԍ�
     ,drop_address1               VARCHAR2(30)                            -- �x��/�o�׏Z���P
     ,drop_address2               VARCHAR2(30)                            -- �x��/�o�׏Z���Q
-- add start ver1.10
     ,phone                       VARCHAR2(30)                            -- �x��/�o�דd�b�ԍ�
-- add end ver1.10
     ,factory_name                xxcmn_vendor_sites_v.vendor_site_name%TYPE -- �H�ꖼ
     ,dept_code                   po_headers_all.attribute10%TYPE            -- �����R�[�h
     ,vendor_id                   xxcmn_vendors2_v.vendor_id%TYPE            -- �d����h�c
     ,product_type                xxpo_categories_v.category_code%TYPE       -- ���i�敪
     ,item_type                   xxpo_categories_v.category_code%TYPE       -- �i�ڋ敪
     ,base_uom                    po_lines_all.unit_meas_lookup_code%TYPE    -- ������P��
     ,num_of_cases                xxcmn_item_mst2_v.num_of_cases%TYPE        -- �P�[�X����
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
  TYPE subinv_code_type IS TABLE OF
    xxpo_security_supply_v.segment1%TYPE INDEX BY BINARY_INTEGER; -- �ۊǑq�ɃR�[�h
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%type ;     -- �c�ƒP��
  gv_user_vender            xxpo_per_all_people_f_v.attribute4%TYPE;   -- �d����R�[�h
  gv_user_vender_site       xxpo_per_all_people_f_v.attribute6%TYPE;   -- �d����T�C�g�R�[�h
  gn_user_vender_id         po_vendors.vendor_id%TYPE;                 -- �d����ID
  gv_subinv_code            subinv_code_type;                          -- �ۊǑq�ɃR�[�h
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id              VARCHAR2(12) ;    -- ���[ID
  gd_exec_date              DATE         ;    -- ���{��
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
  /**********************************************************************************
   * Function Name    : fnc_show_ctl
   * Description      : �\������
   ***********************************************************************************/
  FUNCTION fnc_show_ctl (
      iv_value             IN        VARCHAR2   -- �o�̓f�[�^
     ,ic_type              IN        CHAR       -- �g�p�ړI
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_show_ctl' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�g�p�ړI =�u�������v�̏ꍇ
    IF (ic_type = gv_use_site_po) THEN
      lv_data := iv_value;
    --�g�p�ړI =�u�����w�����v�̏ꍇ
    ELSIF (ic_type = gv_use_site_po_inst) THEN
      lv_data := ' ';
    END IF ;
--
    RETURN(lv_data) ;
--
  END fnc_show_ctl ;
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
   * Description      : �O����(A-1)
   ***********************************************************************************/
  PROCEDURE prc_initialize(
      ir_param      IN     rec_param_data   -- 01.���̓p�����[�^�Q
     ,ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
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
    IF ( ir_param.security_type = gc_seqrt_class_outside ) THEN
      -- ====================================================
      -- �ۊǑq�ɃR�[�h�擾(�����̏ꍇ�L)
      -- ====================================================
      BEGIN
        SELECT xssv.segment1
          BULK COLLECT INTO gv_subinv_code
        FROM  xxpo_security_supply_v xssv
        WHERE xssv.user_id        = gn_user_id
          AND xssv.security_class = ir_param.security_type;
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
          AND xssv.user_id = gn_user_id
          AND xssv.security_class = ir_param.security_type
          AND FND_DATE.STRING_TO_DATE( ir_param.delivery_date_from, gc_char_d_format )
              BETWEEN vnd.start_date_active (+) AND vnd.end_date_active (+) ;
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
    END IF;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
--
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
   * Description      : �f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
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
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���E�萔 ***
    cv_pln_cancel_flag  CONSTANT VARCHAR2( 1) := 'Y';          -- ����t���O�i����j
    cv_poh_status       CONSTANT VARCHAR2(10) := 'APPROVED';   -- �����X�e�[�^�X�i���F�ς݁j
    cv_poh_make         CONSTANT VARCHAR2( 2) := '20';         -- ������޵ݽð��(�����쐬��)
    cv_poh_cancel       CONSTANT VARCHAR2( 2) := '99';         -- ������޵ݽð��(���)
    cv_lookup_type_drop_ship  CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXPO_DROP_SHIP_TYPE';
    cv_lookup_type_l05        CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_L05';
    cv_lookup_type_l06        CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_L06';
    cv_lookup_type_l07        CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_L07';
    cv_lookup_type_l08        CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_L08';
    cv_lookup_type_kousen_type  CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXPO_KOUSEN_TYPE';
    cv_lookup_type_gukakin_type CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXPO_FUKAKIN_TYPE';
    cv_ja               CONSTANT VARCHAR2(100) := 'JA' ;
--
    -- *** ���[�J���E�ϐ� ***
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
    lv_sql        VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
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
              || ' poh.segment1          AS po_number'                  -- �����ԍ�
              || ',xve1.segment1         AS cust_cd'                    -- �����R�[�h
              || ',xve1.vendor_full_name AS cust_nm'                    -- ����於
              || ',xve2.segment1         AS med_cd'                     -- �����҃R�[�h
              || ',xve2.vendor_full_name AS med_nm'                     -- �����Җ�
              || ',poh.attribute4        AS deli_date'                  -- �[����
              || ',xil.segment1          AS deli_cd'                    -- �[����R�[�h
              || ',xil.description       AS deli_nm'                    -- �[���於
              || ',poh.attribute6        AS direct_type'                -- �����敪
              || ',poh.attribute15       AS poh_description'            -- �����w�b�_/�E�v
              || ',pol.attribute3        AS hutai_cd'                   -- �t�уR�[�h
              || ',pol.attribute4        AS inv_incnt'                  -- �݌ɓ���
              || ',pol.attribute11       AS po_cnt'                     -- ��������
              || ',pol.attribute10       AS po_units'                   -- �����P��
              || ',pol.attribute8        AS buy_price'                  -- �d���艿
              || ',pol.attribute2        AS factory_code'               -- �H��R�[�h
              || ',polo.attribute1       AS division'                   -- ������
              || ',polo.attribute2       AS unit_price_rate'            -- ������P��
              || ',polo.attribute9       AS amount'                     -- ��������z
              || ',polo.attribute4       AS commission_unit_price_rate' -- ���K
              || ',polo.attribute5       AS commission_amount'          -- �a����K���z
              || ',pol.attribute15       AS pol_description'            -- ��������/�E�v
              || ',polo.attribute7       AS levy_unit_price_rate'       -- ���ۋ�
              || ',polo.attribute8       AS levy_amount'                -- ���ۋ��z
              || ',xim.item_no           AS item_no'                    -- �i�ڃR�[�h
              || ',xim.item_name         AS item_nm'                    -- �i�ږ���
              || ',DECODE(xim.lot_ctl,'  || gv_lot_n_div
              || '  ,NULL,iclt.lot_no)   AS lot_no'                     -- ���b�g�m��
              || ',iclt.attribute1       AS manu_date'                  -- �����N����
              || ',iclt.attribute3       AS use_by_date'                -- �ܖ�����
              || ',iclt.attribute2       AS peculiar_mark'              -- �ŗL�L��
              || ',iclt.attribute11      AS year'                       -- �N�x
              || ',iclt.attribute14      AS lank1'                      -- �����N1
              || ',iclt.attribute15      AS lank2'                      -- �����N2
              || ',iclt.attribute19      AS lank3'                      -- �����N3
              || ',flv1.meaning          AS direct_name'                -- ��������(���o)
              || ',flv2.meaning          AS vender_form'                -- ��������(�d���`��)
              || ',flv3.meaning          AS tea_time_division'          -- ��������(�����敪)
              || ',flv4.meaning          AS Place_of_production'        -- ��������(�Y�n)
              || ',flv5.meaning          AS l_type'                     -- ��������(�^�C�v)
              || ',flv6.meaning          AS commission_division'        -- ��������(���K�敪)
              || ',flv7.meaning          AS levy_amount_division'       -- ��������(���ۋ��敪)
              || ',CASE '
              || ' WHEN poh.attribute6 = '|| gv_direct_type_p ||' THEN ' -- �o�ׂ̏ꍇ
              || '      xps.party_site_number '    -- �p�[�e�B�T�C�g�ԍ�
              || ' WHEN poh.attribute6 = '|| gv_direct_type_s ||' THEN ' -- �x���̏ꍇ
              || '      xves2.vendor_site_code '   -- �d����T�C�g��
              || ' END  AS drop_code '             -- �x��/�o�׃R�[�h
              || ',CASE '
              || ' WHEN poh.attribute6 = '|| gv_direct_type_p ||' THEN ' -- �o�ׂ̏ꍇ
              || '      xps.party_site_full_name ' -- �p�[�e�B�T�C�g������
              || ' WHEN poh.attribute6 = '|| gv_direct_type_s ||' THEN ' -- �x���̏ꍇ
              || '      xves2.vendor_site_name '   -- �d����T�C�g������
              || ' END  AS drop_name '             -- �x��/�o�א�����
              || ',CASE '
              || ' WHEN poh.attribute6 = '|| gv_direct_type_p ||' THEN ' -- �o�ׂ̏ꍇ
              || '      xps.zip '                  -- �p�[�e�B�T�C�g�X�֔ԍ�
              || ' WHEN poh.attribute6 = '|| gv_direct_type_s ||' THEN ' -- �x���̏ꍇ
              || '      xves2.zip '                -- �d����T�C�g�X�֔ԍ�
              || ' END  AS drop_zip  '             -- �x��/�o�חX�֔ԍ�
              || ',CASE '
              || ' WHEN poh.attribute6 = '|| gv_direct_type_p ||' THEN ' -- �o�ׂ̏ꍇ
              || '      xps.address_line1 '        -- �p�[�e�B�T�C�g�Z���P
              || ' WHEN poh.attribute6 = '|| gv_direct_type_s ||' THEN ' -- �x���̏ꍇ
              || '      xves2.address_line1 '      -- �d����T�C�g�Z���P
              || ' END  AS drop_address1 '         -- �x��/�o�׏Z���P
              || ',CASE '
              || ' WHEN poh.attribute6 = '|| gv_direct_type_p ||' THEN ' -- �o�ׂ̏ꍇ
              || '      xps.address_line2 '        -- �p�[�e�B�T�C�g�Z���Q
              || ' WHEN poh.attribute6 = '|| gv_direct_type_s ||' THEN ' -- �x���̏ꍇ
              || '      xves2.address_line2 '      -- �d����T�C�g�Z���Q
              || ' END  AS drop_address2 '         -- �x��/�o�׏Z���Q
-- add start ver1.10
              || ',CASE '
              || ' WHEN poh.attribute6 = '|| gv_direct_type_p ||' THEN ' -- �o�ׂ̏ꍇ
              || '      xps.phone '                -- �p�[�e�B�T�C�g�d�b�ԍ�
              || ' WHEN poh.attribute6 = '|| gv_direct_type_s ||' THEN ' -- �x���̏ꍇ
              || '      xves2.phone '              -- �d����T�C�g�d�b�ԍ�
              || ' END  AS phone '                 -- �x��/�o�דd�b�ԍ�
-- add end ver1.10
              || ',xves3.vendor_site_name AS factory_name'           -- �H�ꖼ
              || ',poh.attribute10        AS dept_code'              -- �����R�[�h
              || ',xve1.vendor_id         AS vendor_id'              -- �d����h�c
              || ',xpoc1.category_code       AS product_type' -- ���i�敪
              || ',xpoc2.category_code       AS item_type'    -- �i�ڋ敪
              || ',pol.unit_meas_lookup_code AS base_uom'     -- ������P��
              || ',xim.num_of_cases          AS num_of_cases' -- �P�[�X����
              ;
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    lv_from := ' FROM'
            || ' po_headers_all             poh'   -- �����w�b�_
            || ',xxpo_headers_all           xpoh'  -- �����w�b�_(�A�h�I��)
            || ',po_lines_all               pol'   -- ��������
            || ',po_line_locations_all      polo'  -- �[������
            || ',ic_lots_mst                iclt'  -- opm���b�g�}�X�^
            || ',xxcmn_item_mst2_v          xim'   -- opm�i�ڏ��view
            || ',(SELECT mcb.segment1  AS category_code '
            || ',  mcb.category_id AS category_id '
            || ',  mcst.category_set_id AS category_set_id '
            || '  FROM   mtl_category_sets_tl  mcst, '
            || '   mtl_category_sets_b   mcsb, '
            || '   mtl_categories_b      mcb '
            || '  WHERE mcsb.category_set_id  = mcst.category_set_id '
            || '  AND   mcst.language         = ''' || cv_ja || ''''
            || '  AND   mcsb.structure_id     = mcb.structure_id '
            || '  AND  mcst.category_set_name = '''|| gc_cat_set_goods_class || '''' || ') xpoc1'
            || ',(SELECT mcb.segment1  AS category_code '
            || ',  mcb.category_id AS category_id '
            || ',  mcst.category_set_id AS category_set_id '
            || '  FROM   mtl_category_sets_tl  mcst, '
            || '   mtl_category_sets_b   mcsb, '
            || '   mtl_categories_b      mcb '
            || '  WHERE mcsb.category_set_id  = mcst.category_set_id '
            || '  AND   mcst.language         = ''' || cv_ja || ''''
            || '  AND   mcsb.structure_id     = mcb.structure_id '
            || '  AND   mcst.category_set_name = ''' || gc_cat_set_item_class || '''' || ') xpoc2'
            || ',xxcmn_item_categories2_v   xic1'  -- opm�i�ڃJ�e�S������view(���i�敪)
            || ',xxcmn_item_categories2_v   xic2'  -- opm�i�ڃJ�e�S������view(�i�ڋ敪)
            || ',xxcmn_vendors2_v           xve1'  -- �d������view(���)
            || ',xxcmn_vendors2_v           xve2'  -- �d������view(����)
            || ',xxcmn_vendor_sites2_v      xves1' -- �d����T�C�g���view(���)
            || ',xxcmn_item_locations2_v    xil'   -- opm�ۊǏꏊ���view(�[����)
            || ',xxcmn_party_sites2_v       xps'   -- �p�[�e�B�T�C�g���view(�o��)
            || ',xxcmn_vendor_sites2_v      xves2' -- �d����T�C�g���view(�x��)
            || ',xxcmn_vendor_sites2_v      xves3' -- �d����T�C�g���view(�H��/�z����)
            || ',fnd_lookup_values          flv1'  -- �N�C�b�N�R�[�h(���o)
            || ',fnd_lookup_values          flv2'  -- �N�C�b�N�R�[�h(�d���`��)
            || ',fnd_lookup_values          flv3'  -- �N�C�b�N�R�[�h(�����敪)
            || ',fnd_lookup_values          flv4'  -- �N�C�b�N�R�[�h(�Y�n)
            || ',fnd_lookup_values          flv5'  -- �N�C�b�N�R�[�h(�^�C�v)
            || ',fnd_lookup_values          flv6'  -- �N�C�b�N�R�[�h(���K�敪)
            || ',fnd_lookup_values          flv7'  -- �N�C�b�N�R�[�h(���ۋ��敪)
            ;
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    lv_where := ' WHERE'
             || '     poh.org_id               = ' || gn_sales_class
             || ' AND poh.segment1             = xpoh.po_header_number'
             || ' AND poh.po_header_id         = pol.po_header_id'
             || ' AND pol.po_line_id           = polo.po_line_id'
             || ' AND poh.authorization_status = ''' || cv_poh_status  || ''''
             || ' AND poh.attribute1          >= ''' || cv_poh_make    || ''''
             || ' AND poh.attribute1           < ''' || cv_poh_cancel  || ''''
             || ' AND pol.cancel_flag         <> ''' || cv_pln_cancel_flag   || ''''
             || ' AND poh.attribute4          >= ''' || ir_param.delivery_date_from || ''''
-- 2009/03/30 v1.11 ADD START
             || ' AND poh.org_id               = FND_PROFILE.VALUE(''ORG_ID'') '
-- 2009/03/30 v1.11 ADD END
             ;
    -- �����ԍ������͂���Ă���ꍇ
    IF (ir_param.po_number IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.segment1      = ''' || ir_param.po_number || ''''
               ;
    END IF;
    -- �S�����������͂���Ă���ꍇ
    IF (ir_param.role_department IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute10      = ''' || ir_param.role_department || ''''
               ;
    END IF;
    -- �S���҂����͂���Ă���ꍇ
    IF (ir_param.role_people IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND xpoh.order_created_by_code      = ''' || ir_param.role_people || ''''
               ;
    END IF;
    -- �쐬����FROM�����͂���Ă���ꍇ
    IF (ir_param.create_date_from IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND xpoh.order_created_date      >= '
               || '     FND_DATE.STRING_TO_DATE(''' || ir_param.create_date_from || ''','''
                                                    || gc_char_dt_format  || ''')'
               ;
    END IF;
    -- �쐬����TO�����͂���Ă���ꍇ
    IF (ir_param.create_date_to IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND xpoh.order_created_date      <= '
               || '     FND_DATE.STRING_TO_DATE(''' || ir_param.create_date_to || ''','''
                                                    || gc_char_dt_format  || ''')'
               ;
    END IF;
    -- �[���悪���͂���Ă���ꍇ
    IF (ir_param.delivery_to IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute5      = ''' || ir_param.delivery_to || ''''
               ;
    END IF;
    -- �[�����s�n�����͂���Ă���ꍇ
    IF (ir_param.delivery_date_to IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute4      <= ''' || ir_param.delivery_date_to || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- ���b�g���i�ڂ̍i���ݏ���
    lv_where := lv_where
             || ' AND pol.item_id            = xim.inventory_item_id'
             || ' AND xim.item_id            = iclt.item_id'
             || ' AND DECODE(xim.lot_ctl,' || gv_lot_n_div   || ','''
                                           || gv_lot_default || ''''
                                           || ',pol.attribute1) = iclt.lot_no '
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN xim.start_date_active AND xim.end_date_active'
             ;
    ---------------------------------------------------------------------------------------------
    -- �i�ڃJ�e�S��(���i�敪)�̍i���ݏ���
    lv_where := lv_where
             || ' AND xim.item_id                          = xic1.item_id'
             || ' AND xic1.category_set_id                 = xpoc1.category_set_id'
             || ' AND xic1.category_id                     = xpoc1.category_id'
             ;
    -- ���i�敪�����͂���Ă���ꍇ
    IF (ir_param.product_type IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND xpoc1.category_code   = ''' || ir_param.product_type || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �i�ڃJ�e�S��(�i�ڋ敪)�̍i���ݏ���
    lv_where := lv_where
             || ' AND xim.item_id                          = xic2.item_id'
             || ' AND xic2.category_set_id                 = xpoc2.category_set_id'
             || ' AND xic2.category_id                     = xpoc2.category_id'
             ;
    -- �i�ڋ敪�����͂���Ă���ꍇ
    IF (ir_param.item_type IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND xpoc2.category_code   = ''' || ir_param.item_type || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �����̍i���ݏ���
    lv_where := lv_where
             || ' AND xve1.vendor_id       = xves1.vendor_id'
             || ' AND poh.vendor_id        = xve1.vendor_id'
             || ' AND poh.vendor_site_id   = xves1.vendor_site_id'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN xve1.start_date_active AND xve1.end_date_active'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN xves1.start_date_active AND xves1.end_date_active'
             ;
    -- ����悪���͂���Ă���ꍇ
    IF (ir_param.vendor_code IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND xve1.segment1   = ''' || ir_param.vendor_code || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �����҂̍i���ݏ���
    -- �����҂����͂���Ă��Ȃ��ꍇ
    IF (ir_param.mediation IS NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute3       = xve2.vendor_id(+)'
               || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
               || '     BETWEEN xve2.start_date_active(+) AND xve2.end_date_active(+)'
               ;
    ELSE
      -- �����҂����͂���Ă���ꍇ
      lv_where := lv_where
               || ' AND poh.attribute3       = xve2.vendor_id'
               || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
               || '     BETWEEN xve2.start_date_active AND xve2.end_date_active'
               || ' AND xve2.segment1   = ''' || ir_param.mediation || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �[����̍i���ݏ���
    lv_where := lv_where
             || ' AND poh.attribute5       = xil.segment1'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''') >= xil.date_from'
             || ' AND (  (xil.date_to IS NULL)'
             || '   OR ( (xil.date_to IS NOT NULL)'
             || '    AND (xil.date_to >= FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from
                                                  || ''',''' || gc_char_d_format  || '''))))'
             || ' AND xil.disable_date IS NULL'
             ;
    ---------------------------------------------------------------------------------------------
    -- �x��/�o�ׂ̍i���ݏ���
    lv_where := lv_where
             || ' AND poh.attribute7 = xps.party_site_number(+)'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN xps.start_date_active(+) AND xps.end_date_active(+)'
             || ' AND poh.attribute7 = xves2.vendor_site_code(+)'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN xves2.start_date_active(+) AND xves2.end_date_active(+)'
             ;
    ---------------------------------------------------------------------------------------------
    -- �H��/�z����̍i���ݏ���
    lv_where := lv_where
             || ' AND pol.attribute2 = xves3.vendor_site_code'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN xves3.start_date_active AND xves3.end_date_active'
             ;
    ---------------------------------------------------------------------------------------------
    -- �Z�L�����e�B�敪�̍i���ݏ���
    -- �u�����v�̏ꍇ
    IF (ir_param.security_type = gc_seqrt_class_vender) THEN
      lv_where := lv_where
               || ' AND (   ( poh.attribute3  = ''' || gn_user_vender_id || ''')'
               || '      OR ((poh.vendor_id   = ''' || gn_user_vender_id || ''')'
               ;
      -- ���O�C�����[�U�[�̎d����T�C�g�R�[�h���ݒ肳��Ă���ꍇ
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_where := lv_where
                 || '        AND  NOT EXISTS(SELECT po_line_id '
                 ||                        ' FROM   po_lines_all pol '
                 ||                        ' WHERE  pol.po_header_id = poh.po_header_id '
                 ||                        ' AND  NVL(pol.attribute2,''*'') '
                 ||                        ' <> ''' || gv_user_vender_site || ''')'
                 ;
      END IF;
      lv_where := lv_where
               || '))'
               ;
    END IF;
    -- �u�O���q�Ɂv�̏ꍇ
    IF (ir_param.security_type = gc_seqrt_class_outside) THEN
      IF ( gv_subinv_code.COUNT = 1 ) THEN
        lv_where := lv_where
          || ' AND xil.segment1 = ''' || gv_subinv_code(1) || '''';
      ELSIF ( gv_subinv_code.COUNT > 1 ) THEN
        lv_where := lv_where
          || ' AND xil.segment1 IN(' || fnc_get_in_statement(gv_subinv_code) || ')';
      END IF;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �N�C�b�N�R�[�h�̍i���ݏ���
    -- <���o��>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv1.start_date_active(+) '
             || '       AND      NVL(flv1.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                     || ir_param.delivery_date_from || ''','''
                                                     || gc_char_d_format  || '''))'
             || ' AND   flv1.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv1.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv1.lookup_type(+)        = ''' || cv_lookup_type_drop_ship || ''''
             || ' AND   flv1.lookup_code(+)        = poh.attribute6'
             ;
    -- <�d���`��>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv2.start_date_active(+) '
             || '       AND      NVL(flv2.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                      || ir_param.delivery_date_from || ''','''
                                                      || gc_char_d_format  || '''))'
             || ' AND   flv2.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv2.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv2.lookup_type(+)        = ''' || cv_lookup_type_l05 || ''''
             || ' AND   flv2.lookup_code(+)        = iclt.attribute9'
             ;
    -- <�����敪>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv3.start_date_active(+) '
             || '       AND      NVL(flv3.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                      || ir_param.delivery_date_from || ''','''
                                                      || gc_char_d_format  || '''))'
             || ' AND   flv3.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv3.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv3.lookup_type(+)        = ''' || cv_lookup_type_l06 || ''''
             || ' AND   flv3.lookup_code(+)        = iclt.attribute10'
             ;
    -- <�Y�n>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv4.start_date_active(+) '
             || '       AND      NVL(flv4.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                      || ir_param.delivery_date_from || ''','''
                                                      || gc_char_d_format  || '''))'
             || ' AND   flv4.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv4.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv4.lookup_type(+)        = ''' || cv_lookup_type_l07 || ''''
             || ' AND   flv4.lookup_code(+)        = iclt.attribute12'
             ;
    -- <�^�C�v>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv5.start_date_active(+) '
             || '       AND      NVL(flv5.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                      || ir_param.delivery_date_from || ''','''
                                                      || gc_char_d_format  || '''))'
             || ' AND   flv5.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv5.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv5.lookup_type(+)        = ''' || cv_lookup_type_l08 || ''''
             || ' AND   flv5.lookup_code(+)        = iclt.attribute13'
             ;
    -- <���K�敪>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv6.start_date_active(+) '
             || '       AND      NVL(flv6.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                      || ir_param.delivery_date_from || ''','''
                                                      || gc_char_d_format  || '''))'
             || ' AND   flv6.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv6.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv6.lookup_type(+)        = ''' || cv_lookup_type_kousen_type || ''''
             || ' AND   flv6.lookup_code(+)        = polo.attribute3'
             ;
    -- <���ۋ��敪>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv7.start_date_active(+) '
             || '       AND      NVL(flv7.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                      || ir_param.delivery_date_from || ''','''
                                                      || gc_char_d_format  || '''))'
             || ' AND   flv7.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv7.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv7.lookup_type(+)        = ''' || cv_lookup_type_gukakin_type || ''''
             || ' AND   flv7.lookup_code(+)        = polo.attribute6'
             ;
--
    -- ----------------------------------------------------
    -- �n�q�c�d�q  �a�x�吶��
    -- ----------------------------------------------------
    lv_order_by := ' ORDER BY'
                || ' poh.segment1'      -- �����ԍ�
                || ',xve1.segment1'     -- �����
                || ',xve2.segment1'     -- ������
                || ',poh.attribute4'    -- �[����
                || ',xil.segment1'      -- �[����
                || ',pol.line_num'      -- ���הԍ�
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
    -- �I�[�v��
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
   * Description      : XML�f�[�^�o��
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
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
    lc_break_init     VARCHAR2(100) := '*' ;            -- �����l
    lc_break_null     VARCHAR2(100) := '**' ;           -- �m�t�k�k����
    lc_max_cnt        NUMBER        := 6 ;              -- ����MAX�s��
    lc_report_name1   VARCHAR2(10)  := '������' ;       -- ���[����
    lc_report_name2   VARCHAR2(20)  := '�����w����' ;   -- ���[����
    lc_price_text1    VARCHAR2(50)  := '�i����[�����x���ꍇ�͕K�����O�ɂ��A���������B�j' ;
    lc_price_text2    VARCHAR2(100) := '�{�������̒P���́A����œ������̒P���ł��B�x������' ||
                                       '�ɂ́A���s�@��ŗ��̏���œ������Z���Ďx�����܂��B' ;
    lc_zero           NUMBER        := 0 ;
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_po_number            VARCHAR2(100) DEFAULT lc_break_init ;  -- �����ԍ�
    ln_cnt                  NUMBER DEFAULT 0;                      -- ���׌���
    ln_ctotal               NUMBER DEFAULT 0;                      -- ���v��
    ln_mtotal               NUMBER DEFAULT 0;                      -- ���v���z
    ld_appl_date            DATE DEFAULT NULL;
    -- �������擾�v���V�[�W���ɂĎg�p
    lv_postal_code          VARCHAR2( 10) DEFAULT NULL ; -- �X�֔ԍ�
    lv_address              VARCHAR2(100) DEFAULT NULL ; -- �Z��
    lv_tel_num              VARCHAR2( 30) DEFAULT NULL ; -- �d�b�ԍ�
    lv_fax_num              VARCHAR2( 30) DEFAULT NULL ; -- FAX�ԍ�
    lv_dept_formal_name     VARCHAR2(100) DEFAULT NULL ; -- ����������
    lv_term_str             VARCHAR2(100) DEFAULT NULL ; -- �x����������
--
    ln_purchase_amount      NUMBER;                      -- �d�����z�v�Z�p
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;             -- �擾���R�[�h�Ȃ�
--
  BEGIN
--
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
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
    -- �f�[�^�k�f�f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- ���[����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    IF ( ir_param.site_use = gv_use_site_po ) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := lc_report_name1; -- ������
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := lc_report_name2; -- �����w����
    END IF;
    -- �P������ŕ����P
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_price_tax_text1' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(lc_price_text1,
                                                            ir_param.site_use) ;
    -- �P������ŕ����Q
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_price_tax_text2' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(lc_price_text2,
                                                            ir_param.site_use) ;
    -- -----------------------------------------------------
    -- �����ԍ��k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_po_num' ;
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
      IF ( NVL( gt_main_data(i).po_number, lc_break_null ) <> lv_po_number ) THEN
--
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_po_number <> lc_break_init ) THEN
--
          IF ((ln_cnt <= lc_max_cnt ) OR ( (ln_cnt > lc_max_cnt)
            AND (ln_cnt MOD lc_max_cnt <= lc_max_cnt))) THEN
--
            IF ((ln_cnt MOD lc_max_cnt) <> lc_zero) THEN
--
              -- ��s�̍쐬
              <<blank_loop>>
              FOR i IN 1 .. lc_max_cnt - ( ln_cnt MOD lc_max_cnt ) LOOP
--
                -- -----------------------------------------------------
                -- ���b�gL�f�J�n�^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_lot' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
                -- -----------------------------------------------------
                -- ���b�g�f�J�n�^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := 'g_lot' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
                -- -----------------------------------------------------
                -- ���b�g�f�f�[�^�^�O�o��
                -- -----------------------------------------------------
                -- �i�ڃR�[�h
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
                gt_xml_data_table(gl_xml_idx).tag_value := NULL;
                -- -----------------------------------------------------
                -- ���b�g�f�I���^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lot' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
                -- -----------------------------------------------------
                -- ���b�gL�f�I���^�O�o��
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
              END LOOP blank_loop;
--
            END IF;
--
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
          -- ���v��
          IF (ln_ctotal <> 0) THEN
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'cnt_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_ctotal;
          END IF;
          -- ���v���z
          IF (ln_mtotal <> 0) THEN
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'money_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(TO_CHAR(ln_mtotal),
                                                                    ir_param.site_use);
          END IF;
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
          -- �����A���v�O�N���A
          ln_cnt   := 0;
          ln_ctotal := 0;
          ln_mtotal := 0;
--
          ------------------------------
          -- �����ԍ��f�I���^�O
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_po_num' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- �����ԍ��f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_po_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- �����ԍ��f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        ld_appl_date := FND_DATE.STRING_TO_DATE(ir_param.delivery_date_from,gc_char_d_format);
        -- �������擾�v���V�[�W�����擾
        xxcmn_common_pkg.get_dept_info(
           iv_dept_cd          => gt_main_data(i).dept_code -- �����R�[�h(���Ə�CD)
          ,id_appl_date        => ld_appl_date              -- ���
          ,ov_postal_code      => lv_postal_code            -- �X�֔ԍ�
          ,ov_address          => lv_address                -- �Z��
          ,ov_tel_num          => lv_tel_num                -- �d�b�ԍ�
          ,ov_fax_num          => lv_fax_num                -- FAX�ԍ�
          ,ov_dept_formal_name => lv_dept_formal_name       -- ����������
          ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         ) ;
--
        -- ���t���Z��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'address' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(lv_address,1,30) ;
        -- ���t���d�b�ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'telephone_number_1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_tel_num ;
        -- ���t��FAX�ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'telephone_number_2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_fax_num ;
        -- ���t��������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dept' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(lv_dept_formal_name,1,30) ;
        -- �����ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'po_number' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).po_number ;
        -- �����F�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'business_partner_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).business_partner_num ;
        -- �����F������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'business_partner_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).business_partner_name,
                                                           1,60) ;
        -- �����ҁF�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'mediator_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).mediator_num ;
        -- �����ҁF������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'mediator_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).mediator_name,
                                                           1,60) ;
        -- �[����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).delivery_date ;
        -- �[����F�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_to_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).delivery_to_num ;
        -- �[����F������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_to_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).delivery_to_name,
                                                           1,20) ;
        -- �x��/�o�ׁF���o��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_ship_caption' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        IF ( gt_main_data(i).direct_type <> gv_direct_type_u ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).direct_name ;
        ELSIF (( gt_main_data(i).direct_type = gv_direct_type_u )
           OR  ( gt_main_data(i).direct_type = NULL )) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := '' ;
        END IF ;
        -- �x��/�o�ׁF�R�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_ship_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).drop_code ;
        -- �x��/�o�ׁF������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_ship_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).drop_name,
                                                           1,60) ;
        -- �x��/�o�ׁF�X�֔ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_ship_postno' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).drop_zip ;
        -- �x��/�o�ׁF�Z���P
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_ship_address1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).drop_address1,
                                                           1,30) ;
        -- �x��/�o�ׁF�Z���Q
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_ship_address2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).drop_address2,
                                                           1,30) ;
-- add start ver1.10
        -- �x��/�o�ׁF�d�b�ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'phone_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).phone,
                                                           1,30) ;
-- add end ver1.10
--
        -- �x�����������擾�֐��ɂ��
        lv_term_str := xxcmn_common_pkg.get_term_of_payment(
                         in_vendor_id        => gt_main_data(i).vendor_id -- �d����h�c
                        ,id_appl_date        => ld_appl_date              -- ���
                       ) ;
--
        -- �x������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'term' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(lv_term_str,
                                                                ir_param.site_use) ;
        -- �����w�b�_�F�E�v
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'description' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).description,
                                                           1,60) ;
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_po_number  := NVL( gt_main_data(i).po_number, lc_break_null )  ;
--
      END IF ;
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
--
      -- -----------------------------------------------------
      -- ���b�g�k�f�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���b�g�f�J�n�^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���ׂf�f�[�^�^�O�o��
      -- -----------------------------------------------------
      -- �i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_code ;
      -- �t�уR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'incident' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).incident ;
      -- �i�ږ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).item_name,
                                                         1,40) ;
      -- �݌ɓ���
      IF (gt_main_data(i).inventory_quantity IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'inventory_quantity' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).inventory_quantity ;
      END IF;
      -- ����
      IF (gt_main_data(i).quantity IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quantity' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).quantity ;
      END IF;
      -- �P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_of_measure' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).unit_of_measure ;
      -- �P��
      IF (gt_main_data(i).unit_price IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).unit_price,
                                                                ir_param.site_use) ;
      END IF;
      -- �d�����z
-- mod start 1.9
--      IF ( (gt_main_data(i).product_type = gv_goods_classe_drink)         -- �h�����N ����
--        AND (gt_main_data(i).item_type = gv_item_class_products)          -- ���i ����
--        AND (gt_main_data(i).base_uom <> gt_main_data(i).unit_of_measure) -- ���o�Ɋ��Z�P�ʂ���
--        ) THEN
          --�m���ʁ~�݌ɓ����~�P���n
--          ln_purchase_amount := ROUND((NVL(gt_main_data(i).quantity , 0) *
--                                  TO_NUMBER(NVL(gt_main_data(i).inventory_quantity , 0))) *
--                                  NVL(gt_main_data(i).unit_price , 0));
          -- �m���ʁ~�݌ɓ����~�P���n
--      ELSE
--          ln_purchase_amount := ROUND(NVL(gt_main_data(i).quantity , 0) *
--                                  NVL(gt_main_data(i).unit_price , 0));
--      END IF;
      -- �m��������z-�a����K���z-���ۋ��z�n
      ln_purchase_amount := TRUNC(gt_main_data(i).amount - 
                              gt_main_data(i).commission_amount - 
                              gt_main_data(i).levy_amount);
-- mod end 1.9
      IF (ln_purchase_amount <> 0) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'purchase_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(ln_purchase_amount,
                                                                ir_param.site_use) ;
      END IF;
      -- ���b�g�m��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_number' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).lot_number ;
      -- ������
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'wip_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).wip_date ;
      -- �ܖ�����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'best_before_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).best_before_date ;
      -- �ŗL�L��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'peculiar_mark' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).peculiar_mark ;
      -- �H��R�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'factory_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).factory_code ;
      -- �H�ꖼ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'factory_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).factory_name,
                                                         1,20) ;
      -- ������
      IF (gt_main_data(i).division IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'division' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).division,
                                                                ir_param.site_use) ;
      END IF;
      -- ������P��
      IF (gt_main_data(i).unit_price_rate IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_price_rate' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).unit_price_rate,
                                                                ir_param.site_use) ;
      END IF;
      -- ��������z
      IF (gt_main_data(i).amount IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(NVL(gt_main_data(i).amount , 0),
                                                                ir_param.site_use) ;
      END IF;
      -- �d���`��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'vender_form' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).vender_form,
                                                              ir_param.site_use) ;
      -- �N�x
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).year,
                                                              ir_param.site_use) ;
      -- �����敪
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tea_time_division' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).tea_time_division,
                                                              ir_param.site_use) ;
      -- �Y�n
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'Place_of_production' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).Place_of_production,
                                                              ir_param.site_use) ;
      -- �^�C�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'type' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_type ;
      -- �����N
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lank' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).lank1 || '-' ||
                                                              gt_main_data(i).lank2 || '-' ||
                                                              gt_main_data(i).lank3,
                                                              ir_param.site_use) ;
      -- ���K�敪
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'commission_division' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).commission_division,
                                                              ir_param.site_use) ;
      -- ���K
      IF (gt_main_data(i).commission_unit_price_rate IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'commission_unit_price_rate' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(
                                                   gt_main_data(i).commission_unit_price_rate,
                                                   ir_param.site_use) ;
      END IF;
      -- �a����K���z
      IF (gt_main_data(i).commission_amount IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'commission_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(
                                                        NVL(gt_main_data(i).commission_amount,0),
                                                        ir_param.site_use) ;
      END IF;
      -- ���ׁF�E�v
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'description2' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).description2,
                                                         1,40) ;
      -- ���ۋ��敪
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'levy_amount_division' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).levy_amount_division,
                                                              ir_param.site_use) ;
      -- ���ۋ�
      IF (gt_main_data(i).levy_unit_price_rate IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'levy_unit_price_rate' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(
                                         gt_main_data(i).levy_unit_price_rate,ir_param.site_use) ;
      END IF;
      -- ���ۋ��z
      IF (gt_main_data(i).levy_amount IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'levy_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(NVL(gt_main_data(i).levy_amount,0),
                                                                ir_param.site_use) ;
      END IF;
      -- -----------------------------------------------------
      -- ���b�g�f�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ���b�g�k�f�I���^�O�o��
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ���v��(�W�v)
      ln_ctotal := ln_ctotal + NVL(gt_main_data(i).quantity,0) ;
      -- ���v���z(�W�v)
      ln_mtotal := ln_mtotal + NVL(gt_main_data(i).amount,0) ;
      -- ���׌����J�E���g
      ln_cnt := ln_cnt + 1;
--
    END LOOP main_data_loop ;
--
    IF ((ln_cnt <= lc_max_cnt ) OR ( (ln_cnt > lc_max_cnt)
         AND (ln_cnt MOD lc_max_cnt <= lc_max_cnt))) THEN
--
      IF ((ln_cnt MOD lc_max_cnt) <> lc_zero) THEN
--
        -- ��s�̍쐬
        <<blank_loop>>
        FOR i IN 1 .. lc_max_cnt - ( ln_cnt MOD lc_max_cnt ) LOOP
--
          -- -----------------------------------------------------
          -- ���b�gL�f�J�n�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- ���b�g�f�J�n�^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- ���b�g�f�f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- �i�ڃR�[�h
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- -----------------------------------------------------
          -- ���b�g�f�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- ���b�gL�f�I���^�O�o��
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END LOOP blank_loop;
--
      END IF;
--
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
    -- ���v��
    IF (ln_ctotal <> 0) THEN
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'cnt_total' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_ctotal;
    END IF;
    -- ���v���z
    IF (ln_mtotal <> 0) THEN
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'money_total' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(TO_CHAR(ln_mtotal),
                                                              ir_param.site_use);
    END IF;
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
    -- �����ԍ��f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_po_num' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �����ԍ��k�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_po_num' ;
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
  PROCEDURE submain(
      iv_site_use           IN     VARCHAR2         -- 01 : �g�p�ړI
     ,iv_po_number          IN     VARCHAR2         -- 02 : �����ԍ�
     ,iv_role_department    IN     VARCHAR2         -- 03 : �S������
     ,iv_role_people        IN     VARCHAR2         -- 04 : �S����
     ,iv_create_date_from   IN     VARCHAR2         -- 05 : �쐬��FROM
     ,iv_create_date_to     IN     VARCHAR2         -- 06 : �쐬��TO
     ,iv_vendor_code        IN     VARCHAR2         -- 07 : �����
     ,iv_mediation          IN     VARCHAR2         -- 08 : ������
     ,iv_delivery_date_from IN     VARCHAR2         -- 09 : �[����FROM
     ,iv_delivery_date_to   IN     VARCHAR2         -- 10 : �[����TO
     ,iv_delivery_to        IN     VARCHAR2         -- 11 : �[����
     ,iv_product_type       IN     VARCHAR2         -- 12 : ���i�敪
     ,iv_item_type          IN     VARCHAR2         -- 13 : �i�ڋ敪
     ,iv_security_type      IN     VARCHAR2         -- 14 : �Z�L�����e�B�敪
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
    -- *** ���[�J���ϐ� ***
    lr_param_rec            rec_param_data ;          -- �p�����[�^��n���p
--
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER := 0 ;
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
    gv_report_id              := 'XXPO360001T' ;      -- ���[ID
    gd_exec_date              := SYSDATE ;            -- ���{��
    -- �p�����[�^�i�[
    lr_param_rec.site_use           := iv_site_use;           -- �g�p�ړI
    lr_param_rec.po_number          := iv_po_number;          -- �����ԍ�
    lr_param_rec.role_department    := iv_role_department;    -- �S������
    lr_param_rec.role_people        := iv_role_people;        -- �S����
    lr_param_rec.create_date_from   := iv_create_date_from;   -- �쐬��FROM
    lr_param_rec.create_date_to     := iv_create_date_to;     -- �쐬��TO
    lr_param_rec.vendor_code        := iv_vendor_code;        -- �����
    lr_param_rec.mediation          := iv_mediation;          -- ������
    lr_param_rec.delivery_date_from := TO_CHAR(FND_DATE.STRING_TO_DATE(  -- �[����FROM
                                       iv_delivery_date_from,gc_char_dt_format) ,gc_char_d_format);
    lr_param_rec.delivery_date_to   := TO_CHAR(FND_DATE.STRING_TO_DATE(  -- �[����TO
                                       iv_delivery_date_to,gc_char_dt_format) ,gc_char_d_format);
    lr_param_rec.delivery_to        := iv_delivery_to;        -- �[����
    lr_param_rec.product_type       := iv_product_type;       -- ���i�敪
    lr_param_rec.item_type          := iv_item_type;          -- �i�ڋ敪
    lr_param_rec.security_type      := iv_security_type;      -- �Z�L�����e�B�敪
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize(
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
    prc_create_xml_data(
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
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_po_num>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_po_num>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_po_num>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_po_num>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
      -- �O�����b�Z�[�W���O�o��
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-10026'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
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
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_site_use           IN     VARCHAR2         -- 01 : �g�p�ړI
     ,iv_po_number          IN     VARCHAR2         -- 02 : �����ԍ�
     ,iv_role_department    IN     VARCHAR2         -- 03 : �S������
     ,iv_role_people        IN     VARCHAR2         -- 04 : �S����
     ,iv_create_date_from   IN     VARCHAR2         -- 05 : �쐬��FROM
     ,iv_create_date_to     IN     VARCHAR2         -- 06 : �쐬��TO
     ,iv_vendor_code        IN     VARCHAR2         -- 07 : �����
     ,iv_mediation          IN     VARCHAR2         -- 08 : ������
     ,iv_delivery_date_from IN     VARCHAR2         -- 09 : �[����FROM
     ,iv_delivery_date_to   IN     VARCHAR2         -- 10 : �[����TO
     ,iv_delivery_to        IN     VARCHAR2         -- 11 : �[����
     ,iv_product_type       IN     VARCHAR2         -- 12 : ���i�敪
     ,iv_item_type          IN     VARCHAR2         -- 13 : �i�ڋ敪
     ,iv_security_type      IN     VARCHAR2         -- 14 : �Z�L�����e�B�敪
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
        iv_site_use           => iv_site_use            -- 01 : �g�p�ړI
       ,iv_po_number          => iv_po_number           -- 02 : �����ԍ�
       ,iv_role_department    => iv_role_department     -- 03 : �S������
       ,iv_role_people        => iv_role_people         -- 04 : �S����
       ,iv_create_date_from   => iv_create_date_from    -- 05 : �쐬��FROM
       ,iv_create_date_to     => iv_create_date_to      -- 06 : �쐬��TO
       ,iv_vendor_code        => iv_vendor_code         -- 07 : �����
       ,iv_mediation          => iv_mediation           -- 08 : ������
       ,iv_delivery_date_from => iv_delivery_date_from  -- 09 : �[����FROM
       ,iv_delivery_date_to   => iv_delivery_date_to    -- 10 : �[����TO
       ,iv_delivery_to        => iv_delivery_to         -- 11 : �[����
       ,iv_product_type       => iv_product_type        -- 12 : ���i�敪
       ,iv_item_type          => iv_item_type           -- 13 : �i�ڋ敪
       ,iv_security_type      => iv_security_type       -- 14 : �Z�L�����e�B�敪
       ,ov_errbuf             => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
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
END xxpo360001c ;
/