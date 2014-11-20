/*============================================================================
* ファイル名 : XxwshStockCanEncQtyVOImpl
* 概要説明   : 手持数・引当可能数一覧リージョンビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-17 1.0  北寒寺正夫     新規作成
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
 * 手持数・引当可能数一覧リージョンビューオブジェクトクラスです。
 * @author  ORACLE 北寒寺 正夫
 * @version 1.0
 ***************************************************************************
 */
public class XxwshStockCanEncQtyVOImpl extends OAViewObjectImpl
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshStockCanEncQtyVOImpl()
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
 
      // WHERE句を初期化
      setWhereClauseParams(null); // Always reset
      setOrderByClause(null);
      setWhereClause(null);
      // バインド変数に値をセット
      setWhereClauseParam(0,  lotCtl);                   // ロット管理     
      setWhereClauseParam(1,  scheduleShipDate);         // 出庫予定日
      setWhereClauseParam(2,  scheduleShipDate);         // 出庫予定日
      setWhereClauseParam(3,  inputInventoryLocationId); // 入力保管倉庫ID
      setWhereClauseParam(4,  lotCtl);                   // ロット管理
      setWhereClauseParam(5,  scheduleShipDate);         // 出庫予定日
      setWhereClauseParam(6,  inputInventoryLocationId); // 入力保管倉庫ID
      setWhereClauseParam(7,  lotCtl);                   // ロット管理
      setWhereClauseParam(8,  convUnitUseKbn);           // 入出庫換算単位使用区分
      setWhereClauseParam(9,  inputInventoryLocationId); // 入力保管倉庫ID
      setWhereClauseParam(10, lotCtl);                   // ロット管理
      setWhereClauseParam(11, scheduleShipDate);         // 出庫予定日
      setWhereClauseParam(12, numOfCases);               // ケース入数
      setWhereClauseParam(13, inputInventoryLocationId); // 入力保管倉庫ID
      setWhereClauseParam(14, lotCtl);                   // ロット管理
      setWhereClauseParam(15, scheduleShipDate);         // 出庫予定日
      setWhereClauseParam(16, convUnitUseKbn);           // 入出庫換算単位使用区分
      setWhereClauseParam(17, inputInventoryLocationId); // 入力保管倉庫ID
      setWhereClauseParam(18, lotCtl);                   // ロット管理
      setWhereClauseParam(19, numOfCases);               // ケース入数
      setWhereClauseParam(20, inputInventoryLocationId); // 入力保管倉庫ID
      setWhereClauseParam(21, lotCtl);                   // ロット管理
      setWhereClauseParam(22, convUnitUseKbn);           // 入出庫換算単位使用区分
      setWhereClauseParam(23, numOfCases);               // ケース入数
      setWhereClauseParam(24, itemId);                   // 品目ID
      setWhereClauseParam(25, prodClass);                // 商品区分
      setWhereClauseParam(26, lineId);                   // 明細ID
      setWhereClauseParam(27, documentTypeCode);         // 文書タイプ
      setWhereClauseParam(28, inputInventoryLocationId); // 入力保管倉庫ID
      setWhereClauseParam(29, lotCtl);                   // ロット管理
      setWhereClauseParam(30, scheduleShipDate);         // 出庫予定日
      // ロット管理品の場合条件をセット
      if (XxwshConstants.LOT_CTL_Y.equals(lotCtl.toString()))
      {
        //WHERE句作成
        StringBuffer whereClause   = new StringBuffer(1000);  // WHERE句作成用オブジェクト
        //ORDERBY句生成
        StringBuffer orderByClause = new StringBuffer(1000);  // ORDERBY句作成用オブジェクト
        //条件にロット管理品を追加
        whereClause.append("lot_id <> " + XxwshConstants.DEFAULT_LOT.toString());

        //指定製造日が入力されている場合条件を追加
        if (!XxcmnUtility.isBlankOrNull(designatedProductionDate))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where句生成
          whereClause.append("production_date >= '" + designatedProductionDate + "'");
        }
        //呼出画面区分が「出荷」で拠点実績有無区分が「売上拠点」の場合条件を追加
        if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn) &
           XxwshConstants.LOCATION_REL_CODE_SALE.equals(locationRelCode))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where句生成
          whereClause.append("ship_req_m_reserve = 'Y'");
        }
        // 呼出画面区分が「支給」の場合条件を追加
        else if(XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where句生成
          whereClause.append("pay_provision_m_reserve = 'Y'");
        }
        // 呼出画面区分が「移動」の場合条件を追加
        else if(XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where句生成
          whereClause.append("move_inst_m_reserve = 'Y'");
        }
        // ORDER BY句を設定
        // 品目区分が製品の場合
        if (XxwshConstants.ITEM_TYPE_PROD.equals(itemClass))
        {
          // Order BY句生成
          orderByClause.append(" production_date asc "); // 製造日(昇順)
          orderByClause.append(",expiration_date asc "); // 賞味期限(昇順)
          orderByClause.append(",uniqe_sign asc ");      // 固有記号(昇順)
        } else
        {
          // Order BY句生成
          orderByClause.append(" show_lot_no asc ");     // ロットNo(昇順)
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