/*============================================================================
* ファイル名 : XxcsoContractSummaryVOImpl
* 概要説明   : 契約書明細ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-10-31 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*******************************************************************************
 * 契約書明細を出力するためのビュークラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractSummaryVOImpl()
  {
  }
  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param Contractnumber         契約書番号
   * @param Installaccountnumber   顧客コード
   * @param Installpartyname       設置先名
   *****************************************************************************
   */
  public void initQuery(
    String Contractnumber,
    String Installaccountnumber,
    String Installpartyname
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, Contractnumber);
    setWhereClauseParam(index++, Contractnumber);
    setWhereClauseParam(index++, Contractnumber);
    setWhereClauseParam(index++, Installaccountnumber);
    setWhereClauseParam(index++, Installaccountnumber);
    setWhereClauseParam(index++, Installaccountnumber);
    setWhereClauseParam(index++, Installpartyname);
    setWhereClauseParam(index++, Installpartyname);
    setWhereClauseParam(index++, Installpartyname);

    executeQuery();
  }
}