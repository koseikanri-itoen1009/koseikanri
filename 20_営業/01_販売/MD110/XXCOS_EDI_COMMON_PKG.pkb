CREATE OR REPLACE PACKAGE BODY apps.xxcos_edi_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcos_edi_common_pkg(body)
 * Description            :
 * MD.070                 : MD070_IPO_COS_嫟捠娭悢
 * Version                : 1.9
 *
 * Program List
 *  ----------------------------- ---- ----- -----------------------------------------
 *   Name                         Type  Ret   Description
 *  ----------------------------- ---- ----- -----------------------------------------
 *  edi_manual_order_acquisition  P          EDI庴拲庤擖椡暘庢崬
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/11/26   1.0   H.Fujimoto       怴婯嶌惉
 *  2009/03/03   1.1   H.Fujimoto       寢崌晄嬶崌No152
 *  2009/03/24   1.2   T.Miyata         ST忈奞丗T1_0126
 *  2009/04/24   1.3   K.Kiriu          ST忈奞丗T1_0112
 *  2009/06/19   1.4   N.Maeda          [T1_1358]懳墳
 *  2009/07/13   1.5   K.Kiriu          [0000660]懳墳
 *  2009/07/14   1.6   K.Kiriu          [0000064]懳墳
 *  2009/08/11   1.7   K.Kiriu          [0000966]懳墳
 *  2010/03/09   1.8   S.Karikomi       [E_杮壱摥_01637]懳墳
 *  2010/04/15   1.9   S.Karikomi       [E_杮壱摦_02296]懳墳
 *****************************************************************************************/
  -- ===============================
  -- 僌儘乕僶儖曄悢
  -- ===============================
  gv_msg_part VARCHAR2(100) := ' : ';
--
  /**********************************************************************************
   * Procedure Name   : edi_manual_order_acquisition
   * Description      : EDI庴拲庤擖椡暘庢崬
   ***********************************************************************************/
  PROCEDURE edi_manual_order_acquisition(
               iv_edi_chain_code           IN VARCHAR2  DEFAULT NULL  -- EDI僠僃乕儞揦僐乕僪
              ,iv_edi_forward_number       IN VARCHAR2  DEFAULT NULL  -- EDI揱憲捛斣
              ,id_shop_delivery_date_from  IN DATE      DEFAULT NULL  -- 揦曑擺昳擔(From)
              ,id_shop_delivery_date_to    IN DATE      DEFAULT NULL  -- 揦曑擺昳擔(To)
              ,iv_regular_ar_sale_class    IN VARCHAR2  DEFAULT NULL  -- 掕斣摿攧嬫暘
              ,iv_area_code                IN VARCHAR2  DEFAULT NULL  -- 抧嬫僐乕僪
              ,id_center_delivery_date     IN DATE      DEFAULT NULL  -- 僙儞僞乕擺昳擔
              ,in_organization_id          IN NUMBER    DEFAULT NULL  -- 嵼屔慻怐ID
              ,ov_errbuf                   OUT NOCOPY VARCHAR2        -- 僄儔乕丒儊僢僙乕僕           --# 屌掕 #
              ,ov_retcode                  OUT NOCOPY VARCHAR2        -- 儕僞乕儞丒僐乕僪             --# 屌掕 #
              ,ov_errmsg                   OUT NOCOPY VARCHAR2        -- 儐乕僓乕丒僄儔乕丒儊僢僙乕僕 --# 屌掕 #
            )
  IS
    -- ===============================
    -- 儘乕僇儖掕悢
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_edi_common_pkg.edi_manual_order_acquisition'; -- 僾儘僌儔儉柤
--
/* 2009/07/13 Ver1.5 Add Start */
    --儊僢僙乕僕
    cv_msg_sales_class      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00034';  --攧忋嬫暘崿嵼僄儔乕
    cv_msg_not_outbound     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13593';  --OUTBOUD壜斲僄儔乕
/* 2009/08/11 Ver1.7 Add Start */
    cv_msg_prf_err          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';  --僾儘僼傽僀儖庢摼僄儔乕
    cv_msg_org_prf_name     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00047';  --MO:塩嬈扨埵
/* 2009/08/11 Ver1.7 Add End   */
    --僩乕僋儞
    cv_tkn_order_no         CONSTANT VARCHAR2(20) := 'ORDER_NO';          --揱昜斣崋
    cv_tkn_line_no          CONSTANT VARCHAR2(20) := 'LINE_NUMBER';       --柧嵶斣崋
/* 2009/07/13 Ver1.5 Add End   */
/* 2009/08/11 Ver1.7 Add Start */
    cv_tkn_profile          CONSTANT VARCHAR2(20) := 'PROFILE';           --僾儘僼傽僀儖
/* 2009/08/11 Ver1.7 Add End   */
    cv_cstm_class_base      CONSTANT VARCHAR2(2)  := '1';       -- 屭媞嬫暘:嫆揰
/* 2010/04/15 Ver1.9 Add Start */
    cv_hw_slip_div_yes      CONSTANT VARCHAR2(1)  := '1';       -- EDI庤彂揱昜揱憲嬫暘:揱憲偁傝
/* 2010/04/15 Ver1.9 Add End   */
    cv_cstm_class_customer  CONSTANT VARCHAR2(2)  := '10';      -- 屭媞嬫暘:屭媞
    cv_cstm_class_chain     CONSTANT VARCHAR2(2)  := '18';      -- 屭媞嬫暘:僠僃乕儞揦
    cv_flow_status_entry    CONSTANT VARCHAR2(6)  := 'BOOKED';  -- 僗僥乕僞僗:婰挔嵪傒
--*** 2009/03/24 Ver1.3 MODIFY START ***
--  cn_order_source         CONSTANT NUMBER       := 0;         -- 庴拲僜乕僗ID:夋柺擖椡
--  cn_order_type           CONSTANT NUMBER       := 1068;      -- 庴拲僞僀僾ID:捠忢庴拲
--  cn_line_type            CONSTANT NUMBER       := 1054;      -- 柧嵶僞僀僾ID:捠忢弌壸
    cv_xxcos_appl_short_nm  CONSTANT VARCHAR2(5)  := 'XXCOS';   -- 斕暔抁弅傾僾儕柤
    cv_xxcos1_order_edi_common                                  -- EDI庤擖椡摿掕儅僗僞
                            CONSTANT VARCHAR2(23) := 'XXCOS1_ORDER_EDI_COMMON';
--*** 2009/03/24 Ver1.3 MODIFY END   ***
    cv_tukzik_div_tuk       CONSTANT VARCHAR2(2)  := '11';      -- 捠夁嵼屔宆嬫暘:僙儞僞乕擺昳(捠夁宆丒庴拲)
    cv_tukzik_div_zik       CONSTANT VARCHAR2(2)  := '12';      -- 捠夁嵼屔宆嬫暘:僙儞僞乕擺昳(嵼屔宆丒庴拲)
    cv_tukzik_div_tnp       CONSTANT VARCHAR2(2)  := '24';      -- 捠夁嵼屔宆嬫暘:揦曑擺昳
    cv_flag_yes             CONSTANT VARCHAR2(1)  := 'Y';       -- 僼儔僌:'Y'
    cv_flag_no              CONSTANT VARCHAR2(1)  := 'N';       -- 僼儔僌:'N'
--************************** 2009/06/19 N.Maeda Mod start *********************************--
--    cv_ras_class_all        CONSTANT VARCHAR2(1)  := '0';       -- 掕斣摿攧嬫暘:ALL
    cv_ras_class_all        CONSTANT VARCHAR2(2)  := '00';      -- 掕斣摿攧嬫暘:ALL
--************************** 2009/06/19 N.Maeda Mod  end  *********************************--
    cv_unit_case            CONSTANT VARCHAR2(2)  := 'CS';      -- 扨埵:働乕僗
    cv_unit_bowl            CONSTANT VARCHAR2(2)  := 'BL';      -- 扨埵:儃乕儖
/* 2009/07/13 Ver1.5 Del Start */
--    cv_sale_class_error     CONSTANT VARCHAR2(1)  := '1';       -- 攧忋嬫暘崿嵼僄儔乕
--    cv_outbound_error       CONSTANT VARCHAR2(1)  := '2';       -- OUTBOUND壜斲僄儔乕
/* 2009/07/13 Ver1.5 Del End   */
    cv_medium_class         CONSTANT VARCHAR2(2)  := '01';      -- 攠懱嬫暘
    cv_data_type_code       CONSTANT VARCHAR2(2)  := '11';      -- 僨乕僞庬僐乕僪
    cv_creation_class       CONSTANT VARCHAR2(2)  := '01';      -- 嶌惉尦嬫暘
    cv_file_no              CONSTANT VARCHAR2(2)  := '00';      -- 僼傽僀儖俶倧
    cv_stockout_class       CONSTANT VARCHAR2(2)  := '00';      -- 寚昳嬫暘
    cv_user_env_lang        CONSTANT VARCHAR2(4)  := 'lang';    -- 娐嫬曄悢:尵岅
    cv_ltype_sale_class     CONSTANT VARCHAR2(25) := 'XXCOS1_SALE_CLASS';  -- 嶲徠僞僀僾丒僐乕僪:攧忋嬫暘
    cv_tbl_name_head        CONSTANT VARCHAR2(13) := 'EDI僿僢僟忣曬';      -- 僥乕僽儖柤:EDI僿僢僟忣曬
    cv_tbl_name_line        CONSTANT VARCHAR2(11) := 'EDI柧嵶忣曬';        -- 僥乕僽儖柤:EDI柧嵶忣曬
/* 2009/08/11 Ver1.7 Add Start */
    --僾儘僼傽僀儖柤徧
    ct_prof_org_id                CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'ORG_ID'; --MO:塩嬈扨埵
/* 2009/08/11 Ver1.7 Add Start */
--
    -- 僿僢僟僥乕僽儖
    TYPE order_head_rtype IS RECORD (
         acquisition_flag       xxcos_edi_headers.order_connection_number%TYPE   -- EDI僿僢僟忣曬.庴拲娭楢斣崋
        ,header_id              oe_order_headers_all.header_id%TYPE              -- 庴拲僿僢僟.庴拲僿僢僟ID
        ,ordered_date           oe_order_headers_all.ordered_date%TYPE           -- 庴拲僿僢僟.庴拲擔
        ,request_date           oe_order_headers_all.request_date%TYPE           -- 庴拲僿僢僟.梫媮擔
        ,cust_po_number         oe_order_headers_all.cust_po_number%TYPE         -- 庴拲僿僢僟.屭媞敪拲
        ,order_number           oe_order_headers_all.order_number%TYPE           -- 庴拲僿僢僟.庴拲斣崋
        ,orig_sys_document_ref  oe_order_headers_all.orig_sys_document_ref%TYPE  -- 庴拲僿僢僟.奜晹僔僗僥儉庴拲斣崋
        ,price_list_id          oe_order_headers_all.price_list_id%TYPE          -- 庴拲僿僢僟.壙奿昞ID
/* 2009/07/14 Ver1.6 Add Start */
        ,invoice_class          oe_order_headers_all.attribute5%TYPE             -- 庴拲僿僢僟.DFF5(揱昜嬫暘)
        ,classification_code    oe_order_headers_all.attribute20%TYPE            -- 庴拲僿僢僟.DFF20(暘椶嬫暘)
/* 2009/07/14 Ver1.6 Add End   */
        ,account_number         hz_cust_accounts.account_number%TYPE             -- 屭媞儅僗僞(屭媞).屭媞僐乕僪
        ,customer_name          hz_parties.party_name%TYPE                       -- 僷乕僥傿(屭媞).柤徧
        ,customer_name_alt      hz_parties.organization_name_phonetic%TYPE       -- 僷乕僥傿(屭媞).柤徧(僇僫)
        ,base_code              xxcmm_cust_accounts.delivery_base_code%TYPE      -- 屭媞捛壛(屭媞).擺昳嫆揰僐乕僪
        ,store_code             xxcmm_cust_accounts.store_code%TYPE              -- 屭媞捛壛(屭媞).揦曑僐乕僪
        ,cust_store_name        xxcmm_cust_accounts.cust_store_name%TYPE         -- 屭媞捛壛(屭媞).屭媞揦曑柤徧
        ,edi_district_code      xxcmm_cust_accounts.edi_district_code%TYPE       -- 屭媞捛壛(屭媞).EDI抧嬫僐乕僪(EDI)
        ,edi_district_name      xxcmm_cust_accounts.edi_district_name%TYPE       -- 屭媞捛壛(屭媞).EDI抧嬫柤(EDI)
        ,edi_district_kana      xxcmm_cust_accounts.edi_district_kana%TYPE       -- 屭媞捛壛(屭媞).EDI抧嬫柤僇僫(EDI)
        ,edi_chain_code         xxcmm_cust_accounts.edi_chain_code%TYPE          -- 屭媞捛壛(联拜).EDI僠僃乕儞揦僐乕僪
        ,edi_chain_name         hz_parties.party_name%TYPE                       -- 僷乕僥傿(联拜).柤徧
        ,edi_chain_name_alt     hz_parties.organization_name_phonetic%TYPE       -- 僷乕僥傿(联拜).柤徧(僇僫)
        ,base_name              hz_parties.party_name%TYPE                       -- 僷乕僥傿(嫆揰).柤徧
        ,base_name_alt          hz_parties.organization_name_phonetic%TYPE       -- 僷乕僥傿(嫆揰).柤徧(僇僫)
    );
    -- 柧嵶僥乕僽儖
    TYPE order_line_rtype IS RECORD (
         line_number         oe_order_lines_all.line_number%TYPE         -- 庴拲柧嵶.峴斣崋
        ,ordered_item        oe_order_lines_all.ordered_item%TYPE        -- 庴拲柧嵶.庴拲昳栚
        ,order_quantity_uom  oe_order_lines_all.order_quantity_uom%TYPE  -- 庴拲柧嵶.庴拲扨埵
        ,ordered_quantity    oe_order_lines_all.ordered_quantity%TYPE    -- 庴拲柧嵶.庴拲悢検
        ,orig_sys_line_refw  oe_order_lines_all.orig_sys_line_ref%TYPE   -- 庴拲柧嵶.奜晹僔僗僥儉庴拲柧嵶斣崋
        ,unit_selling_price  oe_order_lines_all.unit_selling_price%TYPE  -- 斕攧扨壙
/* 2010/03/09 Ver1.8 Add Start */
        ,selling_price       xxcos_edi_lines.selling_price%TYPE          -- 攧扨壙
        ,order_price_amt     xxcos_edi_lines.order_price_amt%TYPE        -- 攧壙嬥妟(敪拲)
/* 2010/03/09 Ver1.8 Add  End  */
        ,num_of_case         ic_item_mst_b.attribute11%TYPE              -- OPM昳栚.DFF11(働乕僗擖悢)
        ,jan_code            ic_item_mst_b.attribute21%TYPE              -- OPM昳栚.DFF21(JAN僐乕僪)
        ,itf_code            ic_item_mst_b.attribute22%TYPE              -- OPM昳栚.DFF22(ITF僐乕僪)
        ,item_code           mtl_system_items_b.segment1%TYPE            -- Disc昳栚.昳柤僐乕僪
        ,num_of_bowl         xxcmm_system_items_b.bowl_inc_num%TYPE      -- Disc昳栚傾僪僆儞.儃乕儖擖悢
        ,regular_sale_class  fnd_lookup_values.attribute8%TYPE           -- 僋僀僢僋僐乕僪.DFF8(掕斣摿攧嬫暘)
        ,outbound_flag       fnd_lookup_values.attribute10%TYPE          -- 僋僀僢僋僐乕僪.DFF10(OUTBOUND壜斲)
/* 2009/03/03 Ver1.1 Add Start */
        ,item_name           xxcmn_item_mst_b.item_name%TYPE             -- OPM昳栚傾僪僆儞.惓幃柤
        ,item_name_alt       xxcmn_item_mst_b.item_name_alt%TYPE         -- OPM昳栚傾僪僆儞.僇僫柤
/* 2009/03/03 Ver1.1 Add  End  */
/* 2009/04/24 Ver1.3 Add Start */
        ,edi_rep_uom         mtl_units_of_measure_tl.attribute1%TYPE     -- EDI丒挔昜梡扨埵
/* 2009/04/24 Ver1.3 Add End   */
    );
    -- 揱昜寁僥乕僽儖
    TYPE invoice_sum_rtype IS RECORD (
         invoice_number               VARCHAR2(50)      -- 揱昜斣崋
        ,invoice_indv_order_qty       NUMBER DEFAULT 0  -- 敪拲悢検(僶儔)
        ,invoice_case_order_qty       NUMBER DEFAULT 0  -- 敪拲悢検(働乕僗)
        ,invoice_ball_order_qty       NUMBER DEFAULT 0  -- 敪拲悢検(儃乕儖)
        ,invoice_sum_order_qty        NUMBER DEFAULT 0  -- 敪拲悢検(崌寁丄僶儔)
        ,invoice_indv_shipping_qty    NUMBER DEFAULT 0  -- 弌壸悢検(僶儔)
        ,invoice_case_shipping_qty    NUMBER DEFAULT 0  -- 弌壸悢検(働乕僗)
        ,invoice_ball_shipping_qty    NUMBER DEFAULT 0  -- 弌壸悢検(儃乕儖)
        ,invoice_pallet_shipping_qty  NUMBER DEFAULT 0  -- 弌壸悢検(僷儗僢僩)
        ,invoice_sum_shipping_qty     NUMBER DEFAULT 0  -- 弌壸悢検(崌寁丄僶儔)
        ,invoice_indv_stockout_qty    NUMBER DEFAULT 0  -- 寚昳悢検(僶儔)
        ,invoice_case_stockout_qty    NUMBER DEFAULT 0  -- 寚昳悢検(働乕僗)
        ,invoice_ball_stockout_qty    NUMBER DEFAULT 0  -- 寚昳悢検(儃乕儖)
        ,invoice_sum_stockout_qty     NUMBER DEFAULT 0  -- 寚昳悢検(崌寁丄僶儔)
        ,invoice_case_qty             NUMBER DEFAULT 0  -- 働乕僗屄岥悢
        ,invoice_fold_container_qty   NUMBER DEFAULT 0  -- 僆儕僐儞(僶儔)屄岥悢
        ,invoice_order_cost_amt       NUMBER DEFAULT 0  -- 尨壙嬥妟(敪拲)
        ,invoice_shipping_cost_amt    NUMBER DEFAULT 0  -- 尨壙嬥妟(弌壸)
        ,invoice_stockout_cost_amt    NUMBER DEFAULT 0  -- 尨壙嬥妟(寚昳)
        ,invoice_order_price_amt      NUMBER DEFAULT 0  -- 攧壙嬥妟(敪拲)
        ,invoice_shipping_price_amt   NUMBER DEFAULT 0  -- 攧壙嬥妟(弌壸)
        ,invoice_stockout_price_amt   NUMBER DEFAULT 0  -- 攧壙嬥妟(寚昳)
    );
    -- 僿僢僟曇廤僥乕僽儖
    TYPE head_edit_rtype IS RECORD (
         edi_header_info_id  xxcos_edi_headers.edi_header_info_id%TYPE  -- EDI僿僢僟忣曬ID
        ,ar_sale_class       xxcos_edi_headers.ar_sale_class%TYPE       -- 摿攧嬫暘
    );
--
    -- ===============================
    -- 儘乕僇儖曄悢
    -- ===============================
    -- PL/SQL昞宆
    TYPE order_head_ttype   IS TABLE OF order_head_rtype   INDEX BY BINARY_INTEGER;  -- 僿僢僟僥乕僽儖
    TYPE order_line_ttype   IS TABLE OF order_line_rtype   INDEX BY BINARY_INTEGER;  -- 柧嵶僥乕僽儖
    TYPE invoice_sum_ttype  IS TABLE OF invoice_sum_rtype  INDEX BY BINARY_INTEGER;  -- 揱昜寁僥乕僽儖
    TYPE head_edit_ttype    IS TABLE OF head_edit_rtype    INDEX BY BINARY_INTEGER;  -- 僿僢僟曇廤僥乕僽儖
--
    -- PL/SQL昞
    lt_head_tab          order_head_ttype;     -- 僿僢僟僥乕僽儖
    lt_line_tab          order_line_ttype;     -- 柧嵶僥乕僽儖
    lt_invoice_tab       invoice_sum_ttype;    -- 揱昜寁僥乕僽儖
    lt_head_edit_tab     head_edit_ttype;      -- 僿僢僟曇廤僥乕僽儖
--
    ln_head_cnt          NUMBER;           -- 僿僢僟僥乕僽儖梡僇僂儞僞
    ln_line_cnt          NUMBER;           -- 柧嵶僥乕僽儖梡僇僂儞僞
    ln_invoice_cnt       NUMBER;           -- 揱昜寁僥乕僽儖梡僇僂儞僞
    lv_sale_class_check  VARCHAR2(1);      -- 攧忋嬫暘懳徾
    ln_line_info_id      NUMBER;           -- EDI柧嵶忣曬ID
    ln_user_id           NUMBER;           -- 儐乕僓ID
    ln_login_id          NUMBER;           -- 儘僌僀儞ID
    ld_sysdate           DATE;             -- 僔僗僥儉擔晅
    ln_case_qty          NUMBER;           -- 働乕僗悢
    ln_bowl_qty          NUMBER;           -- 儃乕儖悢
    ln_indv_qty          NUMBER;           -- 僶儔悢
    lv_language          VARCHAR2(10);     -- 尵岅
--
    lv_product_code2     VARCHAR2(16);     -- 彜昳僐乕僪俀
    lv_jan_code          VARCHAR2(13);     -- JAN僐乕僪
    lv_case_jan_code     VARCHAR2(13);     -- 働乕僗JAN僐乕僪
    lv_table_name        VARCHAR2(15);     -- 僥乕僽儖柤
    lv_errbuf            VARCHAR2(5000);   -- 僄儔乕丒儊僢僙乕僕僄儔乕
    lv_retcode           VARCHAR2(1);      -- 儕僞乕儞丒僐乕僪
    lv_errmsg            VARCHAR2(5000);   -- 儐乕僓乕丒僄儔乕丒儊僢僙乕僕
    lv_ret_normal        VARCHAR2(1);      -- 儕僞乕儞丒僐乕僪:惓忢
/* 2009/08/11 Ver1.7 Add Start */
    ln_org_id            NUMBER;           -- ORG_ID
    lv_msg_string        VARCHAR2(5000);   -- 儊僢僙乕僕梡暥帤楍奿擺曄悢
    ld_shop_delivery_date_from DATE;       -- 堷悢TRUNC梡(揦曑擺昳擔Form)
    ld_shop_delivery_date_to   DATE;       -- 堷悢TRUNC梡(揦曑擺昳擔To)
    ld_center_delivery_date    DATE;       -- 堷悢TRUNC梡(僙儞僞乕擺昳擔)
/* 2009/08/11 Ver1.7 Add End   */
--
    -- ================
    -- 儐乕僓乕掕媊椺奜
    -- ================
    sale_class_expt    EXCEPTION;  -- 攧忋嬫暘偑崿嵼偟偨応崌偺椺奜
    outbound_expt      EXCEPTION;  -- OUTBOUND壜斲偑'N'偺応崌偺椺奜
    table_insert_expt  EXCEPTION;  -- 憓擖偵幐攕偟偨応崌偺椺奜
    item_conv_expt     EXCEPTION;  -- 昳栚曄姺偺椺奜
/* 2009/08/11 Ver1.7 Add Start */
    org_id_expt        EXCEPTION;  -- ORG_ID庢摼椺奜
/* 2009/08/11 Ver1.7 Add End   */
--
    PRAGMA EXCEPTION_INIT(sale_class_expt,   -20000);
    PRAGMA EXCEPTION_INIT(outbound_expt,     -20001);
    PRAGMA EXCEPTION_INIT(table_insert_expt, -20002);
    PRAGMA EXCEPTION_INIT(item_conv_expt,    -20003);
/* 2009/08/11 Ver1.7 Add Start */
    PRAGMA EXCEPTION_INIT(org_id_expt,       -20004);
/* 2009/08/11 Ver1.7 Add End   */
--
  BEGIN
--
--##################  屌掕僗僥乕僞僗弶婜壔晹 START   ###################
--
    ov_retcode := xxccp_common_pkg.set_status_normal;
--
--###########################  屌掕晹 END   ############################
--
    ln_user_id     := FND_GLOBAL.USER_ID;                  -- 儐乕僓ID
    ln_login_id    := FND_GLOBAL.LOGIN_ID;                 -- 儘僌僀儞ID
    ld_sysdate     := TRUNC(SYSDATE);                      -- 僔僗僥儉擔晅
    lv_language    := USERENV(cv_user_env_lang);           -- 尵岅
    lv_ret_normal  := xxccp_common_pkg.set_status_normal;  -- 儕僞乕儞僐乕僪:惓忢
/* 2009/08/11 Ver1.7 Add Start */
    ld_shop_delivery_date_from  := TRUNC(id_shop_delivery_date_from);  -- 堷悢傪TRUNC(揦曑擺昳擔Form)
    ld_shop_delivery_date_to    := TRUNC(id_shop_delivery_date_to);    -- 堷悢傪TRUNC(揦曑擺昳擔To)
    ld_center_delivery_date     := TRUNC(id_center_delivery_date);     -- 堷悢傪TRUNC(僙儞僞乕擺昳擔)
--
    ln_org_id      := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_org_id ) ); -- ORG_ID
--
    --ORG_ID偑庢摼偱偒側偄応崌偼僄儔乕
    IF ( ln_org_id IS NULL ) THEN
      lv_msg_string := xxccp_common_pkg.get_msg(
                          iv_application => cv_xxcos_appl_short_nm
                         ,iv_name        => cv_msg_org_prf_name
                       );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_appl_short_nm
                     ,iv_name         => cv_msg_prf_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => lv_msg_string
                   );
      RAISE org_id_expt;
    END IF;
/* 2009/08/11 Ver1.7 Add End   */
--
    -- 僿僢僟忣曬撉崬
    SELECT
/* 2009/08/11 Ver1.7 Add Start */
       /*+
          LEADING(xca2)
          USE_NL(xca1)
       */
/* 2009/08/11 Ver1.7 Add End   */
       xeh.order_connection_number     -- EDI僿僢僟忣曬.庴拲娭楢斣崋
      ,ooha.header_id                  -- 庴拲僿僢僟.庴拲僿僢僟ID
      ,ooha.ordered_date               -- 庴拲僿僢僟.庴拲擔
      ,ooha.request_date               -- 庴拲僿僢僟.梫媮擔
      ,ooha.cust_po_number             -- 庴拲僿僢僟.屭媞敪拲
      ,ooha.order_number               -- 庴拲僿僢僟.庴拲斣崋
      ,ooha.orig_sys_document_ref      -- 庴拲僿僢僟.奜晹僔僗僥儉庴拲斣崋
      ,ooha.price_list_id              -- 庴拲僿僢僟.壙奿昞ID
/* 2009/07/14 Ver1.6 Add Start */
      ,ooha.attribute5                 -- 庴拲僿僢僟.DFF5(揱昜嬫暘)
      ,ooha.attribute20                -- 庴拲僿僢僟.DFF20(暘椶嬫暘)
/* 2009/07/14 Ver1.6 Add End   */
      ,hca1.account_number             -- 屭媞儅僗僞(屭媞).屭媞僐乕僪
      ,hp1.party_name                  -- 僷乕僥傿(屭媞).柤徧
      ,hp1.organization_name_phonetic  -- 僷乕僥傿(屭媞).柤徧(僇僫)
      ,xca1.delivery_base_code         -- 屭媞捛壛(屭媞).擺昳嫆揰僐乕僪
      ,xca1.store_code                 -- 屭媞捛壛(屭媞).揦曑僐乕僪
      ,xca1.cust_store_name            -- 屭媞捛壛(屭媞).屭媞揦曑柤徧
      ,xca1.edi_district_code          -- 屭媞捛壛(屭媞).EDI抧嬫僐乕僪(EDI)
      ,xca1.edi_district_name          -- 屭媞捛壛(屭媞).EDI抧嬫柤(EDI)
      ,xca1.edi_district_kana          -- 屭媞捛壛(屭媞).EDI抧嬫柤僇僫(EDI)
      ,xca2.edi_chain_code             -- 屭媞捛壛(联拜).EDI僠僃乕儞揦僐乕僪
      ,hp2.party_name                  -- 僷乕僥傿(联拜).柤徧
      ,hp2.organization_name_phonetic  -- 僷乕僥傿(联拜).柤徧(僇僫)
      ,hp3.party_name                  -- 僷乕僥傿(嫆揰).柤徧
      ,hp3.organization_name_phonetic  -- 僷乕僥傿(嫆揰).柤徧(僇僫)
     BULK COLLECT INTO lt_head_tab
     FROM oe_order_headers_all  ooha  -- 庴拲僿僢僟
         ,hz_cust_accounts      hca1  -- 屭媞儅僗僞(屭媞)
         ,xxcmm_cust_accounts   xca1  -- 屭媞捛壛(屭媞)
         ,hz_parties            hp1   -- 僷乕僥傿(屭媞)
         ,hz_cust_accounts      hca2  -- 屭媞儅僗僞(联拜)
         ,xxcmm_cust_accounts   xca2  -- 屭媞捛壛(联拜)
         ,hz_parties            hp2   -- 僷乕僥傿(联拜)
         ,hz_cust_accounts      hca3  -- 屭媞儅僗僞(嫆揰)
         ,hz_parties            hp3   -- 僷乕僥傿(嫆揰)
         ,xxcos_edi_headers     xeh   -- EDI僿僢僟忣曬
--*** 2009/03/24 Ver1.3 ADD    START ***
         ,oe_order_sources        oos   -- 庴拲僜乕僗僥乕僽儖
         ,oe_transaction_types_tl ottt  -- 庴拲僞僀僾僥乕僽儖
--*** 2009/03/24 Ver1.3 ADD    END   ***/
     WHERE ooha.sold_to_org_id         =  hca1.cust_account_id            -- 庴拲僿僢僟      亖屭媞儅僗僞(屭媞)
/* 2009/08/11 Ver1.7 Mod Start */
--     AND   hca1.cust_account_id        =  xca1.customer_id                -- 屭媞儅僗僞(屭媞)亖屭媞捛壛(屭媞)
     AND   hca1.account_number         =  xca1.customer_code              -- 屭媞儅僗僞(屭媞)亖屭媞捛壛(屭媞)
/* 2009/08/11 Ver1.7 Mod End   */
     AND   hca1.party_id               =  hp1.party_id                    -- 屭媞儅僗僞(屭媞)亖僷乕僥傿(屭媞)
     AND   xca1.chain_store_code       =  xca2.edi_chain_code             -- 屭媞捛壛(屭媞)  亖屭媞捛壛(联拜)
     AND   hca2.cust_account_id        =  xca2.customer_id                -- 屭媞儅僗僞(联拜)亖屭媞捛壛(联拜)
     AND   hca2.party_id               =  hp2.party_id                    -- 屭媞儅僗僞(联拜)亖僷乕僥傿(联拜)
     AND   xca1.delivery_base_code     =  hca3.account_number             -- 屭媞儅僗僞(屭媞)亖屭媞儅僗僞(嫆揰)
     AND   hca3.party_id               =  hp3.party_id                    -- 屭媞儅僗僞(嫆揰)亖僷乕僥傿(嫆揰)
     AND   ooha.orig_sys_document_ref  =  xeh.order_connection_number(+)  -- 庴拲僿僢僟      亖EDI僿僢僟忣曬
     /* 屭媞嬫暘 */
     AND   hca1.customer_class_code    =  cv_cstm_class_customer   -- 屭媞儅僗僞(屭媞).屭媞嬫暘='10'(屭媞)
     AND   hca2.customer_class_code    =  cv_cstm_class_chain      -- 屭媞儅僗僞(联拜).屭媞嬫暘='18'(联拜揦)
     AND   hca3.customer_class_code    =  cv_cstm_class_base       -- 屭媞儅僗僞(嫆揰).屭媞嬫暘='1'(嫆揰)
/* 2010/04/15 Ver1.9 Add Start */
     /* EDI庤彂揱昜揱憲嬫暘 */ 
     AND   xca2.handwritten_slip_div   =  cv_hw_slip_div_yes       -- 屭媞捛壛(联拜).EDI庤彂揱昜揱憲嬫暘亖'1'(揱憲偁傝)
/* 2010/04/15 Ver1.9 Add End   */
     /* 庴拲僿僢僟拪弌忦審 */
/* 2009/08/11 Ver1.7 Add Start */
     AND   ooha.org_id                 =  ln_org_id              -- ORG_ID亖僾儘僼傽僀儖抣
/* 2009/08/11 Ver1.7 Add End   */
     AND   ooha.flow_status_code       =  cv_flow_status_entry   -- 僗僥乕僞僗  亖婰挔嵪傒
--*** 2009/03/24 Ver1.3 MODIFY START ***
--   AND   ooha.order_source_id        =  cn_order_source        -- 庴拲僜乕僗ID亖夋柺擖椡
--   AND   ooha.order_type_id          =  cn_order_type          -- 庴拲僞僀僾ID亖捠忢庴拲
--
     AND   ooha.order_source_id        =  oos.order_source_id      -- 庴拲僿僢僟.庴拲僜乕僗ID亖庴拲僜乕僗.庴拲僜乕僗ID
     AND   ooha.order_type_id          =  ottt.transaction_type_id -- 庴拲僿僢僟.庴拲僞僀僾ID亖庴拲僞僀僾.庴拲僞僀僾ID
/* 2009/08/11 Ver1.7 Mod Start */
--     AND   ottt.language               =  USERENV('LANG')          -- 庴拲僞僀僾.尵岅亖擔杮岅
     AND   ottt.language               =  lv_language            -- 庴拲僞僀僾.尵岅亖擔杮岅
/* 2009/08/11 Ver1.7 Mod End   */
     AND   EXISTS (
                   SELECT 'X'
/* 2009/08/11 Ver1.7 Mod Start */
--                   FROM (
--                          SELECT
--                            flv.attribute1 AS order_source_name  -- 庴拲僜乕僗
--                           ,flv.attribute2 AS order_h_type_name  -- 庴拲僿僢僟僞僀僾
--                          FROM
--                             fnd_application               fa,
--                             fnd_lookup_types              flt,
--                             fnd_lookup_values             flv
--                           WHERE
--                               fa.application_id           = flt.application_id
--                           AND flt.lookup_type             = flv.lookup_type
--                           AND fa.application_short_name   = cv_xxcos_appl_short_nm
--                           AND flv.lookup_type             = cv_xxcos1_order_edi_common
--                           AND flv.start_date_active      <= TRUNC( ld_sysdate )
--                           AND TRUNC( ld_sysdate )        <= NVL( flv.end_date_active, TRUNC( ld_sysdate ) )
--                           AND flv.enabled_flag            = cv_flag_yes
--                           AND flv.language                = USERENV( 'LANG' )
--                        ) flvs
--                      WHERE
--                          oos.name       = flvs.order_source_name  -- 庴拲僜乕僗丏柤慜亖嶲徠僞僀僾丏庴拲僜乕僗柤
--                      AND ottt.name      = flvs.order_h_type_name  -- 庴拲僞僀僾丏柤慜亖嶲徠僞僀僾丏庴拲僿僢僟僞僀僾柤
                   FROM   fnd_lookup_values  flv
                   WHERE  flv.lookup_type   = cv_xxcos1_order_edi_common
                   AND    ld_sysdate        BETWEEN NVL( flv.start_date_active, ld_sysdate )
                                            AND     NVL( flv.end_date_active, ld_sysdate )
                   AND    flv.enabled_flag  = cv_flag_yes
                   AND    flv.language      = lv_language
                   AND    flv.attribute1    = oos.name
                   AND    flv.attribute2    = ottt.name
/* 2009/08/11 Ver1.7 Mod End   */
                  )
--*** 2009/03/24 Ver1.3 MODIFY END   ***/
     /* 捠夁宆嵼屔嬫暘 */
     AND   xca1.tsukagatazaiko_div     IN ( cv_tukzik_div_tuk    -- 僙儞僞乕擺昳(捠夁宆丒庴拲)
                                          , cv_tukzik_div_zik    -- 僙儞僞乕擺昳(嵼屔宆丒庴拲)
                                          , cv_tukzik_div_tnp )  -- 揦曑擺昳
     /* 僷儔儊乕僞偵傛傞峣傝崬傒 */
/* 2009/08/11 Ver1.7 Mod Start */
--     AND ( xca2.chain_store_code       =  iv_edi_chain_code                  -- EDI僠僃乕儞揦僐乕僪
--     OR    iv_edi_chain_code           IS NULL )
     AND   xca2.edi_chain_code         =  iv_edi_chain_code                  -- EDI僠僃乕儞揦僐乕僪
/* 2009/08/11 Ver1.7 Mod End   */
     AND ( xca1.edi_forward_number     =  iv_edi_forward_number              -- EDI揱憲捛斣
     OR    iv_edi_forward_number       IS NULL )
/* 2009/08/11 Ver1.7 Mod Start */
--     AND ( TRUNC(ooha.request_date)    >= TRUNC(id_shop_delivery_date_from)  -- 揦曑擺昳擔(From)
--     OR    id_shop_delivery_date_from  IS NULL )
--     AND ( TRUNC(ooha.request_date)    <= TRUNC(id_shop_delivery_date_to)    -- 揦曑擺昳擔(To)
--     OR    id_shop_delivery_date_to    IS NULL )
--     AND ( xca1.edi_district_code      =  iv_area_code                       -- 抧嬫僐乕僪
--     OR    iv_area_code                IS NULL )
--     AND ( TRUNC(ooha.request_date)    =  TRUNC(id_center_delivery_date)     -- 僙儞僞乕擺昳擔
--     OR    id_center_delivery_date     IS NULL )
     AND (
           TRUNC(ooha.request_date)    >= ld_shop_delivery_date_from  -- 揦曑擺昳擔(From)
         OR
           ld_shop_delivery_date_from  IS NULL
         )
     AND (
           TRUNC(ooha.request_date)    <= ld_shop_delivery_date_to    -- 揦曑擺昳擔(To)
         OR
           ld_shop_delivery_date_to    IS NULL
         )
     AND (
           xca1.edi_district_code      =  iv_area_code                -- 抧嬫僐乕僪
         OR
           iv_area_code                IS NULL
         )
     AND (
           TRUNC(ooha.request_date)    =  ld_center_delivery_date     -- 僙儞僞乕擺昳擔
         OR
           ld_center_delivery_date     IS NULL
         )
/* 2009/08/11 Ver1.7 Mod End   */
    ;
--
    -- 奩摉僨乕僞側偟
    IF ( lt_head_tab.COUNT = 0 ) THEN
      RETURN;
    END IF;
--
    -- 揱昜寁
    ln_invoice_cnt := 1;
    lt_invoice_tab(ln_invoice_cnt).invoice_number := lt_head_tab(1).cust_po_number;
--
    <<head_proc_loop>>
    FOR ln_head_cnt IN 1 .. lt_head_tab.COUNT LOOP
      -- 僿僢僟曇廤僥乕僽儖弶婜壔
      lt_head_edit_tab(ln_head_cnt).edi_header_info_id := NULL;
--
      -- 庢傝崬傒嵪傒丠
      IF ( lt_head_tab(ln_head_cnt).acquisition_flag IS NULL ) THEN
        lt_line_tab.DELETE;  -- 柧嵶僥乕僽儖僋儕傾
--
        -- 柧嵶忣曬撉崬
        SELECT
          oola.line_number            line_number         -- 庴拲柧嵶.峴斣崋
         ,oola.ordered_item           ordered_item        -- 庴拲柧嵶.庴拲昳栚
         ,oola.order_quantity_uom     order_quantity_uom  -- 庴拲柧嵶.庴拲扨埵
         ,oola.ordered_quantity       ordered_quantity    -- 庴拲柧嵶.庴拲悢検
         ,oola.orig_sys_line_ref      orig_sys_line_refw  -- 庴拲柧嵶.奜晹僔僗僥儉庴拲柧嵶斣崋
         ,oola.unit_selling_price     unit_selling_price  -- 斕攧扨壙
/* 2010/03/09 Ver1.8 Add Start */
         ,TO_NUMBER(oola.attribute10) selling_price       -- 攧扨壙
         ,TO_NUMBER(oola.attribute10)
          * oola.ordered_quantity     order_price_amt     -- 攧壙嬥妟(敪拲)
/* 2010/03/09 Ver1.8 Add  End  */
         ,iimb.attribute11            num_of_case         -- OPM昳栚.DFF11(働乕僗擖悢)
         ,iimb.attribute21            jan_code            -- OPM昳栚.DFF21(JAN僐乕僪)
         ,iimb.attribute22            itf_code            -- OPM昳栚.DFF22(ITF僐乕僪)
         ,msib.segment1               item_code           -- Disc昳栚.昳柤僐乕僪
         ,xsib.bowl_inc_num           num_of_bowl         -- Disc昳栚傾僪僆儞.儃乕儖擖悢
         ,flv.attribute8              regular_sale_class  -- 僋僀僢僋僐乕僪.DFF8(掕斣摿攧嬫暘)
         ,flv.attribute10             outbound_flag       -- 僋僀僢僋僐乕僪.DFF10(OUTBOUND壜斲)
/* 2009/03/03 Ver1.1 Add Start */
         ,ximb.item_name              item_name           -- OPM昳栚傾僪僆儞.惓幃柤
         ,ximb.item_name_alt          item_name_alt       -- OPM昳栚傾僪僆儞.僇僫柤
/* 2009/03/03 Ver1.1 Add  End  */
/* 2009/04/24 Ver1.3 Add Start */
         ,muom.attribute1             edi_rep_uom         -- EDI丒挔昜梡扨埵
/* 2009/04/24 Ver1.3 Add End   */
        BULK COLLECT INTO lt_line_tab
        FROM oe_order_lines_all    oola  -- 庴拲柧嵶
            ,ic_item_mst_b         iimb  -- OPM昳栚儅僗僞
            ,xxcmn_item_mst_b      ximb  -- OPM昳栚傾僪僆儞
            ,mtl_system_items_b    msib  -- Disc昳栚
            ,xxcmm_system_items_b  xsib  -- Disc昳栚傾僪僆儞
            ,fnd_lookup_values     flv   -- 僋僀僢僋僐乕僪
--*** 2009/03/24 Ver1.3 ADD    START ***/
            ,oe_transaction_types_tl ottt  -- 庴拲僞僀僾僥乕僽儖
--*** 2009/03/24 Ver1.3 ADD    END   ***/
/* 2009/04/24 Ver1.3 Add Start */
            ,mtl_units_of_measure_tl muom  -- 扨埵儅僗僞
/* 2009/04/24 Ver1.3 Add End   */
        WHERE oola.header_id            = lt_head_tab(ln_head_cnt).header_id
        AND   oola.ordered_item         = iimb.item_no
        AND   iimb.item_id              = ximb.item_id
        AND   ximb.start_date_active   <= ld_sysdate
        AND   ximb.end_date_active     >= ld_sysdate
        AND   oola.ordered_item         = msib.segment1
        AND   msib.organization_id      = in_organization_id
        AND   msib.segment1             = xsib.item_code
        AND   oola.attribute5           = flv.lookup_code(+)
        AND   flv.lookup_type(+)        = cv_ltype_sale_class
        AND   flv.start_date_active(+) <= ld_sysdate
        AND ( flv.end_date_active      >= ld_sysdate
        OR    flv.end_date_active      IS NULL )
        AND   flv.enabled_flag(+)       = cv_flag_yes
        AND   flv.language(+)           = lv_language
--*** 2009/03/24 Ver1.3 MODIFY START ***
--      AND   oola.line_type_ID         = cn_line_type
        AND   oola.line_type_id         = ottt.transaction_type_id -- 庴拲僿僢僟.庴拲僞僀僾ID亖庴拲僞僀僾.庴拲僞僀僾ID
/* 2009/08/11 Ver1.7 Mod Start */
--        AND   ottt.language             = USERENV('LANG')          -- 庴拲僞僀僾.尵岅亖擔杮岅
        AND   ottt.language             = lv_language              -- 庴拲僞僀僾.尵岅亖擔杮岅
/* 2009/08/11 Ver1.7 Mod End   */
        AND   EXISTS (
                      SELECT 'X'
/* 2009/08/11 Ver1.7 Mod Start */
--                      FROM (
--                             SELECT
--                               flv.attribute3 AS order_l_type_name -- 庴拲柧嵶僞僀僾
--                             FROM
--                                fnd_application               fa,
--                                fnd_lookup_types              flt,
--                                fnd_lookup_values             flv
--                              WHERE
--                                  fa.application_id           = flt.application_id
--                              AND flt.lookup_type             = flv.lookup_type
--                              AND fa.application_short_name   = cv_xxcos_appl_short_nm
--                              AND flv.lookup_type             = cv_xxcos1_order_edi_common
--                              AND flv.start_date_active      <= TRUNC( ld_sysdate )
--                              AND TRUNC( ld_sysdate )        <= NVL( flv.end_date_active, TRUNC( ld_sysdate ) )
--                              AND flv.enabled_flag            = cv_flag_yes
--                              AND flv.language                = USERENV( 'LANG' )
--                           ) flvs
--                         WHERE
--                             ottt.name      = flvs.order_l_type_name  -- 庴拲僞僀僾丏柤慜亖嶲徠僞僀僾丏庴拲柧嵶僞僀僾柤
                      FROM   fnd_lookup_values  flv
                      WHERE  flv.lookup_type   = cv_xxcos1_order_edi_common
                      AND    ld_sysdate        BETWEEN NVL( flv.start_date_active, ld_sysdate )
                                               AND     NVL( flv.end_date_active, ld_sysdate )
                      AND    flv.enabled_flag  = cv_flag_yes
                      AND    flv.language      = lv_language
                      AND    flv.attribute3    = ottt.name
/* 2009/08/11 Ver1.7 Mod End   */
                     )
--*** 2009/03/24 Ver1.3 MODIFY END   ***
/* 2009/04/24 Ver1.3 Add Start */
        AND   oola.order_quantity_uom   = muom.uom_code            -- 庴拲柧嵶.庴拲扨埵亖扨埵儅僗僞.扨埵僐乕僪
/* 2009/08/11 Ver1.7 Mod Start */
--        AND   muom.language             = USERENV('LANG')          -- 扨埵儅僗僞.尵岅亖擔杮岅
        AND   muom.language             = lv_language          -- 扨埵儅僗僞.尵岅亖擔杮岅
/* 2009/08/11 Ver1.7 Mod End   */
/* 2009/04/24 Ver1.3 Add End   */
        ;
--
        -- 奩摉柧嵶偁傝丠
        IF ( lt_line_tab.COUNT <> 0 ) THEN
          -- 庴拲柧嵶忣曬僠僃僢僋
          <<line_check_loop>>
          FOR ln_line_cnt IN 1 .. lt_line_tab.COUNT LOOP
            -- 掕斣攧忋嬫暘偑(1)偲(n)偱堎側傞応崌丄僄儔乕
            IF ( lt_line_tab(1).regular_sale_class <> lt_line_tab(ln_line_cnt).regular_sale_class ) THEN
/* 2009/07/13 Ver1.5 Add Start */
              lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application     => cv_xxcos_appl_short_nm
                              ,iv_name            => cv_msg_sales_class
                              ,iv_token_name1     => cv_tkn_order_no
                              ,iv_token_value1    => lt_head_tab(ln_head_cnt).cust_po_number
                              );
/* 2009/07/13 Ver1.5 Add End   */
              RAISE sale_class_expt;
            END IF;
            -- OUTBOUD壜斲偑'N'偺応崌丄僄儔乕
            IF ( lt_line_tab(ln_line_cnt).outbound_flag = cv_flag_no ) THEN
/* 2009/07/13 Ver1.5 Add Start */
              lv_errmsg  := xxccp_common_pkg.get_msg(
                               iv_application     => cv_xxcos_appl_short_nm
                              ,iv_name            => cv_msg_not_outbound
                              ,iv_token_name1     => cv_tkn_order_no
                              ,iv_token_value1    => lt_head_tab(ln_head_cnt).cust_po_number
                              ,iv_token_name2     => cv_tkn_line_no
                              ,iv_token_value2    => TO_CHAR( lt_line_tab(ln_line_cnt).line_number )
                              );
/* 2009/07/13 Ver1.5 Add End   */
              RAISE outbound_expt;
            END IF;
          END LOOP line_check_loop;
--
          -- 僷儔儊乕僞.掕斣摿攧嬫暘亖枹愝掕 or ALL
          IF ( iv_regular_ar_sale_class IS NULL )
          OR ( iv_regular_ar_sale_class = cv_ras_class_all )
          THEN
            lv_sale_class_check := cv_flag_yes;      -- 懳徾
          ELSE
            -- 僷儔儊乕僞.掕斣摿攧嬫暘亖庴拲柧嵶.掕斣摿攧嬫暘
            IF ( iv_regular_ar_sale_class = lt_line_tab(1).regular_sale_class ) THEN
              lv_sale_class_check := cv_flag_yes;    -- 懳徾
            ELSE
              lv_sale_class_check := cv_flag_no;     -- 懳徾奜
            END IF;
          END IF;
--
          -- 攧忋嬫暘懳徾丠
          IF ( lv_sale_class_check = cv_flag_yes ) THEN
            <<line_insert_loop>>
            FOR ln_line_cnt IN 1 .. lt_line_tab.COUNT LOOP
              -- 揱昜寁
              IF ( lt_invoice_tab(ln_invoice_cnt).invoice_number <> lt_head_tab(ln_head_cnt).cust_po_number ) THEN
                ln_invoice_cnt := ln_invoice_cnt + 1;
                lt_invoice_tab(ln_invoice_cnt).invoice_number := lt_head_tab(ln_head_cnt).cust_po_number;
              END IF;
--
              ln_case_qty := 0;  -- 働乕僗悢
              ln_bowl_qty := 0;  -- 儃乕儖悢
              ln_indv_qty := 0;  -- 僶儔悢
--
              CASE lt_line_tab(ln_line_cnt).order_quantity_uom
                WHEN cv_unit_case THEN  -- 働乕僗
                  ln_case_qty := lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- 弌壸悢検(働乕僗)
                  lt_invoice_tab(ln_invoice_cnt).invoice_case_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_case_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- 弌壸悢検(崌寁丄僶儔)
                  lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity
                     * TO_NUMBER( lt_line_tab(ln_line_cnt).num_of_case );
                WHEN cv_unit_bowl THEN  -- 儃乕儖
                  ln_bowl_qty := lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- 弌壸悢検(儃乕儖)
                  lt_invoice_tab(ln_invoice_cnt).invoice_ball_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_ball_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- 弌壸悢検(崌寁丄僶儔)
                  lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity
                     * lt_line_tab(ln_line_cnt).num_of_bowl;
                ELSE                    -- 僶儔
                  ln_indv_qty := lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- 弌壸悢検(僶儔)
                  lt_invoice_tab(ln_invoice_cnt).invoice_indv_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_indv_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity;
                  -- 弌壸悢検(崌寁丄僶儔)
                  lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                    := lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty
                     + lt_line_tab(ln_line_cnt).ordered_quantity;
              END CASE;
--
              IF ( lt_head_edit_tab(ln_head_cnt).edi_header_info_id IS NULL ) THEN
                -- 僿僢僟ID嵦斣
                SELECT xxcos.xxcos_edi_headers_s01.NEXTVAL
                INTO   lt_head_edit_tab(ln_head_cnt).edi_header_info_id
                FROM   dual;
                -- 摿攧嬫暘
                lt_head_edit_tab(ln_head_cnt).ar_sale_class := lt_line_tab(1).regular_sale_class;
              END IF;
--
              -- 柧嵶ID嵦斣
              SELECT xxcos.xxcos_edi_lines_s01.NEXTVAL
              INTO   ln_line_info_id
              FROM   dual;
--
              -- 昳栚曄姺(EBS仺EDI)
              xxcos_common2_pkg.conv_edi_item_code(
                   lt_head_tab(ln_head_cnt).edi_chain_code      -- EDI僠僃乕儞揦僐乕僪
                 , lt_line_tab(ln_line_cnt).ordered_item        -- 昳栚僐乕僪
                 , in_organization_id                           -- 嵼屔慻怐ID
                 , lt_line_tab(ln_line_cnt).order_quantity_uom  -- 扨埵僐乕僪
                 , lv_product_code2                             -- 彜昳僐乕僪俀
                 , lv_jan_code                                  -- JAN僐乕僪
                 , lv_case_jan_code                             -- 働乕僗JAN僐乕僪
                 , lv_errbuf                                    -- 僄儔乕丒儊僢僙乕僕僄儔乕
                 , lv_retcode                                   -- 儕僞乕儞丒僐乕僪
                 , lv_errmsg                                    -- 儐乕僓乕丒僄儔乕丒儊僢僙乕僕
              );
              -- 儕僞乕儞僐乕僪偑惓忢偱側偄応崌
              IF ( lv_retcode <> lv_ret_normal ) THEN
                ov_errbuf  := cv_prg_name || lv_errbuf;
                ov_errmsg  := lv_errmsg;
                RAISE item_conv_expt;
              END IF;
--
              -- EDI柧嵶忣曬僥乕僽儖憓擖
              BEGIN
                INSERT INTO xxcos_edi_lines
                (
                  edi_line_info_id              -- EDI柧嵶忣曬ID
                 ,edi_header_info_id            -- EDI僿僢僟忣曬ID
                 ,line_no                       -- 峴俶倧
                 ,stockout_class                -- 寚昳嬫暘
                 ,stockout_reason               -- 寚昳棟桼
                 ,product_code_itouen           -- 彜昳僐乕僪(埳摗墍)
                 ,product_code1                 -- 彜昳僐乕僪侾
                 ,product_code2                 -- 彜昳僐乕僪俀
                 ,jan_code                      -- 俰俙俶僐乕僪
                 ,itf_code                      -- 俬俿俥僐乕僪
                 ,extension_itf_code            -- 撪敔俬俿俥僐乕僪
                 ,case_product_code             -- 働乕僗彜昳僐乕僪
                 ,ball_product_code             -- 儃乕儖彜昳僐乕僪
                 ,product_code_item_type        -- 彜昳僐乕僪昳庬
                 ,prod_class                    -- 彜昳嬫暘
                 ,product_name                  -- 彜昳柤(娍帤)
                 ,product_name1_alt             -- 彜昳柤侾(僇僫)
                 ,product_name2_alt             -- 彜昳柤俀(僇僫)
                 ,item_standard1                -- 婯奿侾
                 ,item_standard2                -- 婯奿俀
                 ,qty_in_case                   -- 擖悢
                 ,num_of_cases                  -- 働乕僗擖悢
                 ,num_of_ball                   -- 儃乕儖擖悢
                 ,item_color                    -- 怓
                 ,item_size                     -- 僒僀僘
                 ,expiration_date               -- 徿枴婜尷擔
                 ,product_date                  -- 惢憿擔
                 ,order_uom_qty                 -- 敪拲扨埵悢
                 ,shipping_uom_qty              -- 弌壸扨埵悢
                 ,packing_uom_qty               -- 崼曪扨埵悢
                 ,deal_code                     -- 堷崌
                 ,deal_class                    -- 堷崌嬫暘
                 ,collation_code                -- 徠崌
                 ,uom_code                      -- 扨埵
                 ,unit_price_class              -- 扨壙嬫暘
                 ,parent_packing_number         -- 恊崼曪斣崋
                 ,packing_number                -- 崼曪斣崋
                 ,product_group_code            -- 彜昳孮僐乕僪
                 ,case_dismantle_flag           -- 働乕僗夝懱晄壜僼儔僌
                 ,case_class                    -- 働乕僗嬫暘
                 ,indv_order_qty                -- 敪拲悢検(僶儔)
                 ,case_order_qty                -- 敪拲悢検(働乕僗)
                 ,ball_order_qty                -- 敪拲悢検(儃乕儖)
                 ,sum_order_qty                 -- 敪拲悢検(崌寁丄僶儔)
                 ,indv_shipping_qty             -- 弌壸悢検(僶儔)
                 ,case_shipping_qty             -- 弌壸悢検(働乕僗)
                 ,ball_shipping_qty             -- 弌壸悢検(儃乕儖)
                 ,pallet_shipping_qty           -- 弌壸悢検(僷儗僢僩)
                 ,sum_shipping_qty              -- 弌壸悢検(崌寁丄僶儔)
                 ,indv_stockout_qty             -- 寚昳悢検(僶儔)
                 ,case_stockout_qty             -- 寚昳悢検(働乕僗)
                 ,ball_stockout_qty             -- 寚昳悢検(儃乕儖)
                 ,sum_stockout_qty              -- 寚昳悢検(崌寁丄僶儔)
                 ,case_qty                      -- 働乕僗屄岥悢
                 ,fold_container_indv_qty       -- 僆儕僐儞(僶儔)屄岥悢
                 ,order_unit_price              -- 尨扨壙(敪拲)
                 ,shipping_unit_price           -- 尨扨壙(弌壸)
                 ,order_cost_amt                -- 尨壙嬥妟(敪拲)
                 ,shipping_cost_amt             -- 尨壙嬥妟(弌壸)
                 ,stockout_cost_amt             -- 尨壙嬥妟(寚昳)
                 ,selling_price                 -- 攧扨壙
                 ,order_price_amt               -- 攧壙嬥妟(敪拲)
                 ,shipping_price_amt            -- 攧壙嬥妟(弌壸)
                 ,stockout_price_amt            -- 攧壙嬥妟(寚昳)
                 ,a_column_department           -- 俙棑(昐壿揦)
                 ,d_column_department           -- 俢棑(昐壿揦)
                 ,standard_info_depth           -- 婯奿忣曬丒墱峴偒
                 ,standard_info_height          -- 婯奿忣曬丒崅偝
                 ,standard_info_width           -- 婯奿忣曬丒暆
                 ,standard_info_weight          -- 婯奿忣曬丒廳検
                 ,general_succeeded_item1       -- 斈梡堷宲偓崁栚侾
                 ,general_succeeded_item2       -- 斈梡堷宲偓崁栚俀
                 ,general_succeeded_item3       -- 斈梡堷宲偓崁栚俁
                 ,general_succeeded_item4       -- 斈梡堷宲偓崁栚係
                 ,general_succeeded_item5       -- 斈梡堷宲偓崁栚俆
                 ,general_succeeded_item6       -- 斈梡堷宲偓崁栚俇
                 ,general_succeeded_item7       -- 斈梡堷宲偓崁栚俈
                 ,general_succeeded_item8       -- 斈梡堷宲偓崁栚俉
                 ,general_succeeded_item9       -- 斈梡堷宲偓崁栚俋
                 ,general_succeeded_item10      -- 斈梡堷宲偓崁栚侾侽
                 ,general_add_item1             -- 斈梡晅壛崁栚侾
                 ,general_add_item2             -- 斈梡晅壛崁栚俀
                 ,general_add_item3             -- 斈梡晅壛崁栚俁
                 ,general_add_item4             -- 斈梡晅壛崁栚係
                 ,general_add_item5             -- 斈梡晅壛崁栚俆
                 ,general_add_item6             -- 斈梡晅壛崁栚俇
                 ,general_add_item7             -- 斈梡晅壛崁栚俈
                 ,general_add_item8             -- 斈梡晅壛崁栚俉
                 ,general_add_item9             -- 斈梡晅壛崁栚俋
                 ,general_add_item10            -- 斈梡晅壛崁栚侾侽
                 ,chain_peculiar_area_line      -- 僠僃乕儞揦屌桳僄儕傾(柧嵶)
                 ,item_code                     -- 昳栚僐乕僪
                 ,line_uom                      -- 柧嵶扨埵
                 ,hht_delivery_schedule_flag    -- HHT擺昳梊掕楢実嵪僼儔僌
                 ,order_connection_line_number  -- 庴拲娭楢柧嵶斣崋
                 ,created_by                    -- 嶌惉幰
                 ,creation_date                 -- 嶌惉擔
                 ,last_updated_by               -- 嵟廔峏怴幰
                 ,last_update_date              -- 嵟廔峏怴擔
                 ,last_update_login             -- 嵟廔峏怴儘僌僀儞
                 ,request_id                    -- 梫媮ID
                 ,program_application_id        -- 僐儞僇儗儞僩丒僾儘僌儔儉丒傾僾儕働乕僔儑儞ID
                 ,program_id                    -- 僐儞僇儗儞僩丒僾儘僌儔儉ID
                 ,program_update_date           -- 僾儘僌儔儉峏怴擔
                ) VALUES (
                  ln_line_info_id                                  -- EDI柧嵶忣曬ID
                 ,lt_head_edit_tab(ln_head_cnt).edi_header_info_id -- EDI僿僢僟忣曬ID
                 ,lt_line_tab(ln_line_cnt).line_number             -- 峴俶倧
                 ,cv_stockout_class                                -- 寚昳嬫暘
                 ,NULL                                             -- 寚昳棟桼
                 ,lt_line_tab(ln_line_cnt).ordered_item            -- 彜昳僐乕僪(埳摗墍)
                 ,NULL                                             -- 彜昳僐乕僪侾
                 ,lv_product_code2                                 -- 彜昳僐乕僪俀
                 ,lt_line_tab(ln_line_cnt).jan_code                -- 俰俙俶僐乕僪
                 ,lt_line_tab(ln_line_cnt).itf_code                -- 俬俿俥僐乕僪
                 ,NULL                                             -- 撪敔俬俿俥僐乕僪
                 ,NULL                                             -- 働乕僗彜昳僐乕僪
                 ,NULL                                             -- 儃乕儖彜昳僐乕僪
                 ,NULL                                             -- 彜昳僐乕僪昳庬
                 ,NULL                                             -- 彜昳嬫暘
/* 2009/03/03 Ver1.1 Mod Start */
--               ,NULL                                             -- 彜昳柤(娍帤)
                 ,SUBSTRB(lt_line_tab(ln_line_cnt).item_name, 1, 60)     -- 彜昳柤(娍帤)
                 ,NULL                                             -- 彜昳柤侾(僇僫)
--               ,NULL                                             -- 彜昳柤俀(僇僫)
                 ,SUBSTRB(lt_line_tab(ln_line_cnt).item_name_alt, 1, 15) -- 彜昳柤俀(僇僫)
/* 2009/03/03 Ver1.1 Mod  End  */
                 ,NULL                                             -- 婯奿侾
                 ,NULL                                             -- 婯奿俀
                 ,NULL                                             -- 擖悢
                 ,lt_line_tab(ln_line_cnt).num_of_case             -- 働乕僗擖悢
                 ,lt_line_tab(ln_line_cnt).num_of_bowl             -- 儃乕儖擖悢
                 ,NULL                                             -- 怓
                 ,NULL                                             -- 僒僀僘
                 ,NULL                                             -- 徿枴婜尷擔
                 ,NULL                                             -- 惢憿擔
                 ,NULL                                             -- 敪拲扨埵悢
                 ,NULL                                             -- 弌壸扨埵悢
                 ,NULL                                             -- 崼曪扨埵悢
                 ,NULL                                             -- 堷崌
                 ,NULL                                             -- 堷崌嬫暘
                 ,NULL                                             -- 徠崌
/* 2009/04/24 Ver1.3 Mod Start */
--                 ,lt_line_tab(ln_line_cnt).order_quantity_uom      -- 扨埵
                 ,lt_line_tab(ln_line_cnt).edi_rep_uom             -- 扨埵
/* 2009/04/24 Ver1.3 Mod End   */
                 ,NULL                                             -- 扨壙嬫暘
                 ,NULL                                             -- 恊崼曪斣崋
                 ,NULL                                             -- 崼曪斣崋
                 ,NULL                                             -- 彜昳孮僐乕僪
                 ,NULL                                             -- 働乕僗夝懱晄壜僼儔僌
                 ,NULL                                             -- 働乕僗嬫暘
                 ,ln_indv_qty                                      -- 敪拲悢検(僶儔)
                 ,ln_case_qty                                      -- 敪拲悢検(働乕僗)
                 ,ln_bowl_qty                                      -- 敪拲悢検(儃乕儖)
                 ,lt_line_tab(ln_line_cnt).ordered_quantity        -- 敪拲悢検(崌寁丄僶儔)
                 ,ln_indv_qty                                      -- 弌壸悢検(僶儔)
                 ,ln_case_qty                                      -- 弌壸悢検(働乕僗)
                 ,ln_bowl_qty                                      -- 弌壸悢検(儃乕儖)
                 ,NULL                                             -- 弌壸悢検(僷儗僢僩)
                 ,lt_line_tab(ln_line_cnt).ordered_quantity        -- 弌壸悢検(崌寁丄僶儔)
                 ,0                                                -- 寚昳悢検(僶儔)
                 ,0                                                -- 寚昳悢検(働乕僗)
                 ,0                                                -- 寚昳悢検(儃乕儖)
                 ,0                                                -- 寚昳悢検(崌寁丄僶儔)
                 ,NULL                                             -- 働乕僗屄岥悢
                 ,NULL                                             -- 僆儕僐儞(僶儔)屄岥悢
                 ,lt_line_tab(ln_line_cnt).unit_selling_price      -- 尨扨壙(敪拲)
                 ,lt_line_tab(ln_line_cnt).unit_selling_price      -- 尨扨壙(弌壸)
                 ,NULL                                             -- 尨壙嬥妟(敪拲)
                 ,NULL                                             -- 尨壙嬥妟(弌壸)
                 ,NULL                                             -- 尨壙嬥妟(寚昳)
/* 2010/03/09 Ver1.8 Mod Start */
--                 ,NULL                                             -- 攧扨壙
--                 ,NULL                                             -- 攧壙嬥妟(敪拲)
                 ,lt_line_tab(ln_line_cnt).selling_price           -- 攧扨壙
                 ,lt_line_tab(ln_line_cnt).order_price_amt         -- 攧壙嬥妟(敪拲)
/* 2010/03/09 Ver1.8 Mod  End  */
                 ,NULL                                             -- 攧壙嬥妟(弌壸)
                 ,NULL                                             -- 攧壙嬥妟(寚昳)
                 ,NULL                                             -- 俙棑(昐壿揦)
                 ,NULL                                             -- 俢棑(昐壿揦)
                 ,NULL                                             -- 婯奿忣曬丒墱峴偒
                 ,NULL                                             -- 婯奿忣曬丒崅偝
                 ,NULL                                             -- 婯奿忣曬丒暆
                 ,NULL                                             -- 婯奿忣曬丒廳検
                 ,NULL                                             -- 斈梡堷宲偓崁栚侾
                 ,NULL                                             -- 斈梡堷宲偓崁栚俀
                 ,NULL                                             -- 斈梡堷宲偓崁栚俁
                 ,NULL                                             -- 斈梡堷宲偓崁栚係
                 ,NULL                                             -- 斈梡堷宲偓崁栚俆
                 ,NULL                                             -- 斈梡堷宲偓崁栚俇
                 ,NULL                                             -- 斈梡堷宲偓崁栚俈
                 ,NULL                                             -- 斈梡堷宲偓崁栚俉
                 ,NULL                                             -- 斈梡堷宲偓崁栚俋
                 ,NULL                                             -- 斈梡堷宲偓崁栚侾侽
                 ,NULL                                             -- 斈梡晅壛崁栚侾
                 ,NULL                                             -- 斈梡晅壛崁栚俀
                 ,NULL                                             -- 斈梡晅壛崁栚俁
                 ,NULL                                             -- 斈梡晅壛崁栚係
                 ,NULL                                             -- 斈梡晅壛崁栚俆
                 ,NULL                                             -- 斈梡晅壛崁栚俇
                 ,NULL                                             -- 斈梡晅壛崁栚俈
                 ,NULL                                             -- 斈梡晅壛崁栚俉
                 ,NULL                                             -- 斈梡晅壛崁栚俋
                 ,NULL                                             -- 斈梡晅壛崁栚侾侽
                 ,NULL                                             -- 僠僃乕儞揦屌桳僄儕傾(柧嵶)
                 ,lt_line_tab(ln_line_cnt).ordered_item            -- 昳栚僐乕僪
                 ,lt_line_tab(ln_line_cnt).order_quantity_uom      -- 柧嵶扨埵
                 ,cv_flag_no                                       -- HHT擺昳梊掕楢実嵪僼儔僌
                 ,lt_line_tab(ln_line_cnt).orig_sys_line_refw      -- 庴拲娭楢柧嵶斣崋
                 ,ln_user_id                                       -- 嶌惉幰
                 ,SYSDATE                                          -- 嶌惉擔
                 ,ln_user_id                                       -- 嵟廔峏怴幰
                 ,SYSDATE                                          -- 嵟廔峏怴擔
                 ,ln_login_id                                      -- 嵟廔峏怴儘僌僀儞
                 ,NULL                                             -- 梫媮ID
                 ,NULL                                             -- 僐儞僇儗儞僩丒僾儘僌儔儉丒傾僾儕働乕僔儑儞ID
                 ,NULL                                             -- 僐儞僇儗儞僩丒僾儘僌儔儉ID
                 ,NULL                                             -- 僾儘僌儔儉峏怴擔
                );
              EXCEPTION
                WHEN OTHERS THEN
                  lv_table_name := cv_tbl_name_line;
                  RAISE table_insert_expt;
              END;
--
            END LOOP line_insert_loop;
          END IF;      -- 攧忋嬫暘懳徾丠
        END IF;        -- 奩摉柧嵶偁傝丠
      END IF;          -- 庢傝崬傒嵪傒丠
    END LOOP head_proc_loop;
--
    ln_invoice_cnt := 1;
    <<head_insert_loop>>
    FOR ln_head_cnt IN 1 .. lt_head_tab.COUNT LOOP
      -- 僿僢僟張棟懳徾丠
      IF ( lt_head_edit_tab(ln_head_cnt).edi_header_info_id IS NOT NULL ) THEN
        -- 揱昜寁
        IF ( lt_invoice_tab(ln_invoice_cnt).invoice_number <> lt_head_tab(ln_head_cnt).cust_po_number ) THEN
          ln_invoice_cnt := ln_invoice_cnt + 1;
        END IF;
--
        -- EDI僿僢僟忣曬僥乕僽儖憓擖
        BEGIN
          INSERT INTO xxcos_edi_headers
          (
            edi_header_info_id            -- EDI僿僢僟忣曬ID
           ,medium_class                  -- 攠懱嬫暘
           ,data_type_code                -- 僨乕僞庬僐乕僪
           ,file_no                       -- 僼傽僀儖俶倧
           ,info_class                    -- 忣曬嬫暘
           ,process_date                  -- 張棟擔
           ,process_time                  -- 張棟帪崗
           ,base_code                     -- 嫆揰(晹栧)僐乕僪
           ,base_name                     -- 嫆揰柤(惓幃柤)
           ,base_name_alt                 -- 嫆揰柤(僇僫)
           ,edi_chain_code                -- 俤俢俬僠僃乕儞揦僐乕僪
           ,edi_chain_name                -- 俤俢俬僠僃乕儞揦柤(娍帤)
           ,edi_chain_name_alt            -- 俤俢俬僠僃乕儞揦柤(僇僫)
           ,chain_code                    -- 僠僃乕儞揦僐乕僪
           ,chain_name                    -- 僠僃乕儞揦柤(娍帤)
           ,chain_name_alt                -- 僠僃乕儞揦柤(僇僫)
           ,report_code                   -- 挔昜僐乕僪
           ,report_show_name              -- 挔昜昞帵柤
           ,customer_code                 -- 屭媞僐乕僪
           ,customer_name                 -- 屭媞柤(娍帤)
           ,customer_name_alt             -- 屭媞柤(僇僫)
           ,company_code                  -- 幮僐乕僪
           ,company_name                  -- 幮柤(娍帤)
           ,company_name_alt              -- 幮柤(僇僫)
           ,shop_code                     -- 揦僐乕僪
           ,shop_name                     -- 揦柤(娍帤)
           ,shop_name_alt                 -- 揦柤(僇僫)
           ,delivery_center_code          -- 擺擖僙儞僞乕僐乕僪
           ,delivery_center_name          -- 擺擖僙儞僞乕柤(娍帤)
           ,delivery_center_name_alt      -- 擺擖僙儞僞乕柤(僇僫)
           ,order_date                    -- 敪拲擔
           ,center_delivery_date          -- 僙儞僞乕擺昳擔
           ,result_delivery_date          -- 幚擺昳擔
           ,shop_delivery_date            -- 揦曑擺昳擔
           ,data_creation_date_edi_data   -- 僨乕僞嶌惉擔(俤俢俬僨乕僞拞)
           ,data_creation_time_edi_data   -- 僨乕僞嶌惉帪崗(俤俢俬僨乕僞拞)
           ,invoice_class                 -- 揱昜嬫暘
           ,small_classification_code     -- 彫暘椶僐乕僪
           ,small_classification_name     -- 彫暘椶柤
           ,middle_classification_code    -- 拞暘椶僐乕僪
           ,middle_classification_name    -- 拞暘椶柤
           ,big_classification_code       -- 戝暘椶僐乕僪
           ,big_classification_name       -- 戝暘椶柤
           ,other_party_department_code   -- 憡庤愭晹栧僐乕僪
           ,other_party_order_number      -- 憡庤愭敪拲斣崋
           ,check_digit_class             -- 僠僃僢僋僨僕僢僩桳柍嬫暘
           ,invoice_number                -- 揱昜斣崋
           ,check_digit                   -- 僠僃僢僋僨僕僢僩
           ,close_date                    -- 寧尷
           ,order_no_ebs                  -- 庴拲俶倧(俤俛俽)
           ,ar_sale_class                 -- 摿攧嬫暘
           ,delivery_classe               -- 攝憲嬫暘
           ,opportunity_no                -- 曋俶倧
           ,contact_to                    -- 楢棈愭
           ,route_sales                   -- 儖乕僩僙乕儖僗
           ,corporate_code                -- 朄恖僐乕僪
           ,maker_name                    -- 儊乕僇乕柤
           ,area_code                     -- 抧嬫僐乕僪
           ,area_name                     -- 抧嬫柤(娍帤)
           ,area_name_alt                 -- 抧嬫柤(僇僫)
           ,vendor_code                   -- 庢堷愭僐乕僪
           ,vendor_name                   -- 庢堷愭柤(娍帤)
           ,vendor_name1_alt              -- 庢堷愭柤侾(僇僫)
           ,vendor_name2_alt              -- 庢堷愭柤俀(僇僫)
           ,vendor_tel                    -- 庢堷愭俿俤俴
           ,vendor_charge                 -- 庢堷愭扴摉幰
           ,vendor_address                -- 庢堷愭廧強(娍帤)
           ,deliver_to_code_itouen        -- 撏偗愭僐乕僪(埳摗墍)
           ,deliver_to_code_chain         -- 撏偗愭僐乕僪(僠僃乕儞揦)
           ,deliver_to                    -- 撏偗愭(娍帤)
           ,deliver_to1_alt               -- 撏偗愭侾(僇僫)
           ,deliver_to2_alt               -- 撏偗愭俀(僇僫)
           ,deliver_to_address            -- 撏偗愭廧強(娍帤)
           ,deliver_to_address_alt        -- 撏偗愭廧強(僇僫)
           ,deliver_to_tel                -- 撏偗愭俿俤俴
           ,balance_accounts_code         -- 挔崌愭僐乕僪
           ,balance_accounts_company_code -- 挔崌愭幮僐乕僪
           ,balance_accounts_shop_code    -- 挔崌愭揦僐乕僪
           ,balance_accounts_name         -- 挔崌愭柤(娍帤)
           ,balance_accounts_name_alt     -- 挔崌愭柤(僇僫)
           ,balance_accounts_address      -- 挔崌愭廧強(娍帤)
           ,balance_accounts_address_alt  -- 挔崌愭廧強(僇僫)
           ,balance_accounts_tel          -- 挔崌愭俿俤俴
           ,order_possible_date           -- 庴拲壜擻擔
           ,permission_possible_date      -- 嫋梕壜擻擔
           ,forward_month                 -- 愭尷擭寧擔
           ,payment_settlement_date       -- 巟暐寛嵪擔
           ,handbill_start_date_active    -- 僠儔僔奐巒擔
           ,billing_due_date              -- 惪媮掲擔
           ,shipping_time                 -- 弌壸帪崗
           ,delivery_schedule_time        -- 擺昳梊掕帪娫
           ,order_time                    -- 敪拲帪娫
           ,general_date_item1            -- 斈梡擔晅崁栚侾
           ,general_date_item2            -- 斈梡擔晅崁栚俀
           ,general_date_item3            -- 斈梡擔晅崁栚俁
           ,general_date_item4            -- 斈梡擔晅崁栚係
           ,general_date_item5            -- 斈梡擔晅崁栚俆
           ,arrival_shipping_class        -- 擖弌壸嬫暘
           ,vendor_class                  -- 庢堷愭嬫暘
           ,invoice_detailed_class        -- 揱昜撪栿嬫暘
           ,unit_price_use_class          -- 扨壙巊梡嬫暘
           ,sub_distribution_center_code  -- 僒僽暔棳僙儞僞乕僐乕僪
           ,sub_distribution_center_name  -- 僒僽暔棳僙儞僞乕僐乕僪柤
           ,center_delivery_method        -- 僙儞僞乕擺昳曽朄
           ,center_use_class              -- 僙儞僞乕棙梡嬫暘
           ,center_whse_class             -- 僙儞僞乕憅屔嬫暘
           ,center_area_class             -- 僙儞僞乕抧堟嬫暘
           ,center_arrival_class          -- 僙儞僞乕擖壸嬫暘
           ,depot_class                   -- 僨億嬫暘
           ,tcdc_class                    -- 俿俠俢俠嬫暘
           ,upc_flag                      -- 倀俹俠僼儔僌
           ,simultaneously_class          -- 堦惸嬫暘
           ,business_id                   -- 嬈柋俬俢
           ,whse_directly_class           -- 憅捈嬫暘
           ,premium_rebate_class          -- 宨昳妱栠嬫暘
           ,item_type                     -- 崁栚庬暿
           ,cloth_house_food_class        -- 堖壠怘嬫暘
           ,mix_class                     -- 崿嵼嬫暘
           ,stk_class                     -- 嵼屔嬫暘
           ,last_modify_site_class        -- 嵟廔廋惓応強嬫暘
           ,report_class                  -- 挔昜嬫暘
           ,addition_plan_class           -- 捛壛丒寁夋嬫暘
           ,registration_class            -- 搊榐嬫暘
           ,specific_class                -- 摿掕嬫暘
           ,dealings_class                -- 庢堷嬫暘
           ,order_class                   -- 敪拲嬫暘
           ,sum_line_class                -- 廤寁柧嵶嬫暘
           ,shipping_guidance_class       -- 弌壸埬撪埲奜嬫暘
           ,shipping_class                -- 弌壸嬫暘
           ,product_code_use_class        -- 彜昳僐乕僪巊梡嬫暘
           ,cargo_item_class              -- 愊憲昳嬫暘
           ,ta_class                      -- 俿乛俙嬫暘
           ,plan_code                     -- 婇夋僐乕僪
           ,category_code                 -- 僇僥僑儕乕僐乕僪
           ,category_class                -- 僇僥僑儕乕嬫暘
           ,carrier_means                 -- 塣憲庤抜
           ,counter_code                  -- 攧応僐乕僪
           ,move_sign                     -- 堏摦僒僀儞
           ,eos_handwriting_class         -- 俤俷俽丒庤彂嬫暘
           ,delivery_to_section_code      -- 擺昳愭壽僐乕僪
           ,invoice_detailed              -- 揱昜撪栿
           ,attach_qty                    -- 揧晅悢
           ,other_party_floor             -- 僼儘傾
           ,text_no                       -- 俿俤倃俿俶倧
           ,in_store_code                 -- 僀儞僗僩傾僐乕僪
           ,tag_data                      -- 僞僌
           ,competition_code              -- 嫞崌
           ,billing_chair                 -- 惪媮岥嵗
           ,chain_store_code              -- 僠僃乕儞僗僩傾乕僐乕僪
           ,chain_store_short_name        -- 僠僃乕儞僗僩傾乕僐乕僪棯幃柤徧
           ,direct_delivery_rcpt_fee      -- 捈攝憲乛堷庢椏
           ,bill_info                     -- 庤宍忣曬
           ,description                   -- 揈梫
           ,interior_code                 -- 撪晹僐乕僪
           ,order_info_delivery_category  -- 敪拲忣曬 擺昳僇僥僑儕乕
           ,purchase_type                 -- 巇擖宍懺
           ,delivery_to_name_alt          -- 擺昳応強柤(僇僫)
           ,shop_opened_site              -- 揦弌応強
           ,counter_name                  -- 攧応柤
           ,extension_number              -- 撪慄斣崋
           ,charge_name                   -- 扴摉幰柤
           ,price_tag                     -- 抣嶥
           ,tax_type                      -- 惻庬
           ,consumption_tax_class         -- 徚旓惻嬫暘
           ,brand_class                   -- 俛俼
           ,id_code                       -- 俬俢僐乕僪
           ,department_code               -- 昐壿揦僐乕僪
           ,department_name               -- 昐壿揦柤
           ,item_type_number              -- 昳暿斣崋
           ,description_department        -- 揈梫(昐壿揦)
           ,price_tag_method              -- 抣嶥曽朄
           ,reason_column                 -- 帺桼棑
           ,a_column_header               -- 俙棑僿僢僟
           ,d_column_header               -- 俢棑僿僢僟
           ,brand_code                    -- 僽儔儞僪僐乕僪
           ,line_code                     -- 儔僀儞僐乕僪
           ,class_code                    -- 僋儔僗僐乕僪
           ,a1_column                     -- 俙亅侾棑
           ,b1_column                     -- 俛亅侾棑
           ,c1_column                     -- 俠亅侾棑
           ,d1_column                     -- 俢亅侾棑
           ,e1_column                     -- 俤亅侾棑
           ,a2_column                     -- 俙亅俀棑
           ,b2_column                     -- 俛亅俀棑
           ,c2_column                     -- 俠亅俀棑
           ,d2_column                     -- 俢亅俀棑
           ,e2_column                     -- 俤亅俀棑
           ,a3_column                     -- 俙亅俁棑
           ,b3_column                     -- 俛亅俁棑
           ,c3_column                     -- 俠亅俁棑
           ,d3_column                     -- 俢亅俁棑
           ,e3_column                     -- 俤亅俁棑
           ,f1_column                     -- 俥亅侾棑
           ,g1_column                     -- 俧亅侾棑
           ,h1_column                     -- 俫亅侾棑
           ,i1_column                     -- 俬亅侾棑
           ,j1_column                     -- 俰亅侾棑
           ,k1_column                     -- 俲亅侾棑
           ,l1_column                     -- 俴亅侾棑
           ,f2_column                     -- 俥亅俀棑
           ,g2_column                     -- 俧亅俀棑
           ,h2_column                     -- 俫亅俀棑
           ,i2_column                     -- 俬亅俀棑
           ,j2_column                     -- 俰亅俀棑
           ,k2_column                     -- 俲亅俀棑
           ,l2_column                     -- 俴亅俀棑
           ,f3_column                     -- 俥亅俁棑
           ,g3_column                     -- 俧亅俁棑
           ,h3_column                     -- 俫亅俁棑
           ,i3_column                     -- 俬亅俁棑
           ,j3_column                     -- 俰亅俁棑
           ,k3_column                     -- 俲亅俁棑
           ,l3_column                     -- 俴亅俁棑
           ,chain_peculiar_area_header    -- 僠僃乕儞揦屌桳僄儕傾(僿僢僟乕)
           ,order_connection_number       -- 庴拲娭楢斣崋
           ,invoice_indv_order_qty        -- (揱昜寁)敪拲悢検(僶儔)
           ,invoice_case_order_qty        -- (揱昜寁)敪拲悢検(働乕僗)
           ,invoice_ball_order_qty        -- (揱昜寁)敪拲悢検(儃乕儖)
           ,invoice_sum_order_qty         -- (揱昜寁)敪拲悢検(崌寁丄僶儔)
           ,invoice_indv_shipping_qty     -- (揱昜寁)弌壸悢検(僶儔)
           ,invoice_case_shipping_qty     -- (揱昜寁)弌壸悢検(働乕僗)
           ,invoice_ball_shipping_qty     -- (揱昜寁)弌壸悢検(儃乕儖)
           ,invoice_pallet_shipping_qty   -- (揱昜寁)弌壸悢検(僷儗僢僩)
           ,invoice_sum_shipping_qty      -- (揱昜寁)弌壸悢検(崌寁丄僶儔)
           ,invoice_indv_stockout_qty     -- (揱昜寁)寚昳悢検(僶儔)
           ,invoice_case_stockout_qty     -- (揱昜寁)寚昳悢検(働乕僗)
           ,invoice_ball_stockout_qty     -- (揱昜寁)寚昳悢検(儃乕儖)
           ,invoice_sum_stockout_qty      -- (揱昜寁)寚昳悢検(崌寁丄僶儔)
           ,invoice_case_qty              -- (揱昜寁)働乕僗屄岥悢
           ,invoice_fold_container_qty    -- (揱昜寁)僆儕僐儞(僶儔)屄岥悢
           ,invoice_order_cost_amt        -- (揱昜寁)尨壙嬥妟(敪拲)
           ,invoice_shipping_cost_amt     -- (揱昜寁)尨壙嬥妟(弌壸)
           ,invoice_stockout_cost_amt     -- (揱昜寁)尨壙嬥妟(寚昳)
           ,invoice_order_price_amt       -- (揱昜寁)攧壙嬥妟(敪拲)
           ,invoice_shipping_price_amt    -- (揱昜寁)攧壙嬥妟(弌壸)
           ,invoice_stockout_price_amt    -- (揱昜寁)攧壙嬥妟(寚昳)
           ,total_indv_order_qty          -- (憤崌寁)敪拲悢検(僶儔)
           ,total_case_order_qty          -- (憤崌寁)敪拲悢検(働乕僗)
           ,total_ball_order_qty          -- (憤崌寁)敪拲悢検(儃乕儖)
           ,total_sum_order_qty           -- (憤崌寁)敪拲悢検(崌寁丄僶儔)
           ,total_indv_shipping_qty       -- (憤崌寁)弌壸悢検(僶儔)
           ,total_case_shipping_qty       -- (憤崌寁)弌壸悢検(働乕僗)
           ,total_ball_shipping_qty       -- (憤崌寁)弌壸悢検(儃乕儖)
           ,total_pallet_shipping_qty     -- (憤崌寁)弌壸悢検(僷儗僢僩)
           ,total_sum_shipping_qty        -- (憤崌寁)弌壸悢検(崌寁丄僶儔)
           ,total_indv_stockout_qty       -- (憤崌寁)寚昳悢検(僶儔)
           ,total_case_stockout_qty       -- (憤崌寁)寚昳悢検(働乕僗)
           ,total_ball_stockout_qty       -- (憤崌寁)寚昳悢検(儃乕儖)
           ,total_sum_stockout_qty        -- (憤崌寁)寚昳悢検(崌寁丄僶儔)
           ,total_case_qty                -- (憤崌寁)働乕僗屄岥悢
           ,total_fold_container_qty      -- (憤崌寁)僆儕僐儞(僶儔)屄岥悢
           ,total_order_cost_amt          -- (憤崌寁)尨壙嬥妟(敪拲)
           ,total_shipping_cost_amt       -- (憤崌寁)尨壙嬥妟(弌壸)
           ,total_stockout_cost_amt       -- (憤崌寁)尨壙嬥妟(寚昳)
           ,total_order_price_amt         -- (憤崌寁)攧壙嬥妟(敪拲)
           ,total_shipping_price_amt      -- (憤崌寁)攧壙嬥妟(弌壸)
           ,total_stockout_price_amt      -- (憤崌寁)攧壙嬥妟(寚昳)
           ,total_line_qty                -- 僩乕僞儖峴悢
           ,total_invoice_qty             -- 僩乕僞儖揱昜枃悢
           ,chain_peculiar_area_footer    -- 僠僃乕儞揦屌桳僄儕傾(僼僢僞乕)
           ,conv_customer_code            -- 曄峏屻屭媞僐乕僪
           ,order_forward_flag            -- 庴拲楢実嵪僼儔僌
           ,creation_class                -- 嶌惉尦嬫暘
           ,edi_delivery_schedule_flag    -- EDI擺昳梊掕憲怣嵪僼儔僌
           ,price_list_header_id          -- 壙奿昞僿僢僟ID
           ,created_by                    -- 嶌惉幰
           ,creation_date                 -- 嶌惉擔
           ,last_updated_by               -- 嵟廔峏怴幰
           ,last_update_date              -- 嵟廔峏怴擔
           ,last_update_login             -- 嵟廔峏怴儘僌僀儞
           ,request_id                    -- 梫媮ID
           ,program_application_id        -- 僐儞僇儗儞僩丒僾儘僌儔儉丒傾僾儕働乕僔儑儞ID
           ,program_id                    -- 僐儞僇儗儞僩丒僾儘僌儔儉ID
           ,program_update_date           -- 僾儘僌儔儉峏怴擔
           ) VALUES (
            lt_head_edit_tab(ln_head_cnt).edi_header_info_id            -- EDI僿僢僟忣曬ID
           ,cv_medium_class                                             -- 攠懱嬫暘
           ,cv_data_type_code                                           -- 僨乕僞庬僐乕僪
           ,cv_file_no                                                  -- 僼傽僀儖俶倧
           ,NULL                                                        -- 忣曬嬫暘
           ,NULL                                                        -- 張棟擔
           ,NULL                                                        -- 張棟帪崗
           ,lt_head_tab(ln_head_cnt).base_code                          -- 嫆揰(晹栧)僐乕僪
           ,lt_head_tab(ln_head_cnt).base_name                          -- 嫆揰柤(惓幃柤)
           ,lt_head_tab(ln_head_cnt).base_name_alt                      -- 嫆揰柤(僇僫)
           ,lt_head_tab(ln_head_cnt).edi_chain_code                     -- 俤俢俬僠僃乕儞揦僐乕僪
           ,lt_head_tab(ln_head_cnt).edi_chain_name                     -- 俤俢俬僠僃乕儞揦柤(娍帤)
           ,lt_head_tab(ln_head_cnt).edi_chain_name_alt                 -- 俤俢俬僠僃乕儞揦柤(僇僫)
           ,NULL                                                        -- 僠僃乕儞揦僐乕僪
           ,NULL                                                        -- 僠僃乕儞揦柤(娍帤)
           ,NULL                                                        -- 僠僃乕儞揦柤(僇僫)
           ,NULL                                                        -- 挔昜僐乕僪
           ,NULL                                                        -- 挔昜昞帵柤
           ,lt_head_tab(ln_head_cnt).account_number                     -- 屭媞僐乕僪
           ,lt_head_tab(ln_head_cnt).customer_name                      -- 屭媞柤(娍帤)
           ,lt_head_tab(ln_head_cnt).customer_name_alt                  -- 屭媞柤(僇僫)
           ,NULL                                                        -- 幮僐乕僪
           ,NULL                                                        -- 幮柤(娍帤)
           ,NULL                                                        -- 幮柤(僇僫)
           ,lt_head_tab(ln_head_cnt).store_code                         -- 揦僐乕僪
           ,lt_head_tab(ln_head_cnt).cust_store_name                    -- 揦柤(娍帤)
           ,NULL                                                        -- 揦柤(僇僫)
           ,NULL                                                        -- 擺擖僙儞僞乕僐乕僪
           ,NULL                                                        -- 擺擖僙儞僞乕柤(娍帤)
           ,NULL                                                        -- 擺擖僙儞僞乕柤(僇僫)
           ,lt_head_tab(ln_head_cnt).ordered_date                       -- 敪拲擔
           ,lt_head_tab(ln_head_cnt).request_date                       -- 僙儞僞乕擺昳擔
           ,NULL                                                        -- 幚擺昳擔
           ,lt_head_tab(ln_head_cnt).request_date                       -- 揦曑擺昳擔
           ,NULL                                                        -- 僨乕僞嶌惉擔(俤俢俬僨乕僞拞)
           ,NULL                                                        -- 僨乕僞嶌惉帪崗(俤俢俬僨乕僞拞)
/* 2009/07/14 Ver1.6 Mod Start */
--           ,NULL                                                        -- 揱昜嬫暘
           ,lt_head_tab(ln_head_cnt).invoice_class                      -- 揱昜嬫暘
/* 2009/07/14 Ver1.6 Mod End   */
           ,NULL                                                        -- 彫暘椶僐乕僪
           ,NULL                                                        -- 彫暘椶柤
           ,NULL                                                        -- 拞暘椶僐乕僪
           ,NULL                                                        -- 拞暘椶柤
/* 2009/07/14 Ver1.6 Mod Start */
--           ,NULL                                                        -- 戝暘椶僐乕僪
           ,lt_head_tab(ln_head_cnt).classification_code                -- 戝暘椶僐乕僪
/* 2009/07/14 Ver1.6 Mod End   */
           ,NULL                                                        -- 戝暘椶柤
           ,NULL                                                        -- 憡庤愭晹栧僐乕僪
           ,NULL                                                        -- 憡庤愭敪拲斣崋
           ,NULL                                                        -- 僠僃僢僋僨僕僢僩桳柍嬫暘
           ,lt_head_tab(ln_head_cnt).cust_po_number                     -- 揱昜斣崋
           ,NULL                                                        -- 僠僃僢僋僨僕僢僩
           ,NULL                                                        -- 寧尷
           ,lt_head_tab(ln_head_cnt).order_number                       -- 庴拲俶倧(俤俛俽)
           ,lt_head_edit_tab(ln_head_cnt).ar_sale_class                 -- 摿攧嬫暘
           ,NULL                                                        -- 攝憲嬫暘
           ,NULL                                                        -- 曋俶倧
           ,NULL                                                        -- 楢棈愭
           ,NULL                                                        -- 儖乕僩僙乕儖僗
           ,NULL                                                        -- 朄恖僐乕僪
           ,NULL                                                        -- 儊乕僇乕柤
           ,lt_head_tab(ln_head_cnt).edi_district_code                  -- 抧嬫僐乕僪
           ,lt_head_tab(ln_head_cnt).edi_district_name                  -- 抧嬫柤(娍帤)
           ,lt_head_tab(ln_head_cnt).edi_district_kana                  -- 抧嬫柤(僇僫)
           ,NULL                                                        -- 庢堷愭僐乕僪
           ,NULL                                                        -- 庢堷愭柤(娍帤)
           ,NULL                                                        -- 庢堷愭柤侾(僇僫)
           ,NULL                                                        -- 庢堷愭柤俀(僇僫)
           ,NULL                                                        -- 庢堷愭俿俤俴
           ,NULL                                                        -- 庢堷愭扴摉幰
           ,NULL                                                        -- 庢堷愭廧強(娍帤)
           ,NULL                                                        -- 撏偗愭僐乕僪(埳摗墍)
           ,NULL                                                        -- 撏偗愭僐乕僪(僠僃乕儞揦)
           ,NULL                                                        -- 撏偗愭(娍帤)
           ,NULL                                                        -- 撏偗愭侾(僇僫)
           ,NULL                                                        -- 撏偗愭俀(僇僫)
           ,NULL                                                        -- 撏偗愭廧強(娍帤)
           ,NULL                                                        -- 撏偗愭廧強(僇僫)
           ,NULL                                                        -- 撏偗愭俿俤俴
           ,NULL                                                        -- 挔崌愭僐乕僪
           ,NULL                                                        -- 挔崌愭幮僐乕僪
           ,NULL                                                        -- 挔崌愭揦僐乕僪
           ,NULL                                                        -- 挔崌愭柤(娍帤)
           ,NULL                                                        -- 挔崌愭柤(僇僫)
           ,NULL                                                        -- 挔崌愭廧強(娍帤)
           ,NULL                                                        -- 挔崌愭廧強(僇僫)
           ,NULL                                                        -- 挔崌愭俿俤俴
           ,NULL                                                        -- 庴拲壜擻擔
           ,NULL                                                        -- 嫋梕壜擻擔
           ,NULL                                                        -- 愭尷擭寧擔
           ,NULL                                                        -- 巟暐寛嵪擔
           ,NULL                                                        -- 僠儔僔奐巒擔
           ,NULL                                                        -- 惪媮掲擔
           ,NULL                                                        -- 弌壸帪崗
           ,NULL                                                        -- 擺昳梊掕帪娫
           ,NULL                                                        -- 敪拲帪娫
           ,NULL                                                        -- 斈梡擔晅崁栚侾
           ,NULL                                                        -- 斈梡擔晅崁栚俀
           ,NULL                                                        -- 斈梡擔晅崁栚俁
           ,NULL                                                        -- 斈梡擔晅崁栚係
           ,NULL                                                        -- 斈梡擔晅崁栚俆
           ,NULL                                                        -- 擖弌壸嬫暘
           ,NULL                                                        -- 庢堷愭嬫暘
           ,NULL                                                        -- 揱昜撪栿嬫暘
           ,NULL                                                        -- 扨壙巊梡嬫暘
           ,NULL                                                        -- 僒僽暔棳僙儞僞乕僐乕僪
           ,NULL                                                        -- 僒僽暔棳僙儞僞乕僐乕僪柤
           ,NULL                                                        -- 僙儞僞乕擺昳曽朄
           ,NULL                                                        -- 僙儞僞乕棙梡嬫暘
           ,NULL                                                        -- 僙儞僞乕憅屔嬫暘
           ,NULL                                                        -- 僙儞僞乕抧堟嬫暘
           ,NULL                                                        -- 僙儞僞乕擖壸嬫暘
           ,NULL                                                        -- 僨億嬫暘
           ,NULL                                                        -- 俿俠俢俠嬫暘
           ,NULL                                                        -- 倀俹俠僼儔僌
           ,NULL                                                        -- 堦惸嬫暘
           ,NULL                                                        -- 嬈柋俬俢
           ,NULL                                                        -- 憅捈嬫暘
           ,NULL                                                        -- 宨昳妱栠嬫暘
           ,NULL                                                        -- 崁栚庬暿
           ,NULL                                                        -- 堖壠怘嬫暘
           ,NULL                                                        -- 崿嵼嬫暘
           ,NULL                                                        -- 嵼屔嬫暘
           ,NULL                                                        -- 嵟廔廋惓応強嬫暘
           ,NULL                                                        -- 挔昜嬫暘
           ,NULL                                                        -- 捛壛丒寁夋嬫暘
           ,NULL                                                        -- 搊榐嬫暘
           ,NULL                                                        -- 摿掕嬫暘
           ,NULL                                                        -- 庢堷嬫暘
           ,NULL                                                        -- 敪拲嬫暘
           ,NULL                                                        -- 廤寁柧嵶嬫暘
           ,NULL                                                        -- 弌壸埬撪埲奜嬫暘
           ,NULL                                                        -- 弌壸嬫暘
           ,NULL                                                        -- 彜昳僐乕僪巊梡嬫暘
           ,NULL                                                        -- 愊憲昳嬫暘
           ,NULL                                                        -- 俿乛俙嬫暘
           ,NULL                                                        -- 婇夋僐乕僪
           ,NULL                                                        -- 僇僥僑儕乕僐乕僪
           ,NULL                                                        -- 僇僥僑儕乕嬫暘
           ,NULL                                                        -- 塣憲庤抜
           ,NULL                                                        -- 攧応僐乕僪
           ,NULL                                                        -- 堏摦僒僀儞
           ,NULL                                                        -- 俤俷俽丒庤彂嬫暘
           ,NULL                                                        -- 擺昳愭壽僐乕僪
           ,NULL                                                        -- 揱昜撪栿
           ,NULL                                                        -- 揧晅悢
           ,NULL                                                        -- 僼儘傾
           ,NULL                                                        -- 俿俤倃俿俶倧
           ,NULL                                                        -- 僀儞僗僩傾僐乕僪
           ,NULL                                                        -- 僞僌
           ,NULL                                                        -- 嫞崌
           ,NULL                                                        -- 惪媮岥嵗
           ,NULL                                                        -- 僠僃乕儞僗僩傾乕僐乕僪
           ,NULL                                                        -- 僠僃乕儞僗僩傾乕僐乕僪棯幃柤徧
           ,NULL                                                        -- 捈攝憲乛堷庢椏
           ,NULL                                                        -- 庤宍忣曬
           ,NULL                                                        -- 揈梫
           ,NULL                                                        -- 撪晹僐乕僪
           ,NULL                                                        -- 敪拲忣曬 擺昳僇僥僑儕乕
           ,NULL                                                        -- 巇擖宍懺
           ,NULL                                                        -- 擺昳応強柤(僇僫)
           ,NULL                                                        -- 揦弌応強
           ,NULL                                                        -- 攧応柤
           ,NULL                                                        -- 撪慄斣崋
           ,NULL                                                        -- 扴摉幰柤
           ,NULL                                                        -- 抣嶥
           ,NULL                                                        -- 惻庬
           ,NULL                                                        -- 徚旓惻嬫暘
           ,NULL                                                        -- 俛俼
           ,NULL                                                        -- 俬俢僐乕僪
           ,NULL                                                        -- 昐壿揦僐乕僪
           ,NULL                                                        -- 昐壿揦柤
           ,NULL                                                        -- 昳暿斣崋
           ,NULL                                                        -- 揈梫(昐壿揦)
           ,NULL                                                        -- 抣嶥曽朄
           ,NULL                                                        -- 帺桼棑
           ,NULL                                                        -- 俙棑僿僢僟
           ,NULL                                                        -- 俢棑僿僢僟
           ,NULL                                                        -- 僽儔儞僪僐乕僪
           ,NULL                                                        -- 儔僀儞僐乕僪
           ,NULL                                                        -- 僋儔僗僐乕僪
           ,NULL                                                        -- 俙亅侾棑
           ,NULL                                                        -- 俛亅侾棑
           ,NULL                                                        -- 俠亅侾棑
           ,NULL                                                        -- 俢亅侾棑
           ,NULL                                                        -- 俤亅侾棑
           ,NULL                                                        -- 俙亅俀棑
           ,NULL                                                        -- 俛亅俀棑
           ,NULL                                                        -- 俠亅俀棑
           ,NULL                                                        -- 俢亅俀棑
           ,NULL                                                        -- 俤亅俀棑
           ,NULL                                                        -- 俙亅俁棑
           ,NULL                                                        -- 俛亅俁棑
           ,NULL                                                        -- 俠亅俁棑
           ,NULL                                                        -- 俢亅俁棑
           ,NULL                                                        -- 俤亅俁棑
           ,NULL                                                        -- 俥亅侾棑
           ,NULL                                                        -- 俧亅侾棑
           ,NULL                                                        -- 俫亅侾棑
           ,NULL                                                        -- 俬亅侾棑
           ,NULL                                                        -- 俰亅侾棑
           ,NULL                                                        -- 俲亅侾棑
           ,NULL                                                        -- 俴亅侾棑
           ,NULL                                                        -- 俥亅俀棑
           ,NULL                                                        -- 俧亅俀棑
           ,NULL                                                        -- 俫亅俀棑
           ,NULL                                                        -- 俬亅俀棑
           ,NULL                                                        -- 俰亅俀棑
           ,NULL                                                        -- 俲亅俀棑
           ,NULL                                                        -- 俴亅俀棑
           ,NULL                                                        -- 俥亅俁棑
           ,NULL                                                        -- 俧亅俁棑
           ,NULL                                                        -- 俫亅俁棑
           ,NULL                                                        -- 俬亅俁棑
           ,NULL                                                        -- 俰亅俁棑
           ,NULL                                                        -- 俲亅俁棑
           ,NULL                                                        -- 俴亅俁棑
           ,NULL                                                        -- 僠僃乕儞揦屌桳僄儕傾(僿僢僟乕)
           ,lt_head_tab(ln_head_cnt).orig_sys_document_ref              -- 庴拲娭楢斣崋
           ,lt_invoice_tab(ln_invoice_cnt).invoice_indv_order_qty       -- (揱昜寁)敪拲悢検(僶儔)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_case_order_qty       -- (揱昜寁)敪拲悢検(働乕僗)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_ball_order_qty       -- (揱昜寁)敪拲悢検(儃乕儖)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_sum_order_qty        -- (揱昜寁)敪拲悢検(崌寁丄僶儔)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_indv_shipping_qty    -- (揱昜寁)弌壸悢検(僶儔)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_case_shipping_qty    -- (揱昜寁)弌壸悢検(働乕僗)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_ball_shipping_qty    -- (揱昜寁)弌壸悢検(儃乕儖)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_pallet_shipping_qty  -- (揱昜寁)弌壸悢検(僷儗僢僩)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_sum_shipping_qty     -- (揱昜寁)弌壸悢検(崌寁丄僶儔)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_indv_stockout_qty    -- (揱昜寁)寚昳悢検(僶儔)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_case_stockout_qty    -- (揱昜寁)寚昳悢検(働乕僗)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_ball_stockout_qty    -- (揱昜寁)寚昳悢検(儃乕儖)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_sum_stockout_qty     -- (揱昜寁)寚昳悢検(崌寁丄僶儔)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_case_qty             -- (揱昜寁)働乕僗屄岥悢
           ,lt_invoice_tab(ln_invoice_cnt).invoice_fold_container_qty   -- (揱昜寁)僆儕僐儞(僶儔)屄岥悢
           ,lt_invoice_tab(ln_invoice_cnt).invoice_order_cost_amt       -- (揱昜寁)尨壙嬥妟(敪拲)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_shipping_cost_amt    -- (揱昜寁)尨壙嬥妟(弌壸)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_stockout_cost_amt    -- (揱昜寁)尨壙嬥妟(寚昳)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_order_price_amt      -- (揱昜寁)攧壙嬥妟(敪拲)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_shipping_price_amt   -- (揱昜寁)攧壙嬥妟(弌壸)
           ,lt_invoice_tab(ln_invoice_cnt).invoice_stockout_price_amt   -- (揱昜寁)攧壙嬥妟(寚昳)
           ,NULL                                                        -- (憤崌寁)敪拲悢検(僶儔)
           ,NULL                                                        -- (憤崌寁)敪拲悢検(働乕僗)
           ,NULL                                                        -- (憤崌寁)敪拲悢検(儃乕儖)
           ,NULL                                                        -- (憤崌寁)敪拲悢検(崌寁丄僶儔)
           ,NULL                                                        -- (憤崌寁)弌壸悢検(僶儔)
           ,NULL                                                        -- (憤崌寁)弌壸悢検(働乕僗)
           ,NULL                                                        -- (憤崌寁)弌壸悢検(儃乕儖)
           ,NULL                                                        -- (憤崌寁)弌壸悢検(僷儗僢僩)
           ,NULL                                                        -- (憤崌寁)弌壸悢検(崌寁丄僶儔)
           ,NULL                                                        -- (憤崌寁)寚昳悢検(僶儔)
           ,NULL                                                        -- (憤崌寁)寚昳悢検(働乕僗)
           ,NULL                                                        -- (憤崌寁)寚昳悢検(儃乕儖)
           ,NULL                                                        -- (憤崌寁)寚昳悢検(崌寁丄僶儔)
           ,NULL                                                        -- (憤崌寁)働乕僗屄岥悢
           ,NULL                                                        -- (憤崌寁)僆儕僐儞(僶儔)屄岥悢
           ,NULL                                                        -- (憤崌寁)尨壙嬥妟(敪拲)
           ,NULL                                                        -- (憤崌寁)尨壙嬥妟(弌壸)
           ,NULL                                                        -- (憤崌寁)尨壙嬥妟(寚昳)
           ,NULL                                                        -- (憤崌寁)攧壙嬥妟(敪拲)
           ,NULL                                                        -- (憤崌寁)攧壙嬥妟(弌壸)
           ,NULL                                                        -- (憤崌寁)攧壙嬥妟(寚昳)
           ,NULL                                                        -- 僩乕僞儖峴悢
           ,NULL                                                        -- 僩乕僞儖揱昜枃悢
           ,NULL                                                        -- 僠僃乕儞揦屌桳僄儕傾(僼僢僞乕)
           ,lt_head_tab(ln_head_cnt).account_number                     -- 曄峏屻屭媞僐乕僪
           ,cv_flag_yes                                                 -- 庴拲楢実嵪僼儔僌
           ,cv_creation_class                                           -- 嶌惉尦嬫暘
           ,cv_flag_no                                                  -- EDI擺昳梊掕憲怣嵪僼儔僌
           ,lt_head_tab(ln_head_cnt).price_list_id                      -- 壙奿昞僿僢僟ID
           ,ln_user_id                                                  -- 嶌惉幰
           ,SYSDATE                                                     -- 嶌惉擔
           ,ln_user_id                                                  -- 嵟廔峏怴幰
           ,SYSDATE                                                     -- 嵟廔峏怴擔
           ,ln_login_id                                                 -- 嵟廔峏怴儘僌僀儞
           ,NULL                                                        -- 梫媮ID
           ,NULL                                                        -- 僐儞僇儗儞僩丒僾儘僌儔儉丒傾僾儕働乕僔儑儞ID
           ,NULL                                                        -- 僐儞僇儗儞僩丒僾儘僌儔儉ID
           ,NULL                                                        -- 僾儘僌儔儉峏怴擔
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_table_name := cv_tbl_name_head;
            RAISE table_insert_expt;
        END;
      END IF;  -- 僿僢僟張棟懳徾丠
    END LOOP head_insert_loop;
--
    --==============================================================
    --儊僢僙乕僕弌椡(僄儔乕埲奜)傪偡傞昁梫偑偁傞応崌偼張棟傪婰弎
    --==============================================================
--
  EXCEPTION
/* 2009/08/11 Ver1.7 Add Start */
    -- *** ORG_ID庢摼椺奜僴儞僪儔 ***
    WHEN org_id_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := SUBSTRB( cv_prg_name || gv_msg_part || lv_errmsg, 1, 5000);
      ov_errmsg  := lv_errmsg;
/* 2009/08/11 Ver1.7 Add End   */
    -- *** 攧忋嬫暘崿嵼椺奜僴儞僪儔 ***
    WHEN sale_class_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
/* 2009/07/13 Ver1.5 Mod Start */
--      ov_errbuf  := cv_prg_name;
--      ov_errmsg  := cv_sale_class_error;
      ov_errbuf  := SUBSTRB( cv_prg_name || gv_msg_part || lv_errmsg, 1, 5000);
      ov_errmsg  := lv_errmsg;
/* 2009/07/13 Ver1.5 Mod End   */
--
    -- *** OUTBOUND壜斲椺奜僴儞僪儔 ***
    WHEN outbound_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
/* 2009/07/13 Ver1.5 Mod Start */
--      ov_errbuf  := cv_prg_name;
--      ov_errmsg  := cv_outbound_error;
      ov_errbuf  := SUBSTRB( cv_prg_name || gv_msg_part || lv_errmsg, 1, 5000);
      ov_errmsg  := lv_errmsg;
/* 2009/07/13 Ver1.5 Mod End   */
--
    -- *** 憓擖椺奜僴儞僪儔 ***
    WHEN table_insert_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
      ov_errbuf  := cv_prg_name;
      ov_errmsg  := SUBSTRB(lv_table_name||SQLERRM,1,5000);
--
    -- *** 昳栚曄姺椺奜僴儞僪儔 ***
    WHEN item_conv_expt THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--#################################  屌掕椺奜張棟晹 START   ####################################
--
    -- *** OTHERS椺奜僴儞僪儔 ***
    WHEN OTHERS THEN
      ov_retcode := xxccp_common_pkg.set_status_error;
/* 2009/07/13 Ver1.5 Mod Start */
--      ov_errbuf  := SUBSTRB( cv_prg_name || SQLERRM, 1, 5000 );
--      ov_errmsg  := xxccp_common_pkg.get_msg(
--                       iv_application => 'XXCOS'
--                      ,iv_name        => 'APP-XXCOS-xxxxx'
--                    );
      lv_errmsg  := SUBSTRB( SQLERRM, 1, 5000);
      ov_errbuf  := SUBSTRB( cv_prg_name || gv_msg_part || lv_errmsg, 1, 5000);
      ov_errmsg  := lv_errmsg;
/* 2009/07/13 Ver1.5 Mod Start */
--
--#####################################  屌掕晹 END   ##########################################
--
  END edi_manual_order_acquisition;
--
END xxcos_edi_common_pkg;
/
