CREATE OR REPLACE PACKAGE BODY xxcmn820004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn820004c(body)
 * Description      : �V�����z�v�Z�\�쐬
 * MD.050/070       : �W�������}�X�^Draft1C (T_MD050_BPO_820)
 *                    �V�����z�v�Z�\�쐬    (T_MD070_BPO_82D)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  convert_into_xml       XML�f�[�^�ϊ�
 *  output_xml             XML�f�[�^�o��
 *  prc_get_record         ���[�o�͏��擾
 *  prc_get_header_info    �w�b�_���擾
 *  prc_create_xml         XML�f�[�^�쐬
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/18    1.0   Kazuo Kumamoto   �V�K�쐬
 *  2008/05/21    1.1   Masayuki Ikeda   �����e�X�g��Q�Ή�
*
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
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
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
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name               CONSTANT VARCHAR2(12)  := 'xxcmn820004c'; -- �p�b�P�[�W��
--
  gc_application_po         CONSTANT VARCHAR2(4)   := 'XXPO' ;           -- �A�v���P�[�V����(XXPO)
  gc_application_cmn        CONSTANT VARCHAR2(5)   := 'XXCMN' ;          -- �A�v���P�[�V����(XXCMN)
  gc_xxpo_00036             CONSTANT VARCHAR2(14)  := 'APP-XXPO-00036' ; -- �S�����������擾
  gc_xxpo_00026             CONSTANT VARCHAR2(14)  := 'APP-XXPO-00026' ; -- �S���Җ����擾
  gc_xxpo_00033             CONSTANT VARCHAR2(14)  := 'APP-XXPO-00033' ; -- �f�[�^���擾
  gc_xxcmn_10122            CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10122' ;-- ����0��
  gv_msg_kbn                CONSTANT VARCHAR2(5)   := 'XXCMN' ;          -- �p�b�P�[�W��
  gv_msg_num_10013          CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10013' ;-- �P�[�X���萔0�G���[
  gv_ofcase_name            CONSTANT VARCHAR2(14)  := '�̃P�[�X���萔' ;
  gv_mst_name               CONSTANT VARCHAR2(100) := '�i�ڃJ�e�S���}�X�^' ;
  gv_msg_num_10003          CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10003' ;-- �O�N�x�̐���擾�G���[
  gv_prev_gene_err_name     CONSTANT VARCHAR2(36)  := '�t�H�[�L���X�g(�O�N�x�̍ŐV����擾)';
--
  gv_report_id              CONSTANT VARCHAR2(12)  := 'XXCMN820004T' ; -- �v���O���������[�o�͗p
  gc_description_prov       CONSTANT VARCHAR2(8) := '���i�敪';
  gc_description_crowd      CONSTANT VARCHAR2(8) := '�Q�R�[�h';
  gc_lang                   CONSTANT VARCHAR2(2) := 'JA';
  gc_source_lang            CONSTANT VARCHAR2(2) := 'JA';
--
  gc_item_type              CONSTANT VARCHAR2(22) := 'XXPO_EXPENSE_ITEM_TYPE';
  gc_row_material_cost      CONSTANT VARCHAR2(10) := '1';--'������';
  gc_remake_cost            CONSTANT VARCHAR2(10) := '2';--'�Đ���';
  gc_material_cost          CONSTANT VARCHAR2(10) := '3';--'���ޔ�';
  gc_wrapping_cost          CONSTANT VARCHAR2(10) := '4';--'���';
  gc_outside_cost           CONSTANT VARCHAR2(10) := '5';--'�O���Ǘ���';
  gc_store_cost             CONSTANT VARCHAR2(10) := '6';--'�ۊǔ�';
  gc_other_cost             CONSTANT VARCHAR2(10) := '7';--'���̑��o��';
--
  gc_fc_type                CONSTANT VARCHAR2(13) := 'XXINV_FC_TYPE';
  gc_fc_description         CONSTANT VARCHAR2(8) := '�̔��v��';
--
  gc_price_type             CONSTANT VARCHAR2(1) := '2'; --1:�d��  2:�W��
  gc_output_unit_code_quant CONSTANT VARCHAR2(1) := '0'; --0:�{��  1:�P�[�X
  gc_output_unit_code_case  CONSTANT VARCHAR2(1) := '1'; --0:�{��  1:�P�[�X
  gc_output_unit_name_quant CONSTANT VARCHAR2(4) := '�{��';
  gc_output_unit_name_case  CONSTANT VARCHAR2(6) := '�P�[�X';
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
      output_unit       VARCHAR2(6)     -- �o�͒P��
     ,fiscal_year       VARCHAR2(4)     -- �Ώ۔N�x
     ,generation        VARCHAR2(2)     -- ����
     ,prod_div          VARCHAR2(1)     -- ���i�敪
     ,crowd_code_01     VARCHAR2(4)     -- �Q�R�[�h�P
     ,crowd_code_02     VARCHAR2(4)     -- �Q�R�[�h�Q
     ,crowd_code_03     VARCHAR2(4)     -- �Q�R�[�h�R
     ,crowd_code_04     VARCHAR2(4)     -- �Q�R�[�h�R
     ,crowd_code_05     VARCHAR2(4)     -- �Q�R�[�h�R
    ) ;
--
  -- �擾���R�[�h�i�[�p���R�[�h�ϐ�
  TYPE rec_data IS RECORD
    (
      prod_div                         mtl_categories_b.segment1%TYPE
     ,prod_div_name                    mtl_categories_tl.description%TYPE
     ,crowd_code                       mtl_categories_b.segment1%TYPE
     ,item_code                        xxpo_price_headers.item_code%TYPE
     ,item_name                        xxcmn_item_mst_b.item_name%TYPE
     ,in_case                          ic_item_mst_b.attribute11%TYPE
     ,forecast_quantity_new            mrp_forecast_dates.original_forecast_quantity%TYPE
     ,cost_price_new                   xxpo_price_lines.unit_price%TYPE
     ,row_material_cost_new            xxpo_price_lines.unit_price%TYPE
     ,remake_cost_new                  xxpo_price_lines.unit_price%TYPE
     ,material_cost_new                xxpo_price_lines.unit_price%TYPE
     ,wrapping_cost_new                xxpo_price_lines.unit_price%TYPE
     ,outside_cost_new                 xxpo_price_lines.unit_price%TYPE
     ,store_cost_new                   xxpo_price_lines.unit_price%TYPE
     ,other_cost_new                   xxpo_price_lines.unit_price%TYPE
     ,cost_price_old                   xxpo_price_lines.unit_price%TYPE
     ,row_material_cost_old            xxpo_price_lines.unit_price%TYPE
     ,remake_cost_old                  xxpo_price_lines.unit_price%TYPE
     ,material_cost_old                xxpo_price_lines.unit_price%TYPE
     ,wrapping_cost_old                xxpo_price_lines.unit_price%TYPE
     ,outside_cost_old                 xxpo_price_lines.unit_price%TYPE
     ,store_cost_old                   xxpo_price_lines.unit_price%TYPE
     ,other_cost_old                   xxpo_price_lines.unit_price%TYPE
    );
  TYPE tab_data IS TABLE OF rec_data INDEX BY BINARY_INTEGER ;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_exec_date              DATE ;               -- ���{��
  gv_department_code        VARCHAR2(10) ;       -- �S������
  gv_department_name        VARCHAR2(14) ;       -- �S����
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : XML�f�[�^�ϊ�
   ***********************************************************************************/
  FUNCTION convert_into_xml(
    iv_name  IN VARCHAR2,
    iv_value IN VARCHAR2,
    ic_type  IN CHAR
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_convert_data VARCHAR2(2000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
  END convert_into_xml;
--
  /**********************************************************************************
   * Procedure Name   : output_xml
   * Description      : XML�f�[�^�o�͏����v���V�[�W��
   ***********************************************************************************/
  PROCEDURE output_xml(
    iox_xml_data         IN OUT    NOCOPY XML_DATA, -- XML�f�[�^
    ov_errbuf            OUT       VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT       VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT       VARCHAR2)        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_xml' ;  --  �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_xml_string  VARCHAR2(32000) ;
--
  BEGIN
--
    -- XML�w�b�_�o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<?xml version="1.0" encoding="shift_jis" ?>') ;
--
    -- XML�f�[�^���o��
    <<xml_loop>>
    FOR i IN 1 .. iox_xml_data.COUNT LOOP
      lv_xml_string := convert_into_xml(
                         iox_xml_data(i).tag_name
                        ,iox_xml_data(i).tag_value
                        ,iox_xml_data(i).tag_type) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
    END LOOP xml_loop ;
--
    -- XML�f�[�^(Temp)�폜
    iox_xml_data.DELETE ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
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
--
  END output_xml ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_record
   * Description      : ���[�o�͏��擾
   ***********************************************************************************/
  PROCEDURE prc_get_record
    (
      ir_param_rec     IN  rec_param_data    --
     ,ot_data_rec      OUT tab_data          -- 
     ,ov_errbuf        OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_record'; -- �v���O������
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
    lv_prev_year       mrp_forecast_designators.attribute6%TYPE;
    lv_prev_gene       mrp_forecast_designators.attribute5%TYPE;
--
    data_check_expt    EXCEPTION ;             -- �f�[�^�`�F�b�N�G�N�Z�v�V����
--
    CURSOR cur_main_data
      (
        civ_current_year VARCHAR2
       ,civ_current_gene VARCHAR2
       ,civ_prev_year VARCHAR2
       ,civ_prev_gene VARCHAR2
       ,civ_prod_div VARCHAR2
       ,civ_crowd_code_01 VARCHAR2
       ,civ_crowd_code_02 VARCHAR2
       ,civ_crowd_code_03 VARCHAR2
       ,civ_crowd_code_04 VARCHAR2
       ,civ_crowd_code_05 VARCHAR2
      )
    IS
      SELECT
        m.prod_div                            AS prod_div --���i�敪
       ,m.prod_div_name                       AS prod_div_name --���i�敪��
       ,m.crowd_code                          AS crowd_code --�Q�R�[�h
       ,np.item_code                          AS item_code --�i�ڃR�[�h
       ,ximb.item_name                        AS item_name --�i�ږ�
       ,NVL(iimb.attribute11,'0')             AS in_case --�P�[�X���萔
       ,np.forecast_quantity_new              AS forecast_quantity_new --����
       ,np.cost_price_new                     AS cost_price_new --�V.�W������
       ,np.row_material_cost_new              AS row_material_cost_new --�V.������
       ,np.remake_cost_new                    AS remake_cost_new --�V.�Đ���
       ,np.material_cost_new                  AS material_cost_new --�V.���ޔ�
       ,np.wrapping_cost_new                  AS wrapping_cost_new --�V.���
       ,np.outside_cost_new                   AS outside_cost_new --�V.�O���Ǘ���
       ,np.store_cost_new                     AS store_cost_new --�V.�ۊǔ�
       ,np.other_cost_new                     AS other_cost_new --�V.���̑��o��
       ,NVL(op.cost_price_old,0)              AS cost_price_old --��.�W������
       ,NVL(op.row_material_cost_old,0)       AS row_material_cost_old --��.������
       ,NVL(op.remake_cost_old,0)             AS remake_cost_old --��.�Đ���
       ,NVL(op.material_cost_old,0)           AS material_cost_old --��.���ޔ�
       ,NVL(op.wrapping_cost_old,0)           AS wrapping_cost_old --��.���
       ,NVL(op.outside_cost_old,0)            AS outside_cost_old --��.�O���Ǘ���
       ,NVL(op.store_cost_old,0)              AS store_cost_old --��.�ۊǔ�
       ,NVL(op.other_cost_old,0)              AS other_cost_old --��.���̑��o��
      FROM (
        SELECT
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          mfdate.original_forecast_quantity   AS forecast_quantity_new
--         ,mfdate.forecast_date                AS forecast_date
          SUM( mfdate.original_forecast_quantity) AS forecast_quantity_new
         ,MIN(mfdate.forecast_date)               AS forecast_date
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
         ,xph.item_id                         AS item_id
         ,xph.item_code                       AS item_code
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--         ,SUM(xpl.quantity * xpl.unit_price)  AS cost_price_new
         ,SUM(mfdate.original_forecast_quantity * xpl.unit_price)  AS cost_price_new
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
         ,SUM(CASE WHEN flv_item.attribute2 = gc_row_material_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS row_material_cost_new
         ,SUM(CASE WHEN flv_item.attribute2 = gc_remake_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS remake_cost_new
         ,SUM(CASE WHEN flv_item.attribute2 = gc_material_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS material_cost_new
         ,SUM(CASE WHEN flv_item.attribute2 = gc_wrapping_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS wrapping_cost_new
         ,SUM(CASE WHEN flv_item.attribute2 = gc_outside_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS outside_cost_new
         ,SUM(CASE WHEN flv_item.attribute2 = gc_store_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS store_cost_new
         ,SUM(CASE WHEN flv_item.attribute2 = gc_other_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS other_cost_new
        FROM
          mrp_forecast_designators              mfdesi    --�t�H�[�L���X�g��
         ,xxcmn_lookup_values2_v                flv_fc    --�N�C�b�N�R�[�h
         ,mrp_forecast_dates                    mfdate    --�t�H�[�L���X�g���t
         ,mtl_system_items_b                    msib      --�i�ڃ}�X�^
         ,xxpo_price_headers                    xph       --�d���E�W���P���w�b�_
         ,xxpo_price_lines                      xpl       --�d���E�W���P������
         ,xxcmn_lookup_values2_v                flv_item  --�N�C�b�N�R�[�h
        WHERE flv_fc.lookup_type = gc_fc_type
        AND flv_fc.description = gc_fc_description
        AND mfdesi.attribute1 = flv_fc.lookup_code
        AND mfdate.forecast_date
          BETWEEN flv_fc.start_date_active AND NVL(flv_fc.end_date_active,mfdate.forecast_date)
        AND mfdesi.forecast_designator = mfdate.forecast_designator
        AND mfdesi.organization_id = mfdate.organization_id
        AND mfdate.inventory_item_id = msib.inventory_item_id
        AND mfdate.organization_id = msib.organization_id
        AND xph.price_header_id = xpl.price_header_id
        AND xph.price_type = gc_price_type
        AND mfdate.forecast_date
          BETWEEN xph.start_date_active AND NVL(xph.end_date_active,mfdate.forecast_date)
        AND mfdesi.disable_date IS NULL
        AND mfdesi.attribute6 = civ_current_year --�V.�N�x
        AND mfdesi.attribute5 = civ_current_gene --�V.����
        AND msib.segment1 = xph.item_code
        AND flv_item.lookup_type = gc_item_type
        AND flv_item.attribute1 = xpl.expense_item_type
        AND mfdate.forecast_date
          BETWEEN flv_item.start_date_active AND NVL(flv_item.end_date_active,mfdate.forecast_date)
        GROUP BY 
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          mfdate.original_forecast_quantity
--         ,mfdate.forecast_date
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          xph.item_id
         ,xph.item_code
      ) np
     ,(
        SELECT
          xph.item_id                         AS item_id
         ,xph.item_code                       AS item_code
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--         ,SUM(xpl.quantity * xpl.unit_price)  AS cost_price_old
         ,SUM(mfdate.original_forecast_quantity * xpl.unit_price)  AS cost_price_old
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
         ,SUM(CASE WHEN flv_item.attribute2 = gc_row_material_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS row_material_cost_old
         ,SUM(CASE WHEN flv_item.attribute2 = gc_remake_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS remake_cost_old
         ,SUM(CASE WHEN flv_item.attribute2 = gc_material_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS material_cost_old
         ,SUM(CASE WHEN flv_item.attribute2 = gc_wrapping_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS wrapping_cost_old
         ,SUM(CASE WHEN flv_item.attribute2 = gc_outside_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS outside_cost_old
         ,SUM(CASE WHEN flv_item.attribute2 = gc_store_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS store_cost_old
         ,SUM(CASE WHEN flv_item.attribute2 = gc_other_cost
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                     THEN xpl.quantity * xpl.unit_price
                     THEN mfdate.original_forecast_quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END) AS other_cost_old
        FROM
          mrp_forecast_designators              mfdesi  --�t�H�[�L���X�g��
         ,xxcmn_lookup_values2_v                flv_fc     --�N�C�b�N�R�[�h
         ,mrp_forecast_dates                    mfdate  --�t�H�[�L���X�g���t
         ,mtl_system_items_b                    msib    --�i�ڃ}�X�^
         ,xxpo_price_headers                    xph     --�d���E�W���P���w�b�_
         ,xxpo_price_lines                      xpl
         ,xxcmn_lookup_values2_v                flv_item
        WHERE flv_fc.lookup_type = gc_fc_type
        AND flv_fc.description = gc_fc_description
        AND mfdesi.attribute1 = flv_fc.lookup_code
        AND mfdate.forecast_date
          BETWEEN flv_fc.start_date_active AND NVL(flv_fc.end_date_active,mfdate.forecast_date)
        AND mfdesi.forecast_designator = mfdate.forecast_designator
        AND mfdesi.organization_id = mfdate.organization_id
        AND mfdate.inventory_item_id = msib.inventory_item_id
        AND mfdate.organization_id = msib.organization_id
        AND xph.price_header_id = xpl.price_header_id
        AND xph.price_type = gc_price_type
        AND mfdate.forecast_date
          BETWEEN xph.start_date_active AND NVL(xph.end_date_active,mfdate.forecast_date)
        AND mfdesi.disable_date IS NULL
        AND mfdesi.attribute6 = civ_prev_year --�V.�N�x
        AND mfdesi.attribute5 = civ_prev_gene --�V.����
        AND msib.segment1 = xph.item_code
        AND flv_item.lookup_type = gc_item_type
        AND flv_item.attribute1 = xpl.expense_item_type
        AND mfdate.forecast_date
          BETWEEN flv_item.start_date_active AND NVL(flv_item.end_date_active,mfdate.forecast_date)
        GROUP BY 
          mfdate.original_forecast_quantity
         ,xph.item_id
         ,xph.item_code
      ) op
     ,(
        SELECT
          MAX(CASE WHEN mcst.description = gc_description_prov THEN mcb.segment1 ELSE NULL END)
          AS prod_div --���i�敪
         ,MAX(CASE WHEN mcst.description = gc_description_prov THEN mct.description ELSE NULL END)
          AS prod_div_name --���i�敪��
         ,MAX(CASE WHEN mcst.description = gc_description_crowd THEN mcb.segment1 ELSE NULL END)
          AS crowd_code --�Q�R�[�h
         ,gic.item_id           AS item_id --�i��ID
        FROM
          mtl_category_sets_tl     mcst  --�i�ڃJ�e�S���Z�b�g���{��
         ,mtl_category_sets_b      mcsb  --�i�ڃJ�e�S���Z�b�g
         ,mtl_categories_b         mcb   --�i�ڃJ�e�S���}�X�^
         ,mtl_categories_tl        mct   --�i�ڃJ�e�S���}�X�^���{��
         ,gmi_item_categories      gic   --OPM�i�ڃJ�e�S������
        WHERE mcst.description IN( gc_description_prov,gc_description_crowd)
        AND mcst.language = gc_lang
        AND mcst.source_lang = gc_source_lang
        AND mcst.category_set_id = mcsb.category_set_id
        AND mcsb.structure_id = mcb.structure_id
        AND mcb.category_id = mct.category_id
        AND mct.language = gc_lang
        AND mct.source_lang = gc_source_lang
        AND mcsb.category_set_id = gic.category_set_id
        AND mcb.category_id = gic.category_id
        GROUP BY gic.item_id
      ) m
     ,ic_item_mst_b            iimb  --OPM�i�ڃ}�X�^
     ,xxcmn_item_mst_b         ximb  --OPM�i�ڃA�h�I���}�X�^
    WHERE np.item_id = op.item_id(+)
    AND np.item_id = m.item_id
    AND np.item_id = iimb.item_id
    AND np.item_id = ximb.item_id
    AND np.forecast_date
      BETWEEN ximb.start_date_active AND NVL(ximb.end_date_active,np.forecast_date)
    --�i����(���i�敪)
    AND (civ_prod_div IS NOT NULL AND m.prod_div = civ_prod_div
    OR   civ_prod_div IS NULL)
    --�i����(�Q�R�[�h)
    AND (civ_crowd_code_01 IS NULL AND civ_crowd_code_02 IS NULL AND civ_crowd_code_03 IS NULL 
    AND  civ_crowd_code_04 IS NULL AND civ_crowd_code_05 IS NULL
    OR   civ_crowd_code_01 IS NOT NULL AND m.crowd_code LIKE civ_crowd_code_01 || '%'
    OR   civ_crowd_code_02 IS NOT NULL AND m.crowd_code LIKE civ_crowd_code_02 || '%'
    OR   civ_crowd_code_03 IS NOT NULL AND m.crowd_code LIKE civ_crowd_code_03 || '%'
    OR   civ_crowd_code_04 IS NOT NULL AND m.crowd_code LIKE civ_crowd_code_04 || '%'
    OR   civ_crowd_code_05 IS NOT NULL AND m.crowd_code LIKE civ_crowd_code_05 || '%')
    ORDER BY m.prod_div,m.crowd_code,TO_NUMBER(np.item_code)
    ;
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
    -- �O�N�x�̍ŐV����擾
    -- ====================================================
    lv_prev_year := TO_CHAR(TO_NUMBER(ir_param_rec.fiscal_year) - 1);
--
    BEGIN
      SELECT NVL(MAX(mfdesi.attribute5),'0')
      INTO lv_prev_gene
       FROM
         mrp_forecast_designators  mfdesi
        ,xxcmn_lookup_values2_v    flv
        ,mrp_forecast_dates        mfdate
        ,mtl_system_items_b        msib
      WHERE flv.lookup_type = gc_fc_type
      AND flv.description = gc_fc_description
      AND mfdesi.attribute1 = flv.lookup_code
      AND mfdate.forecast_date
        BETWEEN flv.start_date_active AND NVL(flv.end_date_active,mfdate.forecast_date)
      AND mfdesi.forecast_designator = mfdate.forecast_designator
      AND mfdesi.organization_id = mfdate.organization_id
      AND mfdate.inventory_item_id = msib.inventory_item_id
      AND mfdate.organization_id = msib.organization_id
      AND mfdesi.attribute6 = lv_prev_year
      AND mfdesi.disable_date IS NULL
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn   , gv_msg_num_10003
                                              ,'TABLE' , gv_prev_gene_err_name
                                              ,'KEY', lv_prev_year );
        RAISE data_check_expt ;
    END;
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN cur_main_data
      (
        ir_param_rec.fiscal_year
       ,ir_param_rec.generation
       ,lv_prev_year
       ,lv_prev_gene
       ,ir_param_rec.prod_div
       ,ir_param_rec.crowd_code_01
       ,ir_param_rec.crowd_code_02
       ,ir_param_rec.crowd_code_03
       ,ir_param_rec.crowd_code_04
       ,ir_param_rec.crowd_code_05
      );
--
    --�o���N�t�F�b�`
    FETCH cur_main_data BULK COLLECT INTO ot_data_rec;
    --�N���[�Y
    CLOSE cur_main_data;
--
  EXCEPTION
--
    WHEN data_check_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
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
  END prc_get_record;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_header_info
   * Description      : �w�b�_���擾
   ***********************************************************************************/
  PROCEDURE prc_get_header_info
    (
      ov_errbuf        OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_header_info'; -- �v���O������
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
--
    -- *** ���[�J���E�ϐ� ***
    lv_err_code     VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
--
    -- *** ���[�J���E��O���� ***
--
  BEGIN
    -- ====================================================
    -- ���{���擾
    -- ====================================================
    gd_exec_date := SYSDATE;
--
    -- ====================================================
    -- �S�������擾
    -- ====================================================
    gv_department_code := SUBSTRB( xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ), 1, 10 ) ;
--
    -- ====================================================
    -- �S���Ҏ擾
    -- ====================================================
    gv_department_name := SUBSTRB( xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ), 1, 14 ) ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
--####################################  �Œ蕔 END   ##########################################
--
  END prc_get_header_info;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml
   * Description      : XML�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_xml
   (
    ir_param_rec       IN  rec_param_data
   ,iox_xml_data       IN OUT  NOCOPY XML_DATA -- 1.XML�f�[�^
   ,ov_errbuf          OUT VARCHAR2     --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT VARCHAR2     --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
   )
  IS
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml'; -- �v���O������
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
    lt_data_rec              tab_data;
    ln_idx                   NUMBER := 0;
    lv_prod_div              VARCHAR2(2) ;         -- ���i�敪�擾�p
    lv_prod_div_name         VARCHAR2(20) ;        -- ���i�敪��
    lv_crd_code_big          VARCHAR2(4);
    lv_crd_code_middle       VARCHAR2(4);
    lv_crd_code_small        VARCHAR2(4);
    lv_crd_code_detail       VARCHAR2(4);
    lv_crowd_code_current    VARCHAR2(4);
    lv_prod_div_current      VARCHAR2(1);
    ln_quant                 NUMBER;
    lv_output_unit_name      VARCHAR2(6);
--
    -- *** ���[�J���E��O���� ***
    no_data_expt                 EXCEPTION ;             -- �擾���R�[�h�Ȃ�
    data_check_expt              EXCEPTION ;             -- �f�[�^�`�F�b�N�G�N�Z�v�V����
--
  BEGIN
    -- =====================================================
    -- �w�b�_�[���擾
    -- =====================================================
    prc_get_header_info
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
    -- =====================================================
    -- ���׏��擾
    -- =====================================================
    prc_get_record
      (
        ir_param_rec      => ir_param_rec       -- ���̓p�����[�^�Q
       ,ot_data_rec       => lt_data_rec        -- �擾���R�[�h
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    ELSIF lt_data_rec.COUNT = 0 THEN
      RAISE no_data_expt;
    END IF ;
--
    -- =====================================================
    -- XML�쐬
    -- =====================================================
    -- �f�[�^�O���[�v���J�n�^�O�Z�b�g   <root>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'root' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- �f�[�^�O���[�v���J�n�^�O�Z�b�g   <user_info>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'user_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- �f�[�^�Z�b�g                     <report_id>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'report_id' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := gv_report_id ;
--
    -- �f�[�^�Z�b�g                     <exec_date>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'exec_date' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := TO_CHAR( gd_exec_date, 'YYYY/MM/DD HH24:MI:SS' ) ;
--
    -- �f�[�^�Z�b�g                     <exec_user_dept>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'exec_user_dept' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := gv_department_code;
--
    -- �f�[�^�Z�b�g                     <exec_user_name>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'exec_user_name' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := gv_department_name;
--
    -- �f�[�^�O���[�v���I���^�O�Z�b�g   </user_info>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/user_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- �p�����[�^�f�[�^�Z�b�g
    -- =====================================================
    -- �f�[�^�O���[�v���J�n�^�O�Z�b�g   <param_info>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- �f�[�^�Z�b�g                     <param_01>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_01' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_param_rec.fiscal_year ;
--
    -- �f�[�^�Z�b�g                     <param_02>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_02' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_param_rec.prod_div ;
--
    -- �f�[�^�Z�b�g                     <param_03>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_03' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := ir_param_rec.generation ;
--
    -- �f�[�^�Z�b�g                     <param_04>
    IF (ir_param_rec.output_unit = gc_output_unit_code_quant ) THEN
      lv_output_unit_name := gc_output_unit_name_quant;
    ELSIF (ir_param_rec.output_unit = gc_output_unit_code_case) THEN
      lv_output_unit_name := gc_output_unit_name_case;
    END IF;
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'param_04' ;
    iox_xml_data(ln_idx).tag_type  := 'D' ;
    iox_xml_data(ln_idx).tag_value := lv_output_unit_name ;
--
    -- �f�[�^�O���[�v���I���^�O�Z�b�g   </param_info>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/param_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- ���׃f�[�^�^�O�Z�b�g
    -- =====================================================
    -- �f�[�^�O���[�v���J�n�^�O�Z�b�g   <data_info>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'data_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- ���i�敪���X�g�^�O�Z�b�g   <lg_prod>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := 'lg_prod' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    FOR i IN 1..lt_data_rec.COUNT LOOP
--
      --���������R�[�h�̌Q�R�[�h
      lv_crowd_code_current := lt_data_rec(i).crowd_code ;
      lv_prod_div_current := lt_data_rec(i).prod_div;
--
      -- ===================================================
      -- �f�[�^�������^�O�A�f�[�^�Z�b�g
      -- ===================================================
      IF (i = 1) THEN
--
        -- ���i�敪���
        lv_prod_div    := lv_prod_div_current;
        -- ��Q�R�[�h���
        lv_crd_code_big := SUBSTR(lv_crowd_code_current,1,1) ;
        -- ���Q�R�[�h���
        lv_crd_code_middle := SUBSTR(lv_crowd_code_current,1,2) ;
        -- ���Q�R�[�h03���
        lv_crd_code_small := SUBSTR(lv_crowd_code_current,1,3) ;
        -- �׌Q�R�[�h���
        lv_crd_code_detail := lv_crowd_code_current ;
--
        -- ==================================================
        -- �f�[�^�Z�b�g
        -- ==================================================
        -- �f�[�^�O���[�v���J�n�^�O�Z�b�g         <g_prod>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_prod' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- �f�[�^�Z�b�g  ���i�敪                 <prod_div>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'prod_div' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lv_prod_div ;
--
        -- �f�[�^�Z�b�g  ���i�敪��               <prod_div_name>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'prod_div_name' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lt_data_rec(i).prod_div_name ;
--
        -- �^�O�Z�b�g    ��Q�R�[�h���X�g              <lg_crd_big>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'lg_crd_big' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- �^�O�Z�b�g  ��Q�R�[�h�O���[�v                 <g_crd_big>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_crd_big' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- �f�[�^�Z�b�g  ��Q�R�[�h                 <crd_code_big>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'crd_code_big' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lv_crd_code_big ;

        -- �^�O�Z�b�g    ���Q�R�[�h���X�g     <lg_crd_middle>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'lg_crd_middle' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- �^�O�Z�b�g  ���Q�R�[�h�O���[�v                 <g_crd_middle>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_crd_middle' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- �f�[�^�Z�b�g  ���Q�R�[�h                 <crd_code_middle>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'crd_code_middle' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lv_crd_code_middle ;

        -- �^�O�Z�b�g    ���Q�R�[�h���X�g     <lg_crd_small>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'lg_crd_small' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      -- �^�O�Z�b�g  ���Q�R�[�h�O���[�v                   <g_crd_small>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_crd_small' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- �f�[�^�Z�b�g  ���Q�R�[�h                 <crd_code_small>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'crd_code_small' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lv_crd_code_small ;
--
        -- �^�O�Z�b�g     �׌Q�R�[�h���X�g    <lg_crd_detail>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'lg_crd_detail' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      -- �^�O�Z�b�g  �׌Q�R�[�h                   <g_crd_detail>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_crd_detail' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      -- �f�[�^�Z�b�g  �׌Q�R�[�h                   <crd_code_detail>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'crd_code_detail' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lv_crd_code_detail ;
--
      END IF;
--
      -- ===========================================================
      -- �O��׌Q�R�[�h�ƈقȂ�ꍇ�A�׌Q�R�[�h�^�O�A�f�[�^�Z�b�g
      -- ===========================================================
      IF (lv_crd_code_detail != lv_crowd_code_current) THEN
        --�׌Q�R�[�h����
        lv_crd_code_detail := lv_crowd_code_current;
--
        -- �I���^�O�Z�b�g         </g_crd_detail>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := '/g_crd_detail' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- ===========================================================
        -- �O�񏬌Q�R�[�h�ƈقȂ�ꍇ�A���Q�R�[�h�^�O�A�f�[�^�Z�b�g
        -- ===========================================================
        IF (lv_crd_code_small != SUBSTRB(lv_crowd_code_current,1,3)) THEN
          --���Q�R�[�h����
          lv_crd_code_small := SUBSTRB(lv_crowd_code_current,1,3);
--
          -- �I���^�O�Z�b�g         </lg_crd_detail>
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := '/lg_crd_detail' ;
          iox_xml_data(ln_idx).tag_type  := 'T' ;
--
          -- �I���^�O�Z�b�g       </g_crd_small>
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := '/g_crd_small' ;
          iox_xml_data(ln_idx).tag_type  := 'T' ;
--
          -- ===========================================================
          -- �O�񒆌Q�R�[�h�ƈقȂ�ꍇ�A���Q�R�[�h�^�O�A�f�[�^�Z�b�g
          -- ===========================================================
          IF (lv_crd_code_middle != SUBSTRB(lv_crowd_code_current,1,2)) THEN
            --���Q�R�[�h����
            lv_crd_code_middle := SUBSTRB(lv_crowd_code_current,1,2);
--
            -- �I���^�O�Z�b�g       </lg_crd_small>
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := '/lg_crd_small' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            -- �I���^�O�Z�b�g     </g_crd_middle>
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := '/g_crd_middle' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            -- ===========================================================
            -- �O���Q�R�[�h�ƈقȂ�ꍇ�A��Q�R�[�h�^�O�A�f�[�^�Z�b�g
            -- ===========================================================
            IF (lv_crd_code_big != SUBSTRB(lv_crowd_code_current,1,1)) THEN
              --��Q�R�[�h����
              lv_crd_code_big := SUBSTRB(lv_crowd_code_current,1,1);
--
              -- �I���^�O�Z�b�g     </lg_crd_middle>
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := '/lg_crd_middle' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              -- �I���^�O�Z�b�g   </g_crd_big>
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := '/g_crd_big' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              -- ===========================================================
              -- �O�񏤕i�敪�ƈقȂ�ꍇ�A���i�敪�^�O�A�f�[�^�Z�b�g
              -- ===========================================================
              IF (lv_prod_div != lv_prod_div_current) THEN
                --���i�敪����
                lv_prod_div := lv_prod_div_current;
--
                -- �I���^�O�Z�b�g   </lg_crd_big>
                ln_idx := iox_xml_data.COUNT + 1 ;
                iox_xml_data(ln_idx).tag_name  := '/lg_crd_big' ;
                iox_xml_data(ln_idx).tag_type  := 'T' ;
--
                -- �f�[�^�O���[�v���I���^�O�Z�b�g </g_prod>
                ln_idx := iox_xml_data.COUNT + 1 ;
                iox_xml_data(ln_idx).tag_name  := '/g_prod' ;
                iox_xml_data(ln_idx).tag_type  := 'T' ;
--
                -- �f�[�^�O���[�v���J�n�^�O�Z�b�g <g_prod>
                ln_idx := iox_xml_data.COUNT + 1 ;
                iox_xml_data(ln_idx).tag_name  := 'g_prod' ;
                iox_xml_data(ln_idx).tag_type  := 'T' ;
--
                -- �f�[�^�Z�b�g  ���i�敪           <prod_div>
                ln_idx := iox_xml_data.COUNT + 1 ;
                iox_xml_data(ln_idx).tag_name  := 'prod_div' ;
                iox_xml_data(ln_idx).tag_type  := 'D' ;
                iox_xml_data(ln_idx).tag_value := lv_prod_div ;
--
                -- �f�[�^�Z�b�g  ���i�敪��               <prod_div_name>
                ln_idx := iox_xml_data.COUNT + 1 ;
                iox_xml_data(ln_idx).tag_name  := 'prod_div_name' ;
                iox_xml_data(ln_idx).tag_type  := 'D' ;
                iox_xml_data(ln_idx).tag_value := lt_data_rec(i).prod_div_name ;
--
                -- �J�n�^�O�Z�b�g   <lg_crd_big>
                ln_idx := iox_xml_data.COUNT + 1 ;
                iox_xml_data(ln_idx).tag_name  := 'lg_crd_big' ;
                iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              END IF;
--
              -- �J�n�^�O�Z�b�g   <g_crd_big>
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'g_crd_big' ;
              iox_xml_data(ln_idx).tag_type  := 'T' ;
--
              -- �f�[�^�Z�b�g  �Q�R�[�h             <crd_code_big>
              ln_idx := iox_xml_data.COUNT + 1 ;
              iox_xml_data(ln_idx).tag_name  := 'crd_code_big' ;
              iox_xml_data(ln_idx).tag_type  := 'D' ;
              iox_xml_data(ln_idx).tag_value := lv_crd_code_big ;
--
            -- �f�[�^�O���[�v���J�n�^�O�Z�b�g      <lg_crd_middle>
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := 'lg_crd_middle' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            END IF;
--
            -- �f�[�^�O���[�v���J�n�^�O�Z�b�g      <g_crd_middle>
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := 'g_crd_middle' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
            -- �f�[�^�Z�b�g  �Q�R�[�h               <gun_02>
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := 'crd_code_middle' ;
            iox_xml_data(ln_idx).tag_type  := 'D' ;
            iox_xml_data(ln_idx).tag_value := lv_crd_code_middle ;
--
            -- �f�[�^�O���[�v���J�n�^�O�Z�b�g       <lg_crd_small>
            ln_idx := iox_xml_data.COUNT + 1 ;
            iox_xml_data(ln_idx).tag_name  := 'lg_crd_small' ;
            iox_xml_data(ln_idx).tag_type  := 'T' ;
--
          END IF;
--
--
          -- �f�[�^�O���[�v���J�n�^�O�Z�b�g       <g_crd_small>
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := 'g_crd_small' ;
          iox_xml_data(ln_idx).tag_type  := 'T' ;
--
          -- �f�[�^�Z�b�g  �Q�R�[�h                 <crd_code_small>
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := 'crd_code_small' ;
          iox_xml_data(ln_idx).tag_type  := 'D' ;
          iox_xml_data(ln_idx).tag_value := lv_crd_code_small ;
--
          -- �J�n�^�O�Z�b�g         <lg_crd_detail>
          ln_idx := iox_xml_data.COUNT + 1 ;
          iox_xml_data(ln_idx).tag_name  := 'lg_crd_detail' ;
          iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        END IF;
--
        -- �J�n�^�O�Z�b�g         <g_crd_detail>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'g_crd_detail' ;
        iox_xml_data(ln_idx).tag_type  := 'T' ;
--
        -- �f�[�^�Z�b�g  �Q�R�[�h                   <crd_code_detail>
        ln_idx := iox_xml_data.COUNT + 1 ;
        iox_xml_data(ln_idx).tag_name  := 'crd_code_detail' ;
        iox_xml_data(ln_idx).tag_type  := 'D' ;
        iox_xml_data(ln_idx).tag_value := lv_crd_code_detail ;
--
      END IF;
--
      -- �J�n�^�O�Z�b�g           <g_item>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'g_item' ;
      iox_xml_data(ln_idx).tag_type  := 'T' ;
--
      -- �f�[�^�Z�b�g  �Q�R�[�h                   <crd_code>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'crd_code' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lv_crd_code_detail ;
--
      -- �f�[�^�Z�b�g  �i�ڃR�[�h                 <item_code>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'item_code' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).item_code ;
--
      -- �f�[�^�Z�b�g  �i�ږ���                   <item_name>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'item_name' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).item_name ;
--
      IF (ir_param_rec.output_unit = gc_output_unit_code_case) THEN 
        -- �f�[�^�Z�b�g  ����                       <quantity>
        IF (TO_NUMBER(lt_data_rec(i).in_case) = 0) THEN
          lv_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn   , gv_msg_num_10013
                                                ,'ITEM' , lt_data_rec(i).item_code || gv_ofcase_name
                                                );
          RAISE data_check_expt ;
        END IF;
--
        ln_quant := CEIL( TRUNC( 
                            lt_data_rec(i).forecast_quantity_new 
                            / TO_NUMBER( lt_data_rec(i).in_case )
                            , 1 )
                        ) ;
      ELSE 
        ln_quant := lt_data_rec(i).forecast_quantity_new ;
      END IF ;
--
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'quantity' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := ln_quant ;
--
      -- �f�[�^�Z�b�g  �V.�W������                 <n_cost_price>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_cost_price' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).cost_price_new ;
--
      -- �f�[�^�Z�b�g  �V.������                 <n_row_material_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_row_material_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).row_material_cost_new ;
--
      -- �f�[�^�Z�b�g  �V.�Đ���                 <n_remake_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_remake_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).remake_cost_new ;
--
      -- �f�[�^�Z�b�g  �V.���ޔ�                 <n_material_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_material_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).material_cost_new ;
--
      -- �f�[�^�Z�b�g  �V.���                 <n_wrapping_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_wrapping_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).wrapping_cost_new ;
--
      -- �f�[�^�Z�b�g  �V.�O���Ǘ���                 <n_outside_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_outside_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).outside_cost_new ;
--
      -- �f�[�^�Z�b�g  �V.�ۊǔ�                 <n_store_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_store_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).store_cost_new ;
--
      -- �f�[�^�Z�b�g  �V.���̑��o��                 <n_other_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'n_other_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).other_cost_new ;
--
      -- �f�[�^�Z�b�g  ��.�W������                 <o_cost_price>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_cost_price' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).cost_price_old ;
--
      -- �f�[�^�Z�b�g  ��.������                 <o_row_material_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_row_material_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).row_material_cost_old ;
--
      -- �f�[�^�Z�b�g  ��.�Đ���                 <o_remake_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_remake_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).remake_cost_old ;
--
      -- �f�[�^�Z�b�g  ��.���ޔ�                 <o_material_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_material_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).material_cost_old ;
--
      -- �f�[�^�Z�b�g  ��.���                 <o_wrapping_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_wrapping_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).wrapping_cost_old ;
--
      -- �f�[�^�Z�b�g  ��.�O���Ǘ���                 <o_outside_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_outside_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).outside_cost_old ;
--
      -- �f�[�^�Z�b�g  ��.�ۊǔ�                 <o_store_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_store_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).store_cost_old ;
--
      -- �f�[�^�Z�b�g  ��.���̑��o��                 <o_other_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'o_other_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).other_cost_old ;
--
      -- �f�[�^�Z�b�g  ��.�W������               <d_cost_price>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_cost_price' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).cost_price_new
                                        - lt_data_rec(i).cost_price_old ;
--
      -- �f�[�^�Z�b�g  ��.������               <d_row_material_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_row_material_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).row_material_cost_new
                                        - lt_data_rec(i).row_material_cost_old ;
--
      -- �f�[�^�Z�b�g  ��.�Đ���               <d_remake_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_remake_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).remake_cost_new
                                        - lt_data_rec(i).remake_cost_old ;
--
      -- �f�[�^�Z�b�g  ��.���ޔ�               <d_material_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_material_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).material_cost_new
                                        - lt_data_rec(i).material_cost_old ;
--
      -- �f�[�^�Z�b�g  ��.���               <d_wrapping_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_wrapping_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).wrapping_cost_new
                                        - lt_data_rec(i).wrapping_cost_old ;
--
      -- �f�[�^�Z�b�g  ��.�O���Ǘ���               <d_outside_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_outside_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).outside_cost_new
                                        - lt_data_rec(i).outside_cost_old ;
--
      -- �f�[�^�Z�b�g  ��.�ۊǔ�               <d_store_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_store_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).store_cost_new
                                        - lt_data_rec(i).store_cost_old ;
--
      -- �f�[�^�Z�b�g  ��.���̑��o��               <d_other_cost>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := 'd_other_cost' ;
      iox_xml_data(ln_idx).tag_type  := 'D' ;
      iox_xml_data(ln_idx).tag_value := lt_data_rec(i).other_cost_new
                                        - lt_data_rec(i).other_cost_old ;
--
      -- �I���^�O�Z�b�g           </g_item>
      ln_idx := iox_xml_data.COUNT + 1 ;
      iox_xml_data(ln_idx).tag_name  := '/g_item' ;
      iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop;
--
    -- ���i�敪���X�g�^�O�Z�b�g   </g_crd_detail>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_crd_detail' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- ���i�敪���X�g�^�O�Z�b�g   </lg_crd_detail>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_crd_detail' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- ���i�敪���X�g�^�O�Z�b�g   </g_crd_small>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_crd_small' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- ���i�敪���X�g�^�O�Z�b�g   </lg_crd_small>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_crd_small' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- ���i�敪���X�g�^�O�Z�b�g   </g_crd_middle>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_crd_middle' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- ���i�敪���X�g�^�O�Z�b�g   </lg_crd_middle>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_crd_middle' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- ���i�敪���X�g�^�O�Z�b�g   </g_crd_big>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_crd_big' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- ���i�敪���X�g�^�O�Z�b�g   </lg_crd_big>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_crd_big' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- ���i�敪���X�g�^�O�Z�b�g   </g_prod>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/g_prod' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- ���i�敪���X�g�^�O�Z�b�g   </lg_prod>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/lg_prod' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- �f�[�^�O���[�v���J�n�^�O�Z�b�g   </data_info>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/data_info' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
    -- �f�[�^�O���[�v���J�n�^�O�Z�b�g   </root>
    ln_idx := iox_xml_data.COUNT + 1 ;
    iox_xml_data(ln_idx).tag_name  := '/root' ;
    iox_xml_data(ln_idx).tag_type  := 'T' ;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn
                                             ,gc_xxcmn_10122 ) ;
--
    WHEN data_check_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
--####################################  �Œ蕔 END   ##########################################
--
  END prc_create_xml;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_fiscal_year      IN  VARCHAR2     --    01.�N�x
   ,iv_generation       IN  VARCHAR2     --    02.����
   ,iv_prod_div         IN  VARCHAR2     --    03.���i�敪
   ,iv_crowd_code_01    IN  VARCHAR2     --    04.�Q�R�[�h1
   ,iv_crowd_code_02    IN  VARCHAR2     --    05.�Q�R�[�h2
   ,iv_crowd_code_03    IN  VARCHAR2     --    06.�Q�R�[�h3
   ,iv_crowd_code_04    IN  VARCHAR2     --    07.�Q�R�[�h4
   ,iv_crowd_code_05    IN  VARCHAR2     --    08.�Q�R�[�h5
   ,iv_output_unit      IN  VARCHAR2     --    09.�o�͒P��
   ,ov_errbuf           OUT VARCHAR2     --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT VARCHAR2     --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2     --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lr_param_rec            rec_param_data ;          -- �p�����[�^��n���p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ��������
    -- ===============================================
    lr_param_rec.output_unit    := iv_output_unit ;     -- �o�͒P��
    lr_param_rec.fiscal_year    := iv_fiscal_year ;     -- �Ώ۔N�x
    lr_param_rec.generation     := iv_generation ;      -- ����
    lr_param_rec.prod_div       := iv_prod_div ;        -- ���i�敪
    lr_param_rec.crowd_code_01  := iv_crowd_code_01 ;   -- �Q�R�[�h�P
    lr_param_rec.crowd_code_02  := iv_crowd_code_02 ;   -- �Q�R�[�h�Q
    lr_param_rec.crowd_code_03  := iv_crowd_code_03 ;   -- �Q�R�[�h�R
    lr_param_rec.crowd_code_04  := iv_crowd_code_04 ;   -- �Q�R�[�h�S
    lr_param_rec.crowd_code_05  := iv_crowd_code_05 ;   -- �Q�R�[�h�T
--
    -- ===============================================
    -- ���[�R���J�����g���s
    -- ===============================================
    prc_create_xml
      (
        ir_param_rec      => lr_param_rec       -- ���̓p�����[�^�Q
       ,iox_xml_data      => xml_data_table
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML�o��
    -- ==================================================
    IF (lv_retcode = gv_status_warn) THEN
      --0��XML�쐬
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis"?>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_prod>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_prod>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_crd_big>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_crd_big>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_crd_middle>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_crd_middle>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_crd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_crd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <lg_crd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      <g_crd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        <msg>***�@�f�[�^�͂���܂���@***</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      </g_crd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    </lg_crd_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_crd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_crd_small>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_crd_middle>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_crd_middle>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_crd_big>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_crd_big>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_prod>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_prod>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    ELSE
      output_xml(
        iox_xml_data   => xml_data_table,  -- XML�f�[�^
        ov_errbuf      => lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode     => lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg      => lv_errmsg
        ) ;
      -- �G���[�n���h�����O
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�Z�b�g
    -- ======================================================
    IF (lv_retcode = gv_status_warn) THEN
      -- �x������
      ov_retcode := lv_retcode ;
      ov_errmsg  := lv_errmsg ;
    END IF ;
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
--####################################  �Œ蕔 END   ##########################################
--
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
      errbuf                OUT    VARCHAR2         --   �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         --   �G���[�R�[�h
     ,iv_fiscal_year        IN     VARCHAR2         --   01 : �Ώ۔N�x
     ,iv_generation         IN     VARCHAR2         --   02 : ����
     ,iv_prod_div           IN     VARCHAR2         --   03 : ���i�敪
     ,iv_output_unit        IN     VARCHAR2         --   04 : �o�͒P��
     ,iv_crowd_code_01      IN     VARCHAR2         --   05 : �Q�R�[�h1
     ,iv_crowd_code_02      IN     VARCHAR2         --   06 : �Q�R�[�h2
     ,iv_crowd_code_03      IN     VARCHAR2         --   07 : �Q�R�[�h3
     ,iv_crowd_code_04      IN     VARCHAR2         --   08 : �Q�R�[�h4
     ,iv_crowd_code_05      IN     VARCHAR2         --   09 : �Q�R�[�h5
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
        iv_fiscal_year    => iv_fiscal_year           -- 01 : �N�x
       ,iv_generation     => iv_generation            -- 02 : ����
       ,iv_prod_div       => iv_prod_div              -- 03 : ���i�敪
       ,iv_crowd_code_01  => iv_crowd_code_01         -- 04 : �Q�R�[�h1
       ,iv_crowd_code_02  => iv_crowd_code_02         -- 05 : �Q�R�[�h2
       ,iv_crowd_code_03  => iv_crowd_code_03         -- 06 : �Q�R�[�h3
       ,iv_crowd_code_04  => iv_crowd_code_04         -- 07 : �Q�R�[�h4
       ,iv_crowd_code_05  => iv_crowd_code_05         -- 08 : �Q�R�[�h5
       ,iv_output_unit    => iv_output_unit           -- 09 : �o�͒P��
       ,ov_errbuf         => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
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
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn820004c;
/

