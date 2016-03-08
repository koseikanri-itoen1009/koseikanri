/*============================================================================
* ファイル名 : XxwshReserveLotVOImpl
* 概要説明   : 手持数・引当可能数一覧(ロット管理品)リージョンビューオブジェクト
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-25 1.0  二瓶　大輔     新規作成 本番#771対応
* 2009-12-04 1.1  伊藤  ひとみ   本稼動障害#11対応
* 2010-01-05 1.2  伊藤  ひとみ   本稼動障害#861対応
* 2016-02-18 1.3  山下  翔太     E_本稼動_13468対応
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;
import com.sun.java.util.collections.HashMap;

/***************************************************************************
 * 手持数・引当可能数一覧(ロット管理品)リージョンビューオブジェクトクラスです。
 * @author  ORACLE 二瓶　大輔
 * @version 1.3
 ***************************************************************************
 */
public class XxwshReserveLotVOImpl extends OAViewObjectImpl
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshReserveLotVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param params - 検索キー
   ****************************************************************************/
  public void initQuery(
    HashMap params)
  {
    // 検索キーが指定されている場合に検索を実行
    if (!XxcmnUtility.isBlankOrNull(params))
    {

      // HashMapから値を取得
      Number itemId                     = (Number)params.get("ItemId");                     // 品目ID
      Number inputInventoryLocationId   = (Number)params.get("InputInventoryLocationId");   // 保管倉庫ID
      String inputInventoryLocationCode = (String)params.get("InputInventoryLocationCode"); // 保管倉庫コード
      String documentTypeCode           = (String)params.get("DocumentTypeCode");           // 文書タイプ
      String locationRelCode            = (String)params.get("LocationRelCode");            // 拠点実績有無区分
      String convUnitUseKbn             = (String)params.get("ConvUnitUseKbn");             // 入出庫換算単位使用区分
      String callPictureKbn             = (String)params.get("CallPictureKbn");             // 呼出画面区分
      Number lotCtl                     = (Number)params.get("LotCtl");                     // ロット管理品
      String designatedProductionDate   = (String)params.get("DesignatedProductionDate");   // 指定製造日
      Number lineId                     = (Number)params.get("LineId");                     // 明細ID
      Date scheduleShipDate             = (Date)params.get("ScheduleShipDate");             // 出荷予定日
      String prodClass                  = (String)params.get("ProdClass");                  // 商品区分
      String itemClass                  = (String)params.get("ItemClass");                  // 品目区分
      String numOfCases                 = (String)params.get("NumOfCases");                 // ケース入数
      String frequentWhseCode           = (String)params.get("FrequentWhseCode");            // 代表倉庫
      String masterOrgId                = (String)params.get("MasterOrgId");                 // 在庫組織ID
      String maxDate                    = (String)params.get("MaxDate");                     // 最大日付
      String dummyFrequentWhse          = (String)params.get("DummyFrequentWhse");           // ダミー倉庫
// 2009-12-04 H.Itou Add Start 本稼動障害#11
      String openDate                   = (String)params.get("OpenDate");                    // オープン日付
// 2009-12-04 H.Itou Add End 本稼動障害#11
 
      // WHERE句を初期化
      setWhereClauseParams(null); // Always reset
      setOrderByClause(null);
      setWhereClause(null);
      // バインド変数に値をセット
      int i = 0;
// 2009-12-04 H.Itou Del Start 本稼動障害#11 換算はデータ取得後行うため。
//      setWhereClauseParam(i++, convUnitUseKbn);             //  0:入出庫換算単位使用区分
//      setWhereClauseParam(i++, numOfCases);                 //  1:ケース入数
//      setWhereClauseParam(i++, convUnitUseKbn);             //  2:入出庫換算単位使用区分
//      setWhereClauseParam(i++, numOfCases);                 //  3:ケース入数
// 2009-12-04 H.Itou Del End
      setWhereClauseParam(i++, lotCtl);                     //  0:ロット管理
// 2009-12-04 H.Itou Add Start 本稼動障害#11
      setWhereClauseParam(i++, scheduleShipDate);           //  1:出庫予定日
      setWhereClauseParam(i++, scheduleShipDate);           //  2:出庫予定日
// 2009-12-04 H.Itou Add End 本稼動障害#11
      setWhereClauseParam(i++, lotCtl);                     //  3:ロット管理
      setWhereClauseParam(i++, masterOrgId);                //  4:在庫組織ID
      setWhereClauseParam(i++, scheduleShipDate);           //  5:出庫予定日
      setWhereClauseParam(i++, maxDate);                    //  6:最大日付
      setWhereClauseParam(i++, inputInventoryLocationId);   //  7:入力保管倉庫ID
      setWhereClauseParam(i++, inputInventoryLocationCode); //  8:入力保管倉庫コード
      setWhereClauseParam(i++, frequentWhseCode);           //  9:代表倉庫
      setWhereClauseParam(i++, dummyFrequentWhse);          // 10:ダミー倉庫
      setWhereClauseParam(i++, lotCtl);                     // 11:ロット管理
      setWhereClauseParam(i++, inputInventoryLocationId);   // 12:入力保管倉庫ID
      setWhereClauseParam(i++, convUnitUseKbn);             // 13:入出庫換算単位使用区分
      setWhereClauseParam(i++, numOfCases);                 // 14:ケース入数
// 2009-12-04 H.Itou Add Start 本稼動障害#11
      setWhereClauseParam(i++, itemId);                     // 15:品目ID
      setWhereClauseParam(i++, openDate);                   // 16:オープン日付
      setWhereClauseParam(i++, itemId);                     // 17:品目ID
      setWhereClauseParam(i++, itemId);                     // 18:品目ID
      setWhereClauseParam(i++, masterOrgId);                // 19:在庫組織ID
      setWhereClauseParam(i++, openDate);                   // 20:オープン日付
      setWhereClauseParam(i++, itemId);                     // 21:品目ID
      setWhereClauseParam(i++, openDate);                   // 22:オープン日付
      setWhereClauseParam(i++, openDate);                   // 23:オープン日付
      setWhereClauseParam(i++, itemId);                     // 24:品目ID
      setWhereClauseParam(i++, itemId);                     // 25:品目ID
      setWhereClauseParam(i++, openDate);                   // 26:オープン日付
// 2010-01-05 H.Itou Add Start 本稼動障害#861
      setWhereClauseParam(i++, itemId);                     // 27:品目ID
      setWhereClauseParam(i++, openDate);                   // 28:オープン日付
// 2010-01-05 H.Itou Add End 本稼動障害#861
      setWhereClauseParam(i++, lineId);                     // 29:明細ID
      setWhereClauseParam(i++, documentTypeCode);           // 30:文書タイプ
// 2009-12-04 H.Itou Add End 本稼動障害#11
      setWhereClauseParam(i++, itemId);                     // 31:品目ID
      setWhereClauseParam(i++, prodClass);                  // 32:商品区分
      setWhereClauseParam(i++, lineId);                     // 33:明細ID
      setWhereClauseParam(i++, documentTypeCode);           // 34:文書タイプ
// 2009-12-04 H.Itou Del Start 本稼動障害#11 上に移動。
//      setWhereClauseParam(i++, scheduleShipDate);           // 21:出庫予定日
//      setWhereClauseParam(i++, scheduleShipDate);           // 22:出庫予定日
// 2009-12-04 H.Itou Del End 本稼動障害#11

      // ロット管理品の場合条件をセット
      if (XxwshConstants.LOT_CTL_Y.equals(lotCtl.toString()))
      {
        //WHERE句作成
        StringBuffer whereClause   = new StringBuffer(1000);  // WHERE句作成用オブジェクト
        //ORDERBY句生成
        StringBuffer orderByClause = new StringBuffer(1000);  // ORDERBY句作成用オブジェクト
        //条件にロット管理品を追加
        whereClause.append(" lot_id <> " + XxwshConstants.DEFAULT_LOT.toString());

        //指定製造日が入力されている場合条件を追加
        if (!XxcmnUtility.isBlankOrNull(designatedProductionDate))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where句生成
          whereClause.append(" production_date >= '" + designatedProductionDate + "'");
        }
        //呼出画面区分が「出荷」で拠点実績有無区分が「売上拠点」の場合条件を追加
        if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn) &
           XxwshConstants.LOCATION_REL_CODE_SALE.equals(locationRelCode))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where句生成
          whereClause.append(" ship_req_m_reserve = 'Y'");
        }
        // 呼出画面区分が「支給」の場合条件を追加
        else if(XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where句生成
          whereClause.append(" pay_provision_m_reserve = 'Y'");
        }
        // 呼出画面区分が「移動」の場合条件を追加
        else if(XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where句生成
          whereClause.append(" move_inst_m_reserve = 'Y'");
        }
        // ORDER BY句を設定
        // 品目区分が製品の場合
        if (XxwshConstants.ITEM_TYPE_PROD.equals(itemClass))
        {
          // Order BY句生成
// 2016-02-18 S.Yamashita Mod Start E_本稼動_13468
//          orderByClause.append(" production_date asc "); // 製造日(昇順)
          orderByClause.append(" expiration_date asc "); // 賞味期限(昇順)
          orderByClause.append(",production_date asc "); // 製造日(昇順)
// 2016-02-18 S.Yamashita Mod End   E_本稼動_13468
          orderByClause.append(",uniqe_sign asc ");      // 固有記号(昇順)
        } else
        {
          // Order BY句生成
          orderByClause.append(" TO_NUMBER(show_lot_no) asc ");     // ロットNo(昇順)
        }
        //追加検索条件をセット
        setWhereClause(whereClause.toString());
        // ORDER BY 条件をセット
        setOrderByClause(orderByClause.toString());
      }
      //検索を実行
      executeQuery();
    }
  }
}