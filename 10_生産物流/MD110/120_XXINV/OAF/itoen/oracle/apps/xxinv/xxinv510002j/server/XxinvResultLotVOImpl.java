/*============================================================================
* ファイル名 : XxinvResultLotVOImpl
* 概要説明   : 出庫・入庫ロット明細画面(実績ロット詳細)ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-11 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510002j.server;
import itoen.oracle.apps.xxinv.util.XxinvConstants;

import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 出庫・入庫ロット明細画面(実績ロット詳細)ビューオブジェクトです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxinvResultLotVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvResultLotVOImpl()
  {
  }

  /*****************************************************************************
   * VOの初期化を行います。
   * @param movLineId      - 移動明細ID
   * @param productFlg     - 製品識別区分
   * @param recordTypeCode - レコードタイプ
   * @param lotCtl         - ロット管理区分
   * @param numOfCases     - ケース入数
   ****************************************************************************/
  public void initQuery(
    String      movLineId,
    String      productFlg,
    String      recordTypeCode,
    String      lotCtl,
    Number      numOfCases
    )
  {
    // 初期化
    setWhereClauseParams(null);
          
    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, lotCtl);
    setWhereClauseParam(1, numOfCases);
    setWhereClauseParam(2, movLineId);
    setWhereClauseParam(3, recordTypeCode);

    // 製品識別区分が1：製品の場合、製造年月日＞固有記号の昇順
    if (XxinvConstants.PRODUCT_FLAG_PROD.equals(productFlg))
    {
      setOrderByClause("manufactured_date,koyu_code");   
    // それ以外はロットNoの昇順
    } else
    {
      setOrderByClause("TO_NUMBER(lot_no)");     
    }

    // SELECT文実行
    executeQuery();
  }
}