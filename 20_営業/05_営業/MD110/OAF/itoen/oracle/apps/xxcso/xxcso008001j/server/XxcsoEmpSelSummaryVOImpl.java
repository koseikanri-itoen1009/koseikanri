/*============================================================================
* ファイル名 : XxcsoEmpSelSummaryVOImpl
* 概要説明   : 週次活動状況照会／検索用ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-06 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * 担当者選択リージョンを検索するためのビュークラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoEmpSelSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoEmpSelSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param baseCd     勤務先拠点コード
   *****************************************************************************
   */
  public void initQuery(
    String  baseCd 
  )
  {
    // 初期化
    setWhereClause(null);
    setWhereClauseParams(null);

    // バインドへの値の設定
    int idx = 0;
    setWhereClauseParam(idx++, baseCd);
    setWhereClauseParam(idx++, baseCd);
    setWhereClauseParam(idx++, baseCd);

    // SQL実行
    executeQuery();
  }

}