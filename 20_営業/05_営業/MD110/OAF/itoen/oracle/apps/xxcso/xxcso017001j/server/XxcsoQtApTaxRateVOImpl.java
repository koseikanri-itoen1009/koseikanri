/*============================================================================
* ファイル名 : XxcsoQtApTaxRateVOImpl
* 概要説明   : 仮払税率取得用ビュークラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2011-05-17 1.0  SCS桐生和幸  新規作成
* 2013-08-20 1.1  SCSK中野徹也 【E_本稼動_10884】消費税増税対応
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
   *****************************************************************************
   */
  public void initQuery(
    Date getDate
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, getDate);

    executeQuery();

  }
// 2013-08-20 Ver1.1 [E_本稼動_10884] Add End
}