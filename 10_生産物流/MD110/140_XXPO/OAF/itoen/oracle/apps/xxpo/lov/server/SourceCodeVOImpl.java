/*============================================================================
* ファイル名 : SourceCodeVOImpl
* 概要説明   : 産地LOVビューオブジェクト
* バージョン : 1.0
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-05-21 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.lov.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 産地LOVビューオブジェクトです。
 * @author  ORACLE伊藤ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class SourceCodeVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public SourceCodeVOImpl()
  {
  }
  /***************************************************************************
   * 初期化処理を行うメソッドです。
   * @param sourceDesc 産地
   ***************************************************************************
   */
  public void initQuery(String sourceDesc)
  {
    // WHERE句に産地を追加
    setWhereClause(null);
    setWhereClause(" meaning = :0");
    setWhereClauseParam(0, sourceDesc);

    // 検索実行
    executeQuery();
  }
}