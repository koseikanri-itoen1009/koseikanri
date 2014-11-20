/*============================================================================
* ファイル名 : XxpoShippedMakeLineVOImpl
* 概要説明   : 出庫実績入力明細ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-31 1.0  山本恭久     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo441001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
/***************************************************************************
 * 出庫実績入力明細ビューオブジェクトクラスです。
 * @author  ORACLE 山本 恭久
 * @version 1.0
 ***************************************************************************
 */
public class XxpoShippedMakeLineVOImpl extends OAViewObjectImpl  
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoShippedMakeLineVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param exeType       - 起動タイプ
   * @param orderHeaderId - 受注ヘッダアドオンID
   ****************************************************************************/
  public void initQuery(String exeType, Number orderHeaderId)
  {
    int i = 0;
    setWhereClauseParam(i++, orderHeaderId);
    // 検索実行
    executeQuery();
  }
}