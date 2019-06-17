/*============================================================================
* ファイル名 : XxcsoQtApTaxRateVOImpl
* 概要説明   : 仮払税率取得用ビュークラス
* バージョン : 1.2
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2011-05-17 1.0  SCS桐生和幸  新規作成
* 2013-08-20 1.1  SCSK中野徹也 【E_本稼動_10884】消費税増税対応
* 2019-06-11 1.2  SCSK阿部直樹 【E_本稼動_15472】軽減税率対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
// 2013-08-20 Ver1.1 [E_本稼動_10884] Add Start
import oracle.jbo.domain.Date;
// 2013-08-20 Ver1.1 [E_本稼動_10884] Add End
/*******************************************************************************
 * 仮払税率取得のビュークラスです。
 * @author  SCS桐生和幸
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQtApTaxRateVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQtApTaxRateVOImpl()
  {
  }
// 2013-08-20 Ver1.1 [E_本稼動_10884] Add Start
  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param getDate 消費税取得基準日
   * @param InventoryItemCode 品目コード
   *****************************************************************************
   */
  public void initQuery(
    Date getDate
// 2019-06-11 Ver1.2 [E_本稼動_15472] Add Start
  , String InventoryItemCode
// 2019-06-11 Ver1.2 [E_本稼動_15472] Add End
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, getDate);
// 2019-06-11 Ver1.2 [E_本稼動_15472] Add Start
    setWhereClauseParam(1, getDate);
    setWhereClauseParam(2, getDate);
    setWhereClauseParam(3, InventoryItemCode);
    setWhereClauseParam(4, getDate);
    setWhereClauseParam(5, getDate);
    setWhereClauseParam(6, getDate);
// 2019-06-11 Ver1.2 [E_本稼動_15472] Add End

    executeQuery();

  }
// 2013-08-20 Ver1.1 [E_本稼動_10884] Add End
}