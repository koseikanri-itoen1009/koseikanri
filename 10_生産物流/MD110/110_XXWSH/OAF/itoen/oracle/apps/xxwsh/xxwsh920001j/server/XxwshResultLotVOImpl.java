/*============================================================================
* ファイル名 : XxwshResultLotVOImpl
* 概要説明   : 入出荷実績ロット入力画面(実績ロット詳細)ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-27 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920001j.server;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
/***************************************************************************
 * 入出荷実績ロット入力画面(実績ロット詳細)ビューオブジェクトです。
 * @author  ORACLE 伊藤ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxwshResultLotVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshResultLotVOImpl()
  {
  }

    
  /*****************************************************************************
   * VOの初期化を行います。
   * @param orderLineId      - 受注明細アドオンID
   * @param documentTypeCode - 文書タイプ
   * @param recordTypeCode   - レコードタイプ
   * @param itemClassCode    - 品目区分
   * @param numOfCases       - ケース入数
   ****************************************************************************/
  public void initQuery(
    String      orderLineId,
    String      documentTypeCode,
    String      recordTypeCode,
    String      itemClassCode,
    Number      numOfCases
    )
  {
    // 初期化
    setWhereClauseParams(null);
          
    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, numOfCases);
    setWhereClauseParam(1, orderLineId);
    setWhereClauseParam(2, documentTypeCode);
    setWhereClauseParam(3, recordTypeCode);

    // 品目区分が5：製品の場合、製造年月日＞賞味期限＞固有記号の昇順
    if (XxwshConstants.ITEM_TYPE_PROD.equals(itemClassCode))
    {
      setOrderByClause("manufactured_date,use_by_date,koyu_code");   
    // それ以外はロットNoの昇順
    } else
    {
      setOrderByClause("TO_NUMBER(lot_no)");      
    }

    // SELECT文実行
    executeQuery();
  }
}