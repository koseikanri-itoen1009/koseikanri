/*============================================================================
* ファイル名 : XxwshLineProdVOImpl
* 概要説明   : 明細情報リージョン(支給)ビューオブジェクト
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
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

/***************************************************************************
 * 明細情報リージョン(支給)ビューオブジェクトクラスです。
 * @author  ORACLE 北寒寺 正夫
 * @version 1.0
 ***************************************************************************
 */
public class XxwshLineProdVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshLineProdVOImpl()
  {
  }

  /*****************************************************************************
   * VOの初期化を行います。
   * @param lineId - 検索条件
   ****************************************************************************/
  public void initQuery(
    String lineId)
  {
    if (!XxcmnUtility.isBlankOrNull(lineId))
    {
      // WHERE句を初期化
      setWhereClauseParams(null); // Always reset
      // バインド変数に値をセット
      setWhereClauseParam(0,  lineId); // 検索条件
      // 検索実行
      executeQuery();
    }
  }
}